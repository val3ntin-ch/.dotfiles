# ~/.config/fish/conf.d/zz-fnm.fish
# fnm (Fast Node Manager) — auto-switch node version on cd (.nvmrc / .node-version)
# zz- prefix: conf.d loads alphabetically; must run AFTER path.fish or the
# homebrew node ends up ahead of fnm's multishell path and shadows it.
if command -q fnm
    fnm env --use-on-cd | source
end
