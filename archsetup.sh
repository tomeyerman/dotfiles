#!/bin/bash

sudo pacman -S wget \
    curl \
    sof-firmware \
    firefox \
    github-cli \
    stow \
    neovim \
    power-profiles-daemon \
    xorg-xhost \
    rofi \
    ghostty \
    gnome-keyring \
    starship \
    intel-media-driver \
    libva-utils \
    ttf-firacode-nerdfont \
    ttf-jetbrains-mono-nerd \
    ttf-hack-nerd \
    luajit \
    lua51 \
    dotnet-sdk \
    dotnet-runtime \
    unzip \
    7z \
    ripgrep \
    luarocks \
    python \
    python-pip \
    fastfetch \
    mesa-utils \
    libnotify

stow ghostty
stow alacritty
stow bashrc
stow inputrc
stow zshrc
stow nvim
stow starship
stow oh-my-posh

# oh-my-posh is not in the official Arch repos. To use it on Linux:
#   curl -s https://ohmyposh.dev/install.sh | bash -s
# or install oh-my-posh-bin from AUR (e.g. yay -S oh-my-posh-bin).
# The stow above only deploys the config; the binary install is separate.

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh