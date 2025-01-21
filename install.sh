#!/bin/bash

# GitHubリポジトリのURL
REPO_URL="https://raw.githubusercontent.com/o8n/dotfiles/master"

# シンボリックリンクを作成する関数
create_symlink() {
    local src=$1
    local dest=$2
    if [ -e "$dest" ]; then
        echo "$dest already exists. Skipping..."
    else
        ln -s "$src" "$dest"
        echo "Created symlink: $dest -> $src"
    fi
}

# 一時ディレクトリを作成
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# zshrcをダウンロードしてシンボリックリンクを作成
curl -LO "$REPO_URL/zshrc"
create_symlink "$TEMP_DIR/zshrc" "$HOME/.zshrc"

# tmux.confをダウンロードしてシンボリックリンクを作成
curl -LO "$REPO_URL/tmux.conf"
create_symlink "$TEMP_DIR/tmux.conf" "$HOME/.tmux.conf"

# vimrcをダウンロードしてシンボリックリンクを作成
curl -LO "$REPO_URL/vimrc"
create_symlink "$TEMP_DIR/vimrc" "$HOME/.vimrc"

# nvimディレクトリをダウンロードしてシンボリックリンクを作成
mkdir -p $TEMP_DIR/nvim
curl -LO "$REPO_URL/nvim/init.vim"
mv init.vim nvim/
create_symlink "$TEMP_DIR/nvim" "$HOME/.config/nvim"

echo "Dotfiles setup completed!"

