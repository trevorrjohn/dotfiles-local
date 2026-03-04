#!/bin/bash
set -e

DOTFILES_LOCAL="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing brew packages"
brew install zoxide tmux hammerspoon neovim mise
brew install --cask font-atkinson-hyperlegible-next

echo "==> Setting up Alacritty"
mkdir -p ~/.config/alacritty
ln -fs "$DOTFILES_LOCAL/alacritty.yml" ~/.config/alacritty/alacritty.yml

echo "==> Setting up Ghostty"
mkdir -p ~/.config/ghostty
ln -fs "$DOTFILES_LOCAL/ghostty-config" ~/.config/ghostty/config

echo "==> Setting up GPG (optional)"
brew install gpg 2>/dev/null || true
mkdir -p ~/.gpg-keys ~/.gnupg
ln -fs "$DOTFILES_LOCAL/gpg-agent.conf" ~/.gnupg/gpg-agent.conf
if [ -f ~/Downloads/trevor-gpg-private.asc ] || [ -f ~/Downloads/trevor-gpg-public.asc ]; then
  mv -f ~/Downloads/trevor-gpg-private.asc ~/Downloads/trevor-gpg-public.asc ~/.gpg-keys/ 2>/dev/null || true
fi
if [ -f ~/.gpg-keys/trevor-gpg-public.asc ]; then
  gpg --import ~/.gpg-keys/trevor-gpg-public.asc
  gpg --import ~/.gpg-keys/trevor-gpg-private.asc
else
  echo "    Skipping GPG key import. To set up GPG manually:"
  echo "      1. Download trevor-gpg-private.asc and trevor-gpg-public.asc from 1Password to ~/Downloads"
  echo "      2. Run this script again"
fi

echo "==> Setting up Hammerspoon"
mkdir -p ~/.hammerspoon/Spoons
ln -fs "$DOTFILES_LOCAL/init.lua" ~/.hammerspoon/init.lua
curl -sL -o /tmp/ShiftIt.spoon.zip https://github.com/peterklijn/hammerspoon-shiftit/raw/master/Spoons/ShiftIt.spoon.zip
unzip -o /tmp/ShiftIt.spoon.zip -d ~/.hammerspoon/Spoons/
rm /tmp/ShiftIt.spoon.zip

echo "==> Setting up Neovim"
if [ ! -d ~/.config/nvim ]; then
  git clone git@github.com:trevorrjohn/nvim-config.git ~/.config/nvim
else
  echo "    ~/.config/nvim already exists, skipping"
fi

echo "==> Setting up Git config"
existing_name=$(git config --global user.name 2>/dev/null || true)
existing_email=$(git config --global user.email 2>/dev/null || true)
if [ -n "$existing_name" ] && [ -n "$existing_email" ]; then
  echo "    Already configured: $existing_name <$existing_email>"
else
  read -p "    Git user.name: " git_name
  read -p "    Git user.email: " git_email
  git config --global user.name "$git_name"
  git config --global user.email "$git_email"
fi

echo "==> Setting up Git SSH signing"
git config --global gpg.format ssh
git config --global commit.gpgsign true
git config --global tag.gpgsign true
existing_key=$(git config --global user.signingkey 2>/dev/null || true)
if [ -n "$existing_key" ]; then
  echo "    Already configured: $existing_key"
else
  echo "    Available SSH public keys:"
  pub_keys=(~/.ssh/*.pub)
  if [ ${#pub_keys[@]} -eq 0 ]; then
    echo "    No .pub keys found in ~/.ssh"
  else
    for i in "${!pub_keys[@]}"; do
      echo "      $((i+1))) ${pub_keys[$i]}"
    done
    read -p "    Which key? [1-${#pub_keys[@]}]: " key_choice
    selected="${pub_keys[$((key_choice-1))]}"
    git config --global user.signingkey "$selected"
    echo "    Using $selected"
  fi
fi

echo "==> Done!"
