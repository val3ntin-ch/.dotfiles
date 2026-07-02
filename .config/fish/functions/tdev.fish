function tdev -d "Create structured tmux dev session: editor + dev split"
    set -l name (basename $PWD)
    test (count $argv) -ge 1; and set name $argv[1]
    set -l root $PWD
    test (count $argv) -ge 2; and set root $argv[2]

    if not tmux has-session -t $name 2>/dev/null
        tmux new-session -d -s $name -c $root

        # Window 1: editor
        tmux rename-window -t "$name:1" editor
        tmux send-keys -t "$name:editor" 'nvim .' Enter

        # Window 2: dev (horizontal split)
        tmux new-window -t $name -n dev -c $root
        tmux split-window -t "$name:dev" -h -c $root
        tmux select-pane -t "$name:dev.left"
    end

    if test -n "$TMUX"
        tmux switch-client -t $name
    else
        tmux attach-session -t $name
    end
end
