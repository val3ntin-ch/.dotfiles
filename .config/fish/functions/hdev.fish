function hdev -d "Herdr dev workspace: nvim 70% + agent 30%"
    # Usage: hdev [-a claude|codex|opencode] [project-dir | zoxide-query]
    # Mirrors zsh version: .config/zsh/conf.d/functions.zsh
    argparse 'a/agent=' -- $argv; or return
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

    # reuse an existing workspace for this project instead of opening a twin
    set -l ws (herdr workspace list | jq -r --arg l $name '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -1)
    if test -n "$ws"; and test "$ws" != "$HERDR_WORKSPACE_ID"
        herdr workspace focus $ws >/dev/null
        return
    end

    # already in this project's workspace: build the layout right here
    if test -n "$ws"
        set -l side (herdr pane split --current --direction right --ratio 0.7 --cwd $root --no-focus | jq -r .result.pane.pane_id)
        herdr pane run $side $agent >/dev/null
        cd $root; and nvim .
        return
    end

    set -l editor (herdr workspace create --cwd $root --label $name --focus | jq -r .result.root_pane.pane_id)
    # --ratio is the share kept by the original (left) pane
    set -l side (herdr pane split $editor --direction right --ratio 0.7 --cwd $root --no-focus | jq -r .result.pane.pane_id)
    herdr pane run $editor 'nvim .' >/dev/null
    herdr pane run $side $agent >/dev/null
end
