function hdev -d "Herdr workspace for a project: nvim + agent (-o: agent only)"
    # Usage: hdev [-o] [-n] [-a claude|codex|opencode] [project-dir | zoxide-query]
    #   default: nvim (left 70%) + agent (right 30%)
    #   -o  agent only, no nvim  (-e is accepted and means the default)
    #   -n  always open a new workspace, even if the project already has one
    # Uses what's there before adding anything: an agent already running in the
    # project and an nvim already open are kept (focused, not duplicated). Free
    # panes are used in this order: the pane you typed `hdev` in (when it's the
    # project's workspace), then idle shell panes (e.g. left over after a herdr
    # restart); a pane is split only when none is free.
    # With no argument inside a git repo, the project is the repo root.
    # Prints one line per pane it touched; herdr errors point to doctor.sh.
    # Mirrors zsh version: .config/zsh/conf.d/functions.zsh
    argparse 'a/agent=' e/editor o/only n/new -- $argv; or return
    set -l agent claude
    set -q _flag_agent; and set agent $_flag_agent
    set -l editor 1
    set -q _flag_only; and set editor 0

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

    # ── what already exists ──────────────────────────────────────────────────
    set -l running
    set -l ws
    if not set -q _flag_new
        set -l agents (_hdev_h agent list); or return 1
        set running (printf '%s\n' $agents | jq -r --arg r $root --arg a $agent '.result.agents[] | select(.cwd == $r and .agent == $a) | .pane_id' | head -1)
        set -l spaces (_hdev_h workspace list); or return 1
        set ws (printf '%s\n' $spaces | jq -r --arg l $name '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -1)
        # an agent already running for the project marks its workspace
        test -n "$running"; and set ws (string split -f1 : $running)
    end

    # ── free panes, in order of preference ───────────────────────────────────
    set -l pool
    if test -z "$ws"
        set -l first (_hdev_h workspace create --cwd $root --label $name --focus | jq -r .result.root_pane.pane_id)
        test -n "$first"; or return 1
        set ws (string split -f1 : $first)
        set pool $first
        echo "hdev: new workspace $name"
    else
        if test "$ws" = "$HERDR_WORKSPACE_ID"
            set pool $HERDR_PANE_ID
        else
            _hdev_h workspace focus $ws >/dev/null; or return 1
        end
        set -l idle (_hdev_idle_panes $ws $HERDR_PANE_ID); or return 1
        set -a pool $idle
    end

    set -l nvim_pane
    if test $editor = 1
        set nvim_pane (_hdev_nvim_pane $ws); or return 1
        test -n "$nvim_pane"; and echo "hdev: nvim already open (pane $nvim_pane)"
    end
    if test -n "$running"
        _hdev_h agent focus $running >/dev/null; or return 1
        echo "hdev: $agent already running (pane $running) — focused"
    end

    # ── assign: nvim takes the first free pane, the agent the next ───────────
    set -l ed
    set -l ag
    if test $editor = 1; and test -z "$nvim_pane"; and test (count $pool) -gt 0
        set ed $pool[1]
        set -e pool[1]
    end
    if test -z "$running"; and test (count $pool) -gt 0
        set ag $pool[1]
        set -e pool[1]
    end
    # ── split only for what's still missing (nvim stays left, 70%) ───────────
    if test $editor = 1; and test -z "$nvim_pane"; and test -z "$ed"
        set -l beside $ag $running
        if test -n "$beside[1]"
            # split leaves the agent in the left 70% slot; swap moves nvim into it
            set ed (_hdev_h pane split $beside[1] --direction right --ratio 0.7 --cwd $root --no-focus | jq -r .result.pane.pane_id)
            test -n "$ed"; or return 1
            _hdev_h pane swap --source-pane $beside[1] --target-pane $ed >/dev/null; or return 1
        else
            set -l anchor (_hdev_h pane list --workspace $ws | jq -r '.result.panes[0].pane_id')
            set ed (_hdev_h pane split $anchor --direction right --ratio 0.5 --cwd $root --no-focus | jq -r .result.pane.pane_id)
            test -n "$ed"; or return 1
        end
    end
    if test -z "$running"; and test -z "$ag"
        # beside nvim when there is one (it keeps the left 70%), else the
        # caller pane (project's workspace) or the workspace's first pane
        set -l beside $ed $nvim_pane
        if test -z "$beside[1]"
            if test "$ws" = "$HERDR_WORKSPACE_ID"
                set beside $HERDR_PANE_ID
            else
                set beside (_hdev_h pane list --workspace $ws | jq -r '.result.panes[0].pane_id')
            end
        end
        set ag (_hdev_h pane split $beside[1] --direction right --ratio 0.7 --cwd $root --no-focus | jq -r .result.pane.pane_id)
        test -n "$ag"; or return 1
    end

    # ── run — the pane running hdev goes last: its command starts once hdev
    #    returns and the shell reads the queued input
    set -l jp
    set -l jn
    set -l jc
    if test -n "$ag"
        set -a jp $ag; set -a jn $agent; set -a jc "$go $agent"
    end
    if test -n "$ed"
        set -a jp $ed; set -a jn nvim; set -a jc "$go nvim ."
    end
    for pass in other self
        set -l i 0
        for pane in $jp
            set i (math $i + 1)
            if test "$pass" = other
                test "$pane" = "$HERDR_PANE_ID"; and continue
            else
                test "$pane" = "$HERDR_PANE_ID"; or continue
            end
            _hdev_h pane run $pane $jc[$i] >/dev/null; or return 1
            if test "$pass" = self
                echo "hdev: $jn[$i] → this pane"
            else
                echo "hdev: $jn[$i] → pane $pane"
            end
        end
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

# _hdev_idle_panes <workspace> <exclude-pane> — print every pane whose
# foreground is only a shell (nothing running in it). Returns 1 only on a
# herdr error.
function _hdev_idle_panes -a ws exclude
    set -l panes (_hdev_h pane list --workspace $ws); or return 1
    for p in (printf '%s\n' $panes | jq -r '.result.panes[].pane_id')
        test "$p" = "$exclude"; and continue
        set -l info (_hdev_h pane process-info --pane $p); or return 1
        printf '%s\n' $info | jq -e '[.result.process_info.foreground_processes[].argv0 | ltrimstr("-")] | length > 0 and all(test("^(zsh|fish|bash|sh)$"))' >/dev/null; and echo $p
    end
    return 0
end

# _hdev_nvim_pane <workspace> — print the first pane running nvim, if any.
# Returns 1 only on a herdr error.
function _hdev_nvim_pane -a ws
    set -l panes (_hdev_h pane list --workspace $ws); or return 1
    for p in (printf '%s\n' $panes | jq -r '.result.panes[].pane_id')
        # capture before jq: a herdr failure must stop here, not read as "no nvim"
        set -l info (_hdev_h pane process-info --pane $p); or return 1
        if printf '%s\n' $info | jq -e '.result.process_info.foreground_processes[] | select(.argv0 == "nvim")' >/dev/null
            echo $p
            return 0
        end
    end
    return 0
end
