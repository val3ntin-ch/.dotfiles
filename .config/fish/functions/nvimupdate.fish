function nvimupdate -d "Pull latest LazyVim/plugins, then remind to commit lazy-lock.json"
    nvim --headless "+Lazy! sync" +qa
    if not git -C ~/.dotfiles diff --quiet -- .config/nvim/lazy-lock.json
        echo "lazy-lock.json changed — commit it to sync this update to other machines:"
        echo "  cd ~/.dotfiles && git add .config/nvim/lazy-lock.json && git commit -m 'chore(nvim): update plugins'"
    else
        echo "lazy-lock.json unchanged — already on latest"
    end
end
