function tdev -d "Create structured tmux dev session: nvim 70% + terminal 30%"
    set -l name (basename $PWD)
    set -l root $PWD
    # true when name/root came from a resolved path (0 args, a dir arg, or a
    # zoxide hit) rather than a literal name the user typed on purpose
    set -l auto_derived true

    if test (count $argv) -ge 2
        set name $argv[1]
        set root $argv[2]
        set auto_derived false
    else if test (count $argv) -eq 1
        if test -d $argv[1]
            # arg is a path — use it directly
            set root (realpath $argv[1])
            set name (basename $root)
        else
            # resolve project path via zoxide (like `z <name>`)
            set -l zdir (zoxide query $argv[1] 2>/dev/null)
            if test -n "$zdir"
                set root $zdir
                set name (basename $root)
            else
                set name $argv[1]
                set auto_derived false
            end
        end
    end

    if test "$auto_derived" = true
        # disambiguate folders that share a basename under different parents
        # (e.g. two repos each with a "mobile/" dir) — without this, `tdev`
        # would find the OTHER project's session already running under the
        # same short name and switch you into it instead of making a new one
        set -l hash (string sub -l 6 (echo -n $root | md5sum | string split ' ')[1])
        set name "$name-$hash"
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
