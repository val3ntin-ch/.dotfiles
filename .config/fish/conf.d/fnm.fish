# ~/.config/fish/conf.d/fnm.fish
# fnm (Fast Node Manager) — auto-switch node version on cd (.nvmrc / .node-version)
if command -q fnm
    fnm env --use-on-cd | source
end
