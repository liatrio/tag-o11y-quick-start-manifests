#!/bin/bash

# Function to check and install Homebrew
install_homebrew() {
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo "Homebrew is already installed."
    fi
}

# Function to install a Homebrew package if not installed
install_brew_package() {
    if ! brew list "$1" &>/dev/null; then
        echo "Installing $1..."
        brew install "$1"
    else
        echo "$1 is already installed."
    fi
}

# Function to install a Homebrew Cask application
install_brew_cask() {
    if ! brew list --cask "$1" &>/dev/null; then
        echo "Installing $1..."
        brew install --cask "$1"
    else
        echo "$1 is already installed."
    fi
}

# Install Homebrew
install_homebrew

# Install Docker Desktop
install_brew_cask docker

# Install k3d, kubectl, kustomize, and Tilt
install_brew_package k3d
install_brew_package kubectl
install_brew_package kustomize
install_brew_package tilt

echo "Installation complete! Ensure Docker Desktop is running before using k3d."