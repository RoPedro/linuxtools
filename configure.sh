#!/bin/bash

source ./applications/apt_packages.sh
source ./utils.sh

main() {
  install_packages
  check_configure_git
  asdf_configure
  clone_repositories
  install_nerdfonts
  zsh_configurations
  tmux_configurations
  p10k_configuration

  source ~/.zshrc

  echo "Configuration complete. Run "source ~/.zshrc" and "source ~/.tmux.conf" to apply changes."
}

main
