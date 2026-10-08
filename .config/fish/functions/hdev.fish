function hdev -d "Herdr workspace for a project: agent (+ nvim with -e)"
    # Usage: hdev [-e] [-n] [-a claude|codex|opencode] [project-dir | zoxide-query]
    #   -e  also open nvim (left 70%, agent right 30%)
    #   -n  always open a new workspace, even if the project already has one
    # Without -n, an agent already running in the project is focused instead
    # of starting a duplicate. With no argument inside a git repo, the project
    # is the repo root (not the subfolder you're in).
    # Every herdr error is printed — run ~/.dotfiles/doctor.sh if one appears.
    # Mirrors zsh version: .config/zsh/conf.d/functions.zsh
    argparse 'a/agent=' e/editor n/new -- $argv; or return
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
            set -q _flag_editor; and _hdev_add_editor $running $root
            return
        end
    end

    set -l main
    set -l ws
    if not set -q _flag_new
        set -l spaces (_hdev_h workspace list); or return 1
        set ws (printf '%s\n' $spaces | jq -r --arg l $name '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -1)
    end
    if test -n "$ws"; and test "$ws" = "$HERDR_WORKSPACE_ID"
        # already in the project's workspace: add the agent beside this pane
        set main (_hdev_h pane split --current --direction right --ratio 0.5 --cwd $root --no-focus | jq -r .result.pane.pane_id)
    else if test -n "$ws"
        _hdev_h workspace focus $ws >/dev/null; or return 1
        set -l first (_hdev_h pane list --workspace $ws | jq -r '.result.panes[0].pane_id')
        set main (_hdev_h pane split $first --direction right --ratio 0.5 --cwd $root --focus | jq -r .result.pane.pane_id)
    else
        set main (_hdev_h workspace create --cwd $root --label $name --focus | jq -r .result.root_pane.pane_id)
    end
    test -n "$main"; or return 1

    if set -q _flag_editor
        # --ratio is the share kept by the original (left) pane
        set -l side (_hdev_h pane split $main --direction right --ratio 0.7 --cwd $root --no-focus | jq -r .result.pane.pane_id)
        test -n "$side"; or return 1
        _hdev_h pane run $main 'nvim .' >/dev/null; or return 1
        _hdev_h pane run $side $agent >/dev/null
    else
        _hdev_h pane run $main $agent >/dev/null
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

# -e on a project whose agent already runs: add nvim left of that agent (70/30)
# unless some pane in the workspace already runs nvim. Never starts an agent.
function _hdev_add_editor -a agent_pane root
    set -l ws (string split -f1 : $agent_pane)
    for p in (_hdev_h pane list --workspace $ws | jq -r '.result.panes[].pane_id')
        _hdev_h pane process-info --pane $p | jq -e '.result.process_info.foreground_processes[] | select(.argv0 == "nvim")' >/dev/null; and return
    end
    # split leaves the agent in the left 70% slot; swap moves nvim into it
    set -l ed (_hdev_h pane split $agent_pane --direction right --ratio 0.7 --cwd $root --no-focus | jq -r .result.pane.pane_id)
    test -n "$ed"; or return 1
    _hdev_h pane swap --source-pane $agent_pane --target-pane $ed >/dev/null; or return 1
    _hdev_h pane run $ed 'nvim .' >/dev/null
end
