function hdev -d "Herdr workspace for a project: nvim + agent (-o: agent only)"
    # Usage: hdev [-o] [-n] [-a claude|codex|opencode] [project-dir | zoxide-query]
    #   default: nvim (left 70%) + agent (right 30%)
    #   -o  agent only, no nvim  (-e is accepted and means the default)
    #   -n  always open a new workspace, even if the project already has one
    # Reuses what exists: an agent already running in the project is focused
    # (not duplicated), and idle shell panes in the project's workspace (e.g.
    # left over after a herdr restart) are reused before any new split.
    # With no argument inside a git repo, the project is the repo root.
    # Always prints what it did; herdr errors are shown — then run doctor.sh.
    # Mirrors zsh version: .config/zsh/conf.d/functions.zsh
    argparse 'a/agent=' e/editor o/only n/new -- $argv; or return
    set -l editor 1
    set -q _flag_only; and set editor 0
    set -l agent claude
    set -q _flag_agent; and set agent $_flag_agent

    set -l root (git rev-parse --show-toplevel 2>/dev/null; or echo $PWD)
    if test (count $argv) -ge 1
        if test -d $argv[1]
            set root $argv[1]
        else
            # resolve project path via zoxide (like `z <name>`)
            set root (zoxide query $argv[1] 2>/dev/null)
            if test -z "$root"
                echo "hdev: no directory matches '$argv[1]'" >&2
                return 1
            end
        end
    end
    # resolved path: herdr reports agent cwds resolved (/tmp → /private/tmp)
    set root (realpath $root)
    set -l name (basename $root)
    # explicit cd: nvim/agent must open the repo even if the pane's shell sits
    # elsewhere (reused pane, rc files, herdr cwd fallback to $HOME)
    set -l go "cd "(string escape -- $root)" &&"

    if test "$HERDR_ENV" != 1
        echo "hdev: run inside herdr (start it with: herdr)" >&2
        return 1
    end
    if not command -q jq
        echo "hdev: jq not found — run ~/.dotfiles/doctor.sh" >&2
        return 1
    end

    if not set -q _flag_new
        # same agent already running in this project → just go there
        set -l agents (_hdev_h agent list); or return 1
        set -l running (printf '%s\n' $agents | jq -r --arg r $root --arg a $agent '.result.agents[] | select(.cwd == $r and .agent == $a) | .pane_id' | head -1)
        if test -n "$running"
            _hdev_h agent focus $running >/dev/null; or return 1
            echo "hdev: $agent already running in $name (pane $running) — focused"
            test $editor = 1; and _hdev_add_editor $running $root
            return
        end
    end

    set -l main
    set -l ws
    if not set -q _flag_new
        set -l spaces (_hdev_h workspace list); or return 1
        set ws (printf '%s\n' $spaces | jq -r --arg l $name '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -1)
    end
    if test -n "$ws"
        if test "$ws" != "$HERDR_WORKSPACE_ID"
            _hdev_h workspace focus $ws >/dev/null; or return 1
        end
        # an idle shell pane (not the one running hdev) before a new split
        set main (_hdev_idle_pane $ws $HERDR_PANE_ID); or return 1
        if test -n "$main"
            echo "hdev: starting $agent in idle pane $main"
        else
            set -l anchor $HERDR_PANE_ID
            if test "$ws" != "$HERDR_WORKSPACE_ID"
                set anchor (_hdev_h pane list --workspace $ws | jq -r '.result.panes[0].pane_id')
            end
            set main (_hdev_h pane split $anchor --direction right --ratio 0.5 --cwd $root --no-focus | jq -r .result.pane.pane_id)
            test -n "$main"; or return 1
            echo "hdev: starting $agent in new pane $main"
        end
    else
        set main (_hdev_h workspace create --cwd $root --label $name --focus | jq -r .result.root_pane.pane_id)
        test -n "$main"; or return 1
        echo "hdev: new workspace $name"
    end

    if test $editor = 1
        # --ratio is the share kept by the original (left) pane
        set -l side (_hdev_h pane split $main --direction right --ratio 0.7 --cwd $root --no-focus | jq -r .result.pane.pane_id)
        test -n "$side"; or return 1
        _hdev_h pane run $main "$go nvim ." >/dev/null; or return 1
        _hdev_h pane run $side "$go $agent" >/dev/null
    else
        _hdev_h pane run $main "$go $agent" >/dev/null
    end
end

# _hdev_h <herdr args> — run herdr; on failure print herdr's own error message
# (it answers JSON {"error":{"message":…}}) instead of failing silently
function _hdev_h
    set -l out (herdr $argv 2>&1)
    set -l st $status
    set -l msg (printf '%s\n' $out | jq -r '.error.message // empty' 2>/dev/null)
    if test $st -ne 0; or test -n "$msg"
        test -n "$msg"; or set msg (string join ' ' $out)
        echo "hdev: `herdr $argv[1] $argv[2]` failed: $msg" >&2
        echo "      run ~/.dotfiles/doctor.sh to diagnose" >&2
        return 1
    end
    printf '%s\n' $out
end

# _hdev_idle_pane <workspace> <exclude-pane> — print the first pane whose
# foreground is only a shell (nothing running in it); prints nothing if none.
# Returns 1 only on a herdr error.
function _hdev_idle_pane -a ws exclude
    set -l panes (_hdev_h pane list --workspace $ws); or return 1
    for p in (printf '%s\n' $panes | jq -r '.result.panes[].pane_id')
        test "$p" = "$exclude"; and continue
        set -l info (_hdev_h pane process-info --pane $p); or return 1
        if printf '%s\n' $info | jq -e '[.result.process_info.foreground_processes[].argv0 | ltrimstr("-")] | length > 0 and all(test("^(zsh|fish|bash|sh)$"))' >/dev/null
            echo $p
            return 0
        end
    end
end

# hdev on a project whose agent already runs: open nvim in an idle shell pane of
# that workspace, else split it off the agent (nvim left 70%). Only says so
# when nvim is already open. Never starts an agent.
function _hdev_add_editor -a agent_pane root
    set -l ws (string split -f1 : $agent_pane)
    # capture before jq: a herdr failure must stop here, not read as "no nvim"
    set -l panes (_hdev_h pane list --workspace $ws); or return 1
    for p in (printf '%s\n' $panes | jq -r '.result.panes[].pane_id')
        set -l info (_hdev_h pane process-info --pane $p); or return 1
        if printf '%s\n' $info | jq -e '.result.process_info.foreground_processes[] | select(.argv0 == "nvim")' >/dev/null
            echo "hdev: nvim already open in this workspace (pane $p)"
            return
        end
    end
    set -l go "cd "(string escape -- $root)" && nvim ."
    set -l ed (_hdev_idle_pane $ws $HERDR_PANE_ID); or return 1
    if test -n "$ed"
        _hdev_h pane run $ed $go >/dev/null; or return 1
        echo "hdev: nvim opened in idle pane $ed"
        return
    end
    # split leaves the agent in the left 70% slot; swap moves nvim into it
    set ed (_hdev_h pane split $agent_pane --direction right --ratio 0.7 --cwd $root --no-focus | jq -r .result.pane.pane_id)
    test -n "$ed"; or return 1
    _hdev_h pane swap --source-pane $agent_pane --target-pane $ed >/dev/null; or return 1
    _hdev_h pane run $ed $go >/dev/null; or return 1
    echo "hdev: nvim opened in new pane $ed"
end
