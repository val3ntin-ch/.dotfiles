function yaziupdate -d "Pull latest yazi plugin revs, then remind to commit package.toml"
    pushd ~/.config/yazi
    ya pkg upgrade --discard
    popd
    if not git -C ~/.dotfiles diff --quiet -- .config/yazi/package.toml
        echo "package.toml changed — commit it to sync this update to other machines:"
        echo "  cd ~/.dotfiles && git add .config/yazi/package.toml && git commit -m 'chore(yazi): update plugins'"
    else
        echo "package.toml unchanged — already on latest"
    end
end
