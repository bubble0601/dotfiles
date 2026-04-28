source ~/dotfiles/.zsh/env.zsh
source ~/dotfiles/.zsh/completion.zsh
source ~/dotfiles/.zsh/aliases.zsh
source ~/dotfiles/.zsh/history.zsh
source ~/dotfiles/.zsh/prompt.zsh
source ~/dotfiles/.zsh/options.zsh
source ~/dotfiles/.zsh/path.zsh
source ~/dotfiles/.zsh/plugins.zsh
source ~/dotfiles/.zsh/abbreviations.zsh

# fzf key-bindings + completion (v0.48.0+)
command -v fzf >/dev/null && source <(fzf --zsh)
