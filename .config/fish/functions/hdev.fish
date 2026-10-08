function hdev -d "Herdr workspace for a project: agent (+ nvim with -e)"
    # Usage: hdev [-e] [-n] [-a claude|codex|opencode] [project-dir | zoxide-query]
    #   -e  also open nvim (left 70%, agent right 30%)
    #   -n  always open a new workspace, even if the project already has one
    # Without -n, an agent already running in the project is focused instead
    # of starting a duplicate.
    # Mirrors zsh version: .config/zsh/conf.d/functions.zsh
    argparse 'a/agent=' e/editor n/new -- $argv; or return
    set -l agent claude
    set -q _flag_agent; and set agent $_flag_agent

    set -l root $PWD
    if test (count $argv) -ge 1
        if test -d $argv[1]
            set root (realpath $argv[1])
        else
            # resolve project path via zoxide (like `z <name>`)
            set root (zoxide query $argv[1] 2>/dev/null)
            if test -z "$root"
                echo "hdev: no directory matches '$argv[1]'" >&2
                return 1
            end
        end
    end
    set -l name (basename $root)

    if test "$HERDR_ENV" != 1
        echo "hdev: run inside herdr (start it with: herdr)" >&2
        return 1
    end

    if not set -q _flag_new
        # same agent already running in this project → just go there
        set -l running (herdr agent list | jq -r --arg r $root --arg a $agent '.result.agents[] | select(.cwd == $r and .agent == $a) | .pane_id' | head -1)
        if test -n "$running"
            herdr agent focus $running >/dev/null
            return
        end
    end

    set -l main
    set -l ws
    set -q _flag_new; or set ws (herdr workspace list | jq -r --arg l $name '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -1)
    if test -n "$ws"; and test "$ws" = "$HERDR_WORKSPACE_ID"
        # already in the project's workspace: add the agent beside this pane
        set main (herdr pane split --current --direction right --ratio 0.5 --cwd $root --no-focus | jq -r .result.pane.pane_id)
    else if test -n "$ws"
        herdr workspace focus $ws >/dev/null
        set -l first (herdr pane list --workspace $ws | jq -r '.result.panes[0].pane_id')
        set main (herdr pane split $first --direction right --ratio 0.5 --cwd $root --focus | jq -r .result.pane.pane_id)
    else
        set main (herdr workspace create --cwd $root --label $name --focus | jq -r .result.root_pane.pane_id)
    end

    if set -q _flag_editor
        # --ratio is the share kept by the original (left) pane
        set -l side (herdr pane split $main --direction right --ratio 0.7 --cwd $root --no-focus | jq -r .result.pane.pane_id)
        herdr pane run $main 'nvim .' >/dev/null
        herdr pane run $side $agent >/dev/null
    else
        herdr pane run $main $agent >/dev/null
    end
end
