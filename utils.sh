# Install all packages
install_packages() {
  display_type=$(loginctl show-session "$(loginctl | grep "$(whoami)" | awk '{print $1}')" -p Type --value)

  sudo apt update -y

  # Install packages with error handling
  echo "Installing terminal apt pkgs..."
  for package in "${packages[@]}"; do
    sudo apt install -y $package || {
      echo "Failed to install $package, skipping..."
    }
  done

  echo "Installed pkgs: ${packages[*]}"

  echo "Installing terminal non apt packages..."
  ./applications/headless/non_apt_packages.sh

  echo "Installing cargo packages..."
  cargo install eza
  sudo apt install bat -y

  if [[ "$display_type" == "x11" || "$display_type" == "wayland" ]]; then
    source ./applications/desktop/apt_pkgs.sh
    source ./applications/desktop/non_apt_pkgs.sh.sh
    source ./applications/desktop/ppa.sh

    ./applications/desktop/ppa.sh # Gets ppa's

    echo "Installing GUI apt pkgs..."
    for gui_package in "${gui_packages[@]}"; do
      sudo apt install -y $gui_package || {
        echo "Failed to install $gui_package, skipping..."
      }
    done

    echo "Installing GUI non apt packages..."
    ./applications/desktop/non_apt_pkgs.sh
  else
    echo "Headless installation, skipping GUI packages..."
  fi
}

asdf_configure() {
  if ! command -v asdf &>/dev/null; then
    echo "Installing asdf..."

    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.1
    echo ". $HOME/.asdf/asdf.sh" >>~/.zshrc

    source ~/.zshrc >/dev/null 2>&1
  else
    echo "asdf already installed, skipping..."
  fi

  asdf_languages=(
    "nodejs"
    "ruby"
    "python"
  )

  for language in "${asdf_languages[@]}"; do
    asdf plugin-add $language
    asdf install $language latest
    asdf global $language latest
  done
}

# Clones repositories
clone_repositories() {
  # Clones powerlevel10k
  if [ -d "$HOME/powerlevel10k" ]; then
    echo "Powerlevel10k directory already exists. Skipping git clone."
  else
    git clone --depth=2 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k" || {
      echo "Failed to clone Powerlevel10k repository"
      return 1
    }
  fi
  # Clones zsh-autosuggestions

  if [ -d "$HOME/.zsh/zsh-autosuggestions" ]; then
    echo "Zsh-autosuggestions directory already exists. Skipping git clone."
  else
    git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions" || {
      echo "Failed to clone Zsh-autosuggestions repository"
      return 1
    }
  fi

  # LazyVim installation
  echo "Installing lazyvim"
  rm -rf "$HOME/.config/nvim" # Remove existing nvim directory before cloning
  git clone https://github.com/LazyVim/starter ~/.config/nvim || {
    echo "Failed to clone LazyVim repository"
    return 1
  }
  rm -rf ~/.config/nvim/.git

  # lazygit installation
  if ! command -v curl &>/dev/null; then
    echo "CURL NOT INSTALLED, LAZYGIT INSTALLATION CANCELLED."
    return 1
  else
    echo "Installing lazygit"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo ~/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf ~/lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin

    # Cleans the trash
    rm -rf ~/lazygit.tar.gz
    rm -rf ~/lazygit
  fi

  if ! command -v lazygit &>/dev/null; then
    echo "lazygit was not installed, skipping."
  fi

  echo "Repositories cloned."
}

check_configure_git() {
  # Check if Git is installed
  if ! command -v git &>/dev/null; then
    echo "Git is not installed. Please install Git to continue."
    return 1
  fi

  # Check if git config user.name is set
  if [ -z "$(git config --get user.name)" ]; then
    read -p "Git username not configured. Please enter your Git username: " username
    git config --global user.name "$username"
  fi

  # Check if git config user.email is set
  if [ -z "$(git config --get user.email)" ]; then
    read -p "Git email not configured. Please enter your Git email: " email
    git config --global user.email "$email"
  fi

  echo "Git configuration completed."
}

# Install NerdFonts
install_nerdfonts() {
  echo "Installing NerdFonts..."

  # Create ~/.local/share/fonts if it doesn't exist
  if [ ! -d ~/.local/share/fonts ]; then
    mkdir -p ~/.local/share/fonts
  fi

  # Installs JetBrainsMono to ~/.local/share/fonts
  wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip &&
    cd ~/.local/share/fonts &&
    unzip JetBrainsMono.zip &&
    rm JetBrainsMono.zip &&
    fc-cache -fv

  echo "NerdFonts installed."
}

# Configures main shell and main theme
zsh_configurations() {
  echo "Configuring Zsh..."

  # Adding path
  echo 'export PATH="$HOME/.cargo/bin:$PATH"' >>~/.zshrc

  # Powerlevel10k and Zsh-autosuggestions
  echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
  echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >>~/.zshrc

  # Adding aliases
  echo "Adding aliases..."
  echo "alias updateUpgrade='sudo apt update && sudo apt upgrade -y'" >>~/.zshrc

  # ls to eza
  if ! type "eza" >/dev/null 2>&1; then
    echo "Alias 'eza' not available, skipping..."
  else
    echo "alias ls='eza'" >>~/.zshrc
  fi

  # cat to batcat
  if type "bat" >/dev/null 2>&1; then
    echo "Using 'bat' as replacement for 'cat'..."
    echo "alias cat='bat'" >>~/.zshrc
  elif type "batcat" >/dev/null 2>&1; then
    echo "Using 'batcat' as replacement for 'cat'..."
    echo "alias cat='batcat'" >>~/.zshrc
  else
    echo "Neither 'bat' nor 'batcat' found, skipping..."
  fi

  # ------ TERMINAL KEYBINDINGS ------ #
  # Creates zsh config directory
  if [[ ! -d /usr/share/zsh ]]; then
    sudo mkdir /usr/share/zsh
  fi

  # Moves the keybindings dotfile
  if [[ -f ~/linuxtools/dotfiles/zsh-keybindings ]]; then
    sudo mv ~/linuxtools/dotfiles/zsh-keybindings /usr/share/zsh/
  else
    echo "Source file not found."
  fi

  # Sourcing keybindings
  cat <<'EOF' >>~/.zshrc
if [[ -e /usr/share/zsh/zsh-keybindings ]]; then
    source /usr/share/zsh/zsh-keybindings
fi
EOF

  echo "Zsh configurations complete."
}

# Configures Tmux
tmux_configurations() {
  echo "Configuring Tmux..."

  # Installing theme
  mkdir -p ~/.config/tmux/plugins/catppuccin
  git clone -b v2.1.2 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux

  if [ -f ~/.tmux.conf ]; then
    echo "tmux.conf already exists. copying files"
    cat ~/linuxtools/dotfiles/.tmux.conf >>~/.tmux.conf
  else
    echo "Creating .tmux.conf"
    mv ~/linuxtools/dotfiles/.tmux.conf ~
  fi
}

terminator_config() {
  echo "Configuring Terminator..."

  TERMINATOR_DIR=$HOME/.config/terminator

  if [ ! -d "$TERMINATOR_DIR" ]; then
    mkdir "$TERMINATOR_DIR"
  fi

  touch "$TERMINATOR_DIR/config"

  if [ ! -f "$TERMINATOR_DIR/config" ]; then
    echo "ERORR: terminator config file not present."
  else
    cat ~/linuxtools/dotfiles/terminator/config >"$TERMINATOR_DIR/config"
  fi
}

p10k_configuration() {
  echo "Configuring p10k..."
  if [ -f ~/.p10k.zsh ]; then
    echo "p10.zsh already exists. copying files"
    cat ~/linuxtools/dotfiles/.p10k.zsh >>~/.p10k.zsh
  else
    echo "Creating .p10k.zsh"
    mv ~/linuxtools/dotfiles/.p10k.zsh ~
  fi

  # Sources p10k.zsh
  echo -e "\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh " >>~/.zshrc
}
