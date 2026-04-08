# oh-my-posh (https://github.com/JanDeDobbeleer/oh-my-posh) の themes を参考にデザイン
setopt prompt_subst

# git情報の表示
autoload -Uz vcs_info
precmd_functions+=(precmd_vcs_info)
precmd_vcs_info() { vcs_info }
zstyle ':vcs_info:*' enable git

# Powerline/Nerd Fonts 文字（要対応フォント）
_PL_SEP_R=$'\ue0b0'   #
_PL_CHIP_L=$'\ue0b6'  #
_PL_CHIP_R=$'\ue0b4'  #
_PL_BRANCH=$'\ue0a0'  #

# カラー定義（256色）
_C_ROOT=95    # くすんだローズ（root用）

# Truecolor定義（24bit）
_TC_BG_HOST=$'\e[48;2;34;34;34m'          # #222222
_TC_FG_HOST=$'\e[38;2;34;34;34m'          # #222222
_TC_BG_DIR=$'\e[48;2;32;50;72m'           # #203248
_TC_FG_DIR=$'\e[38;2;32;50;72m'           # #203248
_TC_BG_PATH=$'\e[48;2;32;50;72m'          # #203248
_TC_FG_PATH=$'\e[38;2;32;50;72m'          # #203248
_TC_BG_BRANCH=$'\e[48;2;41;49;90m'        # #29315A
_TC_FG_BRANCH=$'\e[38;2;41;49;90m'        # #29315A
_TC_FG_BRANCH_TEXT=$'\e[38;2;255;146;72m' # #ff9248
_TC_RESET=$'\e[0m'

zstyle ':vcs_info:git:*' formats "%{${_TC_FG_BRANCH}%}${_PL_CHIP_L}%{${_TC_BG_BRANCH}%}%{${_TC_FG_BRANCH_TEXT}%} ${_PL_BRANCH} %b %{${_TC_RESET}%}%{${_TC_FG_BRANCH}%}${_PL_CHIP_R}%{${_TC_RESET}%} "
zstyle ':vcs_info:git:*' actionformats "%{${_TC_FG_BRANCH}%}${_PL_CHIP_L}%{${_TC_BG_BRANCH}%}%{${_TC_FG_BRANCH_TEXT}%} ${_PL_BRANCH} %b|%a %{${_TC_RESET}%}%{${_TC_FG_BRANCH}%}${_PL_CHIP_R}%{${_TC_RESET}%} "

precmd_functions+=(precmd_prompt)
precmd_prompt() {
    local _rprompt="${vcs_info_msg_0_}%{${_TC_FG_PATH}%}${_PL_CHIP_L}%{${_TC_BG_PATH}%}%F{white} %~ %{${_TC_RESET}%}%{${_TC_FG_PATH}%}${_PL_CHIP_R}%{${_TC_RESET}%}"
    case ${UID} in
    0)
        if [[ -n "${SSH_CONNECTION}" || -f /.dockerenv ]]; then
            PROMPT="%{${_TC_FG_HOST}%}${_PL_CHIP_L}%{${_TC_BG_HOST}%}%F{white}%B %n@%m %b%K{${_C_ROOT}}%{${_TC_FG_HOST}%}${_PL_SEP_R}%F{white}%B %1~ %b%k%F{${_C_ROOT}}${_PL_SEP_R}%{${_TC_RESET}%} "
        else
            PROMPT="%K{${_C_ROOT}}%F{white}%B %1~ %b%k%F{${_C_ROOT}}${_PL_SEP_R}%{${_TC_RESET}%} "
        fi
        RPROMPT="${_rprompt}"
        ;;
    *)
        if [[ -n "${SSH_CONNECTION}" || -f /.dockerenv ]]; then
            PROMPT="%{${_TC_FG_HOST}%}${_PL_CHIP_L}%{${_TC_BG_HOST}%}%F{white} %n@%m %{${_TC_BG_DIR}%}%{${_TC_FG_HOST}%}${_PL_SEP_R}%F{white} %1~ %{${_TC_RESET}%}%{${_TC_FG_DIR}%}${_PL_SEP_R}%{${_TC_RESET}%} "
        else
            PROMPT="%{${_TC_FG_DIR}%}${_PL_CHIP_L}%{${_TC_BG_DIR}%}%F{white} %1~ %{${_TC_RESET}%}%{${_TC_FG_DIR}%}${_PL_SEP_R}%{${_TC_RESET}%} "
        fi
        RPROMPT="${_rprompt}"
        ;;
    esac
}

SPROMPT="%F{red}%r is correct? [n,y,a,e]:%f "
