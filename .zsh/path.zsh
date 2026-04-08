export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

eval "$(fnm env --use-on-cd)"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Added by Amplify CLI binary installer
export PATH="$HOME/.amplify/bin:$PATH"

# Claude, etc
export PATH="$HOME/.local/bin:$PATH"
