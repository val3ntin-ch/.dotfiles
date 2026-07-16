function fal -d "Fuzzy alias/abbr finder: fal (all), fal git, fal tmux"
    begin
        alias
        abbr
    end | sort | fzf --prompt='alias ❯ ' --query="$argv" \
        --preview='echo {}' --preview-window='down:3:wrap'
end
