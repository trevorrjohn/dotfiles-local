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

# Android on macOS

`zshrc.local` is set up to use `~/Library/Android/sdk` as `ANDROID_SDK_ROOT` on macOS. When the SDK directories exist, it also adds these to `PATH` automatically:

- `platform-tools`
- `emulator`
- `cmdline-tools/latest/bin`

## Install the SDK tools

If you do not already have `sdkmanager`, install the Android command line tools with Homebrew:

```bash
brew install android-commandlinetools
```

Create the SDK root and install the packages needed for `adb`, builds, and the emulator:

```bash
mkdir -p "$HOME/Library/Android/sdk"

sdkmanager --sdk_root="$HOME/Library/Android/sdk" \
  "platform-tools" \
  "platforms;android-35" \
  "build-tools;35.0.0" \
  "emulator" \
  "system-images;android-35;google_apis;arm64-v8a" \
  "cmdline-tools;latest"
```

Open a new shell after install, or reload your shell config:

```bash
source ~/.zshrc
```

Verify the tools are available:

```bash
which adb
which emulator
which avdmanager
adb version
```

## Create and run an emulator

Use the `avdmanager` installed inside the SDK root:

```bash
"$HOME/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager" create avd \
  -n pixel-9 \
  -k "system-images;android-35;google_apis;arm64-v8a" \
  -d pixel_9
```

List available devices:

```bash
avdmanager list device | rg pixel
```

Start the emulator:

```bash
emulator -avd pixel-9
```

List available emulators:

```bash
emulator -list-avds
```
