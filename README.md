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
ln -s alacritty.yml ~/.config/alacritty/alacritty.yml
```
