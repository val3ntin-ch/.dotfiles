function tdev -d "Create structured tmux dev session: nvim 70% + terminal 30%"
    set -l name (basename $PWD)
    test (count $argv) -ge 1; and set name $argv[1]
    set -l root $PWD
    if test (count $argv) -ge 2
        set root $argv[2]
    else if test (count $argv) -eq 1
        if test -d $argv[1]
            # arg is a path — use it directly
            set root (realpath $argv[1])
        else
            # resolve project path via zoxide (like `z <name>`)
            set -l zdir (zoxide query $argv[1] 2>/dev/null)
            test -n "$zdir"; and set root $zdir
        end
        set name (basename $root)
    end
    # tmux session names can't contain . or : (target separators)
    set name (string replace -a . _ $name)

    if not tmux has-session -t $name 2>/dev/null
        tmux new-session -d -s $name -c $root

        # Single window: nvim left 70% + terminal right 30%
        tmux rename-window -t "$name:1" dev
        tmux split-window -t "$name:dev" -h -l 30% -c $root
        tmux select-pane -t "$name:dev.left"
        tmux send-keys -t "$name:dev.left" 'nvim .' Enter
    end

    if test -n "$TMUX"
        tmux switch-client -t $name
    else
        tmux attach-session -t $name
    end
end
