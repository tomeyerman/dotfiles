# ~/.zshrc

if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.dotnet/tools:$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# bun
export BUN_INSTALL="$HOME/.bun"
if [ -d "$BUN_INSTALL/bin" ] && ! [[ "$PATH" =~ "$BUN_INSTALL/bin" ]]; then
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# cargo (Rust) — only if installed
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Warp Terminal: warpify this zsh subshell so Warp's input layer
# gets explicit prompt boundary signals. No-op outside Warp.
if [ "$TERM_PROGRAM" = "WarpTerminal" ]; then
    printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh"}}\x9c'
fi

# github desktop via flatpak — alias only if flatpak is available
if command -v flatpak >/dev/null 2>&1; then
    alias github='flatpak run io.github.shiftey.Desktop &>/dev/null &'
fi

autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
setopt MENU_COMPLETE

# starship prompt — only if installed
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
