#!/bin/bash

set -e

DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/o8n/dotfiles.git"

# シンボリックリンクを作成する関数
create_symlink() {
    local src=$1
    local dest=$2
    if [ -L "$dest" ]; then
        echo "Removing existing symlink: $dest"
        rm "$dest"
    elif [ -e "$dest" ]; then
        echo "Backing up existing file: $dest -> ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi
    ln -s "$src" "$dest"
    echo "Created symlink: $dest -> $src"
}

# dotfilesリポジトリをクローン
if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles directory already exists. Pulling latest changes..."
    cd "$DOTFILES_DIR"
    git pull
else
    echo "Cloning dotfiles repository..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# ~/.configディレクトリを作成
mkdir -p "$HOME/.config"

# シンボリックリンクを作成
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# グローバルgit hooksをインストール（AI dual review）
if [ -f "$DOTFILES_DIR/hooks/install-hooks.sh" ]; then
    bash "$DOTFILES_DIR/hooks/install-hooks.sh"
fi

echo "Dotfiles setup completed!"
