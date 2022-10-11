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
  IdentityFile ~/.ssh/id_ed25519
EOF

# test your connection
ssh -T git@github.com
```

# Installation

1. clone down dotfiles dirs (Thoughtbots and this one)

```bash
git clone https://github.com/thoughtbot/dotfiles.git ~/dotfiles
git clone git@github.com:trevorrjohn/dotfiles-local.git ~/dotfiles-local
cd ~/dotfiles-local
git submodule update --init
```

2. Follow the instructions [here](https://github.com/thoughtbot/dotfiles#install)

3. If using alacritty

```bash
cd ~/dotfiles-local
mkdir -p ~/.config/alacritty
ln -fs $(pwd)/alacritty.yml ~/.config/alacritty/alacritty.yml
```

4. GPG Conf

Copy over gpg agent config so that gpg doesn't get logged out every 5 seconds

```bash
# install gpg
brew install gpg

# import key from backup (1Password)
gpg --import gpg-8D9E4AB933454261.key

# setup config so that password is remembered for a bit
ln -fs $(pwd)/gpg-agent.conf ~/.gnupg/gpg-agent.conf
```

5. Install Tmux

```bash
brew install tmux
```

5. Hammerspoon

Download [Hammerspoon](https://www.hammerspoon.org)

```bash
brew install --cask hammerspoon
```

Download [Hammerspoon-Shiftit](https://github.com/peterklijn/hammerspoon-shiftit)

Symlink `init.lua`

```bash
mkdir -p  ~/.hammerspoon/
ln -fs $(pwd)/init.lua ~/.hammerspoon/init.lua
```

6. Git config

```sh
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```


