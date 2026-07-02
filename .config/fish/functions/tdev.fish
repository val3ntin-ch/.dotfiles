function tdev -d "Create structured tmux dev session: editor + dev split"
    set -l name (basename $PWD)
    test (count $argv) -ge 1; and set name $argv[1]
    set -l root $PWD
    if test (count $argv) -ge 2
        set root $argv[2]
    else if test (count $argv) -eq 1
        # resolve project path via zoxide (like `z <name>`)
        set -l zdir (zoxide query $argv[1] 2>/dev/null)
        test -n "$zdir"; and set root $zdir
        set name (basename $root)
    end

    if not tmux has-session -t $name 2>/dev/null
        tmux new-session -d -s $name -c $root

        # Window 1: editor
        tmux rename-window -t "$name:1" editor
        tmux send-keys -t "$name:editor" 'nvim .' Enter

        # Window 2: dev — main pane (nvim) + right 10% + bottom 5% (server)
        tmux new-window -t $name -n dev -c $root
        tmux split-window -t "$name:dev" -h -l 10% -c $root
        tmux select-pane -t "$name:dev.left"
        tmux split-window -t "$name:dev" -v -l 5% -c $root
        tmux select-pane -t "$name:dev.{top-left}"
        tmux send-keys -t "$name:dev" 'nvim .' Enter
    end

    if test -n "$TMUX"
        tmux switch-client -t $name
    else
        tmux attach-session -t $name
    end
end
