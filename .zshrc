source ~/.zsh/env.zsh
source ~/.zsh/completion.zsh
source ~/.zsh/aliases.zsh
source ~/.zsh/history.zsh
source ~/.zsh/prompt.zsh
source ~/.zsh/options.zsh
source ~/.zsh/path.zsh

# ローカル設定（マシン固有の設定を上書きできる）
[[ -f ~/.zshrc_local ]] && source ~/.zshrc_local
