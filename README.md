# Pre-Installation

Copy private/public key to .ssh dir

```
mv ssh-key.pub ssh-key ~/.ssh

# start the ssh-agent
eval "$(ssh-agent -s)"

# tell ssh to use ssh key
cat > ~/.ssh/config <<-EOF
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519_202501
EOF

# test your connection
ssh -T git@github.com
```

# Installation

1. Clone down dotfiles dirs (Thoughtbot's and this one)

```bash
git clone https://github.com/thoughtbot/dotfiles.git ~/dotfiles
git clone git@github.com:trevorrjohn/dotfiles-local.git ~/dotfiles-local
```

2. Follow the instructions [here](https://github.com/thoughtbot/dotfiles#install)

3. Optionally, download `trevor-gpg-private.asc` and `trevor-gpg-public.asc` from 1Password to `~/Downloads` before running the script

4. Run the setup script

```bash
cd ~/dotfiles-local
./setup.sh
```

This will install and configure:
- [Alacritty](https://alacritty.org) and [Ghostty](https://ghostty.org) terminal configs
- [mise](https://mise.jdx.dev) for runtime/tool version management
- [zoxide](https://github.com/ajeetdsouza/zoxide) for smarter cd
- GPG with agent config (optional, imports key from 1Password if downloaded)
- [tmux](https://github.com/tmux/tmux)
- [Hammerspoon](https://www.hammerspoon.org) with [ShiftIt](https://github.com/peterklijn/hammerspoon-shiftit) spoon
- [Neovim](https://neovim.io) with [config](https://github.com/trevorrjohn/nvim-config)
- [Atkinson Hyperlegible Next](https://fonts.google.com/specimen/Atkinson+Hyperlegible+Next) font
- Git user config (prompted during setup) with SSH commit signing
