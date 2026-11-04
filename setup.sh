#!/bin/bash
set -e

DOTFILES_LOCAL="$(cd "$(dirname "$0")" && pwd)"

case "${1:-}" in
  ""|--links-only) ;;
  *) echo "Usage: $0 [--links-only]" >&2; exit 1 ;;
esac

# Apply local config before any package install can fail.
link_config() {
  local source="$1" destination="$2" backup
  mkdir -p "$(dirname "$destination")"
  if [ -e "$destination" ] && [ ! -L "$destination" ]; then
    backup="$(mktemp -d "${destination}.backup-XXXXXXXX")"
    mv "$destination" "$backup/$(basename "$destination")"
    echo "    Backed up $destination to $backup"
  fi
  ln -sfn "$source" "$destination"
}

echo "==> Linking local configs"
if [ ! -f "$DOTFILES_LOCAL/zshenv.local" ]; then
  cp "$DOTFILES_LOCAL/zshenv.local.example" "$DOTFILES_LOCAL/zshenv.local"
fi
link_config "$DOTFILES_LOCAL/zshenv.local" "$HOME/.zshenv.local"
link_config "$DOTFILES_LOCAL/init.lua" "$HOME/.hammerspoon/init.lua"
link_config "$DOTFILES_LOCAL/ghostty-config" "$HOME/.config/ghostty/config"
link_config "$DOTFILES_LOCAL/hyprspace-config" "$HOME/.config/hyprspace/config.toml"
link_config "$DOTFILES_LOCAL/herdr-config" "$HOME/.config/herdr/config.toml"
link_config "$DOTFILES_LOCAL/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"

reload_configs() {
  if command -v hyprspace >/dev/null 2>&1; then
    hyprspace reload-config || echo "    Hyprspace reload failed; config is linked."
  fi
  if command -v herdr >/dev/null 2>&1; then
    herdr server reload-config || echo "    Herdr reload failed; config is linked."
  fi
}
reload_configs

if [ "${1:-}" = --links-only ]; then
  echo "==> Config links updated!"
  exit 0
fi

echo "==> Installing brew packages"
brew install zoxide tmux neovim mise ghostty herdr gh claude-code codex rcm tailscale

# Keep an existing OpenCode installation regardless of its source tap.
if brew list --formula opencode >/dev/null 2>&1; then
  echo "    OpenCode is already installed, skipping"
else
  brew install opencode
fi

echo "==> Installing mac specific brew packages"
brew install --cask flycut hammerspoon slack signal
if [ -d /Applications/Dash.app ] && ! brew list --cask dash >/dev/null 2>&1; then
  echo "    Dash is already installed outside Homebrew, skipping"
else
  brew install --cask dash
fi

echo "==> Installing Hyprspace"
brew install --cask peachlifeab/tap/hyprspace
reload_configs

echo "==> Setting up GPG (optional)"
brew install gpg 2>/dev/null || true
mkdir -p ~/.gpg-keys ~/.gnupg
chmod 700 ~/.gpg-keys ~/.gnupg
if [ -f ~/Downloads/trevor-gpg-private.asc ] || [ -f ~/Downloads/trevor-gpg-public.asc ]; then
  mv -f ~/Downloads/trevor-gpg-private.asc ~/Downloads/trevor-gpg-public.asc ~/.gpg-keys/ 2>/dev/null || true
fi
if [ -f ~/.gpg-keys/trevor-gpg-public.asc ]; then
  gpg --import ~/.gpg-keys/trevor-gpg-public.asc
  if [ -f ~/.gpg-keys/trevor-gpg-private.asc ]; then
    gpg --import ~/.gpg-keys/trevor-gpg-private.asc
  fi
else
  echo "    Skipping GPG key import. To set up GPG manually:"
  echo "      1. Download trevor-gpg-private.asc and trevor-gpg-public.asc from 1Password to ~/Downloads"
  echo "      2. Run this script again"
fi

echo "==> Setting up Hammerspoon"

if pgrep -x Hammerspoon > /dev/null; then
  if ! hs -c "hs.reload()"; then
    echo "    Could not reload Hammerspoon through IPC."
    echo "    Choose Reload Config from the Hammerspoon menu to load the linked config and enable IPC."
  fi
else
  echo "    Start Hammerspoon to load the linked config."
fi

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
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
existing_key=$(git config --get user.signingkey 2>/dev/null || true)
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

signing_key=$(git config --get user.signingkey 2>/dev/null || true)
git_email=$(git config --global user.email 2>/dev/null || true)
signing_key_path="${signing_key/#\~/$HOME}"
if [ -n "$signing_key_path" ] && [ -n "$git_email" ] && [ -f "$signing_key_path" ]; then
  mkdir -p ~/.ssh
  pubkey_contents=$(cat "$signing_key_path")
  signer_line="$git_email $pubkey_contents"
  touch ~/.ssh/allowed_signers
  if grep -Fqx "$signer_line" ~/.ssh/allowed_signers; then
    echo "    allowed_signers already contains $git_email"
  else
    printf '%s\n' "$signer_line" >> ~/.ssh/allowed_signers
    echo "    Added $git_email to ~/.ssh/allowed_signers"
  fi
else
  echo "    Skipping allowed_signers update; missing git email or signing key file"
fi


echo "==> Done!"
