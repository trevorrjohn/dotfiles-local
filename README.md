# Installation

1. clone down dotfiles dirs (Thoughtbots and this one)

```bash
git clone git://github.com/thoughtbot/dotfiles.git ~/dotfiles
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

# import key from backup (Keybase?)
gpg --import gpg-8D9E4AB933454261.key

# setup config so that password is remembered for a bit
ln -fs $(pwd)/gpg-agent.conf ~/.gnupg/gpg-agent.conf
```
