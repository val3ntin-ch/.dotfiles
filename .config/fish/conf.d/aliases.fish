# ~/.config/fish/conf.d/aliases.fish
if status is-interactive

    # ── Editor ────────────────────────────────────────────────────────────────
    command -q nvim; and alias vim nvim; and alias vi nvim; and alias nv nvim; and alias v nvim
    alias svim 'sudo -E nvim'
    alias inv 'nvim (fzf -m --preview="bat --color=always {}")'

    # ── bat ───────────────────────────────────────────────────────────────────
    if command -q bat
        alias cat     'bat --paging=never --style=plain'
        alias catn    'bat --paging=never --style=numbers,changes'
        alias catp    'bat --style=numbers,changes,header'
        alias batdiff 'bat --diff'
    end

    # ── navigation ────────────────────────────────────────────────────────────
    alias .. 'cd ..'
    alias ... 'cd ../..'
    alias .... 'cd ../../..'
    alias ..... 'cd ../../../..'

    # ── ripgrep ───────────────────────────────────────────────────────────────
    if command -q rg
        alias rg   'command rg --color=always --smart-case'
        alias rgi  'command rg --ignore-case'
        alias rgf  'command rg --files-with-matches'
        alias rgts 'command rg --type=ts'
        alias rgjs 'command rg --type=js'
    end

    # ── fd ────────────────────────────────────────────────────────────────────
    if command -q fd
        alias fd  'command fd --color=always'
        alias fdf 'command fd --type f'
        alias fdd 'command fd --type d'
        alias fdh 'command fd --hidden'
    end

    # ── pnpm ──────────────────────────────────────────────────────────────────
    alias pn     pnpm
    alias pni    'pnpm install'
    alias pna    'pnpm add'
    alias pnad   'pnpm add -D'
    alias pnr    'pnpm run'
    alias pnd    'pnpm dev'
    alias pnb    'pnpm build'
    alias pnt    'pnpm test'
    alias pntw   'pnpm test --watch'
    alias pnl    'pnpm lint'
    alias pnlf   'pnpm lint --fix'
    alias pntc   'pnpm typecheck'
    alias pnx    'pnpm dlx'
    alias pnup   'pnpm update --interactive --latest'
    alias pnwhy  'pnpm why'
    alias pnclean 'rm -rf node_modules .turbo dist; and pnpm install'

    # ── React Native / Expo ───────────────────────────────────────────────────
    alias rni    'npx react-native run-ios'
    alias rna    'npx react-native run-android'
    alias rnios  'npx react-native run-ios --simulator="iPhone 15 Pro"'
    alias pods   'cd ios; and bundle exec pod install; and cd ..'
    alias rnclean 'watchman watch-del-all; and rm -rf node_modules ios/Pods ios/build android/build; and pnpm install'
    alias expo   'npx expo'
    alias expod  'npx expo start'
    alias expob  'npx expo build'
    alias expodc 'npx expo start --clear'

    # ── system ────────────────────────────────────────────────────────────────
    alias reload 'exec fish'
    # not `path` — that shadows fish's builtin `path`, which completion and
    # autosuggestions call while typing (spams "usage: nl")
    alias paths  'printf "%s\n" $PATH | nl'
    alias ports  'lsof -i -P -n | grep LISTEN'
    alias myip   'curl -s https://api.ipify.org; and echo'
    alias df     'df -h'
    alias du     'du -sh'
    alias dua    'du -sh * | sort -h'
    alias psa    'ps aux'
    alias psg    'ps aux | grep'
    alias ping   'ping -c 5'

    # ── dotfiles ──────────────────────────────────────────────────────────────
    alias dot    'cd ~/.dotfiles'
    alias frc    'nvim ~/.config/fish/config.fish'
    alias falias 'nvim ~/.config/fish/conf.d/aliases.fish'
    alias fenv   'nvim ~/.config/fish/conf.d/env.fish'
    alias fpath  'nvim ~/.config/fish/conf.d/path.fish'
    alias ffn    'nvim ~/.config/fish/functions'

    # ── clipboard ─────────────────────────────────────────────────────────────
    if test (uname) = Darwin
        alias copy  pbcopy
        alias paste pbpaste
    else if command -q wl-copy
        alias copy  wl-copy
        alias paste wl-paste
    else if command -q xclip
        alias copy  'xclip -selection clipboard'
        alias paste 'xclip -selection clipboard -o'
    end

    # ── macOS ─────────────────────────────────────────────────────────────────
    if test (uname) = Darwin
        alias o         open
        alias ql        'qlmanage -p 2>/dev/null'
        alias flushdns  'sudo dscacheutil -flushcache; and sudo killall -HUP mDNSResponder'
        alias showfiles 'defaults write com.apple.finder AppleShowAllFiles YES; and killall Finder'
        alias hidefiles 'defaults write com.apple.finder AppleShowAllFiles NO; and killall Finder'
        alias cleanup   'find . -type f -name "*.DS_Store" -delete'
        alias update    'brew update; and brew upgrade; and brew autoremove; and brew cleanup'
        alias brewdump  'brew bundle dump --file=~/.dotfiles/Brewfile --force'
        alias awake     'caffeinate -d'
    else if test (uname) = Linux
        alias o      xdg-open
        alias update 'sudo apt update; and sudo apt upgrade -y; and sudo apt autoremove -y'
    end

end
