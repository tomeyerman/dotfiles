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
stow nvim
stow starship

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh