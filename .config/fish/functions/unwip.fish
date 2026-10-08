function unwip -d "Undo last WIP commit, keep changes unstaged"
    set -l msg (git log -1 --pretty=%s)
    if string match -q 'wip:*' $msg
        git reset HEAD~1
        echo "wip commit undone, changes kept, unstaged"
    else
        echo "last commit is not a wip commit: '$msg'"
        return 1
    end
end
