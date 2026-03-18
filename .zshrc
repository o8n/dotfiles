export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.rbenv/shims:$PATH"
export PATH="/usr/local/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="$HOME/.nodebrew/current/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

if [[ -n "${NVIM:-}" ]]; then
  export ZSH_MINIMAL=1

  # 軽量gitブランチ表示
  function _git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [[ -n "$branch" ]] && echo " ($branch)"
  }

  setopt PROMPT_SUBST
  PS1='%F{cyan}%~%f%F{yellow}$(_git_branch)%f %F{magenta}❯%f '
fi

### git-completion
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
if [[ -z "${ZSH_MINIMAL:-}" ]]; then
  autoload -Uz compinit
  if [[ -s "${ZDOTDIR:-$HOME}/.zcompdump" ]]; then
    compinit -C
  else
    compinit
  fi
fi

### prompt
if [[ -z "${ZSH_MINIMAL:-}" ]] && [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ -z "${ZSH_MINIMAL:-}" ]] && [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

if [[ -z "${ZSH_MINIMAL:-}" ]]; then
  ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
  [ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
  [ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  source "${ZINIT_HOME}/zinit.zsh"
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit

  # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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
  zinit ice from"gh-r" as"program"
  zinit light junegunn/fzf

  # Scripts built at install (there's single default make target, "install",
  # and it constructs scripts by `cat'ing a few files). The make'' ice could also be:
  # `make"install PREFIX=$ZPFX"`, if "install" wouldn't be the only default target.
  zinit ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX"
  zinit light tj/git-extras
fi

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

if [[ -z "${ZSH_MINIMAL:-}" ]]; then
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
fi

function load-rbenv() {
  unfunction load-rbenv
  eval "$(rbenv init - zsh)"
}

for cmd in ruby irb gem bundle bundler rails rake rbenv; do
  eval "
  function ${cmd}() {
    load-rbenv
    command ${cmd} \"\$@\"
  }
  "
done

# ローカル環境固有の設定（APIキーなど）
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

# ============================================
# Docker cleanup（必要時のみ手動実行）
# ============================================
function docker-prune-weekly() {
  local marker="$HOME/.docker_last_prune"

  if [[ -f "$marker" ]] && ! find "$marker" -mtime +7 -print -quit 2>/dev/null | grep -q .; then
    echo "Docker cleanup is not needed yet."
    return 0
  fi

  if ! docker info &>/dev/null; then
    echo "Docker daemon is not available."
    return 1
  fi

  echo "Docker cleanup (7+ days old resources)..."
  docker system prune -f --filter "until=168h"
  touch "$marker"
}

# ============================================
# ghq + gwq + fzf 統合設定
# ============================================

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
# ============================================
# ECS Exec 接続 (fzf選択式)
# ============================================
function ecs-exec() {
    # 1. AWSプロファイル選択
    local profile
    profile=$(aws configure list-profiles | fzf --prompt="AWS Profile> ")
    if [[ -z "${profile}" ]]; then
        return 0
    fi

    export AWS_PROFILE="${profile}"
    eval $(aws configure export-credentials --profile "${profile}" --format env)
    echo "✓ Profile: ${profile}"

    # 2. クラスター選択
    local cluster
    cluster=$(aws ecs list-clusters --query 'clusterArns[*]' --output text | tr '\t' '\n' | sed 's|.*/||' | fzf --prompt="Cluster> ")
    if [[ -z "${cluster}" ]]; then
        return 0
    fi
    echo "✓ Cluster: ${cluster}"

    # 3. サービス選択 → タスク特定
    local service
    service=$(aws ecs list-services --cluster "${cluster}" --query 'serviceArns[*]' --output text | tr '\t' '\n' | sed 's|.*/||' | fzf --prompt="Service> ")
    if [[ -z "${service}" ]]; then
        return 0
    fi

    local task
    task=$(aws ecs list-tasks --cluster "${cluster}" --service-name "${service}" --desired-status RUNNING --query 'taskArns[*]' --output text | tr '\t' '\n' | sed 's|.*/||' | fzf --prompt="Task> ")
    if [[ -z "${task}" ]]; then
        return 0
    fi
    echo "✓ Task: ${task}"

    # 4. コンテナ選択（複数コンテナの場合）
    local containers container
    containers=$(aws ecs describe-tasks --cluster "${cluster}" --tasks "${task}" --query 'tasks[0].containers[*].name' --output text | tr '\t' '\n')
    if [[ $(echo "${containers}" | wc -l) -gt 1 ]]; then
        container=$(echo "${containers}" | fzf --prompt="Container> ")
    else
        container="${containers}"
    fi
    if [[ -z "${container}" ]]; then
        return 0
    fi
    echo "✓ Container: ${container}"

    # 5. ECS Exec接続
    echo "→ Connecting..."
    aws ecs execute-command \
        --cluster "${cluster}" \
        --task "${task}" \
        --container "${container}" \
        --interactive \
        --command "/bin/sh"
}

# ローカル専用設定（git管理外）
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
