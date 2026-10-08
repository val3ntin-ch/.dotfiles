# ~/.config/fish/conf.d/path.fish
# Do NOT set TERM globally.

fish_add_path -g $HOME/bin
fish_add_path -g $HOME/.local/bin

# Homebrew paths (macOS)
if test (uname) = Darwin
    fish_add_path -g /opt/homebrew/bin /opt/homebrew/sbin
    fish_add_path -g /usr/local/bin /usr/local/sbin
end

# pnpm
set -gx PNPM_HOME $HOME/.local/share/pnpm
fish_add_path -g $PNPM_HOME

# bun
set -gx BUN_INSTALL $HOME/.bun
fish_add_path -g $BUN_INSTALL/bin

# Go
set -gx GOPATH $HOME/.local/share/go
fish_add_path -g $GOPATH/bin

# Java (Zulu JDK 17 — React Native Android)
if test -d /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
    set -gx JAVA_HOME /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
end

# Android SDK (React Native) — macOS default, else Android Studio's Linux default
if test -d $HOME/Library/Android/sdk; or test -d $HOME/Android/Sdk
    set -gx ANDROID_HOME $HOME/Library/Android/sdk
    test -d $ANDROID_HOME; or set -gx ANDROID_HOME $HOME/Android/Sdk
    fish_add_path -g $ANDROID_HOME/emulator
    fish_add_path -g $ANDROID_HOME/platform-tools
end
