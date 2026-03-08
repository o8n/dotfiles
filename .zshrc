### git-completion
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
autoload -Uz compinit && compinit

### prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Load the pure theme, with zsh-async library that's bundled with it.
zi ice pick"async.zsh" src"pure.zsh"
zi light sindresorhus/pure

# A glance at the new for-syntax – load all of the above
# plugins with a single command. For more information see:
# https://zdharma-continuum.github.io/zinit/wiki/For-Syntax/
zinit for \
    light-mode \
  zsh-users/zsh-autosuggestions \
    light-mode \
  zdharma-continuum/fast-syntax-highlighting \
    light-mode \
    pick"async.zsh" \
    src"pure.zsh" \
  sindresorhus/pure

# Binary release in archive, from GitHub-releases page.
# After automatic unpacking it provides program "fzf".
zi ice from"gh-r" as"program"
zi light junegunn/fzf

# One other binary release, it needs renaming from `docker-compose-Linux-x86_64`.
# This is done by ice-mod `mv'{from} -> {to}'. There are multiple packages per
# single version, for OS X, Linux and Windows – so ice-mod `bpick' is used to
# select Linux package – in this case this is actually not needed, Zinit will
# grep operating system name and architecture automatically when there's no `bpick'.

# zi ice from"gh-r" as"program" mv"docker* -> docker-compose" bpick"*linux*"
# zi load docker/compose

# Vim repository on GitHub – a typical source code that needs compilation – Zinit
# can manage it for you if you like, run `./configure` and other `make`, etc.
# Ice-mod `pick` selects a binary program to add to $PATH. You could also install the
# package under the path $ZPFX, see: https://zdharma-continuum.github.io/zinit/wiki/Compiling-programs
zi ice \
  as"program" \
  atclone"rm -f src/auto/config.cache; ./configure" \
  atpull"%atclone" \
  make \
  pick"src/vim"
zi light vim/vim

# Scripts built at install (there's single default make target, "install",
# and it constructs scripts by `cat'ing a few files). The make'' ice could also be:
# `make"install PREFIX=$ZPFX"`, if "install" wouldn't be the only default target.
zi ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX"
zi light tj/git-extras

###
### git completion
###
source ~/.zsh/git-prompt.sh
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
# autoload -Uz compinit && compinit
## プロンプトのオプション表示設定
# GIT_PS1_SHOWDIRTYSTATE=true
# GIT_PS1_SHOWUNTRACKEDFILES=true
# GIT_PS1_SHOWSTASHSTATE=true
# GIT_PS1_SHOWUPSTREAM=auto
## プロンプトの表示設定(好きなようにカスタマイズ可)
# setopt PROMPT_SUBST ; PS1='%F{green}%n@%m%f: %F{cyan}%~%f %F{red}$(__git_ps1 "(%s)")%f
# \$ '


###
### Open VSCode
###
function code {
    if [[ $# = 0 ]]
    then
        open -a "Visual Studio Code"
    else
        local argPath="$1"
        [[ $1 = /* ]] && argPath="$1" || argPath="$PWD/${1#./}"
        open -a "Visual Studio Code" "$argPath"
    fi
}

# ============================================
# zeno.zsh (abbreviation + smart history)
# ============================================
export ZENO_HOME="$HOME/.config/zeno"

zinit ice lucid depth"1" blockf
zinit light yuki-yano/zeno.zsh

# キーバインド
bindkey ' '   zeno-auto-snippet                   # Space: abbr展開
bindkey '^m'  zeno-auto-snippet-and-accept-line   # Enter: 展開&実行
bindkey '^i'  zeno-completion                     # Tab: 補完
bindkey '^x ' zeno-insert-space                   # Ctrl-X Space: 空白挿入（展開回避）
bindkey '^xs' zeno-insert-snippet                 # Ctrl-X S: スニペット選択

# fzf履歴検索 (Ctrl-R)
function fzf-history-widget() {
  local selected
  selected=$(fc -rl 1 | awk '{$1=""; print substr($0,2)}' | fzf --no-sort --query "${LBUFFER}")
  if [[ -n "$selected" ]]; then
    LBUFFER="$selected"
    RBUFFER=""
  fi
  zle reset-prompt
}
zle -N fzf-history-widget
bindkey '^r' fzf-history-widget
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.rbenv/shims:$PATH"
export PATH="/usr/local/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH=$HOME/.nodebrew/current/bin:$PATH

# ローカル環境固有の設定（APIキーなど）
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

# ============================================
# Docker 週次クリーンアップ（ターミナル起動時）
# ============================================
DOCKER_PRUNE_MARKER="$HOME/.docker_last_prune"
if [[ ! -f "$DOCKER_PRUNE_MARKER" ]] || [[ $(find "$DOCKER_PRUNE_MARKER" -mtime +7 2>/dev/null) ]]; then
  if docker info &>/dev/null; then
    echo "🐳 Docker cleanup (7+ days old resources)..."
    docker system prune -f --filter "until=168h" 2>/dev/null
    touch "$DOCKER_PRUNE_MARKER"
  fi
fi

# ============================================
# ghq + gwq + fzf 統合設定
# ============================================

# GOPATH/bin をPATHに追加
export PATH="$HOME/go/bin:$PATH"

# ghqで管理しているリポジトリをfzfで検索してパスを返す
function ghq-path() {
    ghq list --full-path | fzf --preview 'ls -la {}'
}

# リポジトリを選択して移動 + tmuxセッション名を更新
function dev() {
    local moveto
    moveto=$(ghq-path)

    if [[ -z "${moveto}" ]]; then
        return 0
    fi

    cd "${moveto}" || return 1

    # tmux使用時はセッション名を更新
    if [[ -n ${TMUX} ]]; then
        local repo_name
        repo_name="${moveto##*/}"
        tmux rename-session "${repo_name//./-}"
    fi
}

# gwqでworktreeを作成
function gwq-add() {
    local branch_name="${1}"
    if [[ -z "${branch_name}" ]]; then
        echo "Usage: gwq-add <branch-name>"
        return 1
    fi
    gwq add -b "${branch_name}"
}

# gwqでworktreeをfzf選択して移動
function gwq-switch() {
    local worktree
    worktree=$(gwq list | fzf --preview 'ls -la {}')

    if [[ -z "${worktree}" ]]; then
        return 0
    fi

    cd "${worktree}" || return 1
}

# worktreeの状態を一覧表示
function gwq-status() {
    gwq status
}

# worktreeを削除（fzf選択）
function gwq-remove() {
    local worktree
    worktree=$(gwq list | fzf)

    if [[ -z "${worktree}" ]]; then
        return 0
    fi

    echo "Remove worktree: ${worktree}? [y/N]"
    read -r confirm
    if [[ "${confirm}" == "y" || "${confirm}" == "Y" ]]; then
        gwq remove "${worktree}"
    fi
}
export PATH="$HOME/.local/bin:$PATH"
