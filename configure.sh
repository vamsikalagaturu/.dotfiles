#!/bin/bash

# ================================
# Enhanced Shell Configuration Script
# ================================

# ================================
# Color Definitions
# ================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ================================
# Helper Functions
# ================================

# Function to display messages in different colors
echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to prompt user for input with colored prompt
prompt_user() {
    read -rp "$(echo -e "${YELLOW}$1${NC}")" response
    echo "$response"
}

# Function to install a package with confirmation
install_package() {
    local package="$1"
    if dpkg -l | grep -qw "$package"; then
        echo_success "$package is already installed."
    else
        local confirm
        confirm=$(prompt_user "Do you want to install $package? (y/n): ")
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo_info "Installing $package..."
            sudo apt update
            sudo apt install -y "$package"
            if [[ $? -eq 0 ]]; then
                echo_success "$package has been installed successfully."
            else
                echo_error "Failed to install $package."
                exit 1
            fi
        else
            echo_warning "Skipping installation of $package."
        fi
    fi
}

# Function to create backups, handling symlinks
create_backup() {
    local file="$1"
    local backup_dir="$HOME/.config_backups"

    mkdir -p "$backup_dir"

    if [ -L "$file" ]; then
        local target
        target=$(readlink "$file")
        echo_info "$file is a symlink pointing to $target."
        # Optionally, handle the symlink (e.g., remove it before backing up)
        read -rp "$(echo -e "${YELLOW}Do you want to remove the symlink and back up the target file? (y/n): ${NC}")" remove_confirm
        if [[ "$remove_confirm" =~ ^[Yy]$ ]]; then
            cp -L "$file" "$backup_dir/"
            rm "$file"
            echo_success "Symlink removed and target file backed up to $backup_dir."
        else
            echo_warning "Skipped handling symlink for $file."
            return
        fi
    elif [ -f "$file" ]; then
        cp "$file" "$backup_dir/"
        echo_success "Backup of $(basename "$file") created at $backup_dir/"
    else
        echo_warning "No existing $(basename "$file") found to backup."
    fi
}

# Function to display the changes made to rc files
print_changes() {
    local rc_file="$1"
    echo_info "Latest changes in $rc_file:"
    tail -n 5 "$rc_file"
}

# Function to manage dotfiles
manage_dotfiles() {
    local manage
    manage=$(prompt_user "Do you want to manage dotfiles? (y/n): ")
    if [[ "$manage" =~ ^[Yy]$ ]]; then
        install_package "stow"

        local dotfiles_choice
        dotfiles_choice=$(prompt_user "Do you have an existing Git repository for dotfiles? (y/n): ")
        local dest_dir

        if [[ "$dotfiles_choice" =~ ^[Yy]$ ]]; then
            local repo_url
            repo_url=$(prompt_user "Enter the Git repository URL: ")
            dest_dir=$(prompt_user "Enter the destination directory (e.g., ~/dotfiles): ")

            if [ -d "$dest_dir" ]; then
                echo_warning "Directory $dest_dir already exists."
                local use_existing
                use_existing=$(prompt_user "Do you want to use the existing directory? (y/n): ")
                if [[ ! "$use_existing" =~ ^[Yy]$ ]]; then
                    echo_error "Destination directory already exists. Exiting."
                    exit 1
                fi
            else
                git clone "$repo_url" "$dest_dir"
                if [[ $? -ne 0 ]]; then
                    echo_error "Failed to clone repository. Exiting."
                    exit 1
                fi
                echo_success "Cloned repository to $dest_dir."
            fi
        else
            # check for existing dotfiles directories ~/dotfiles or ~/.dotfiles

            dotfiles_dir=$(ls ~ | grep "^dotfiles" || true)

            if [ -n "$dotfiles_dir" ]; then
                echo_warning "Existing dotfiles directories found: $dotfiles_dir"
                # skip the management
                echo_warning "Skipping dotfiles management."
                return
            fi

            # If no existing dotfiles directory, create a new one at ~/dotfiles
            if [ -z "$dest_dir" ]; then
                dest_dir=~/dotfiles
                mkdir "$dest_dir"
                echo_success "Created new dotfiles directory at $dest_dir."
                
                # Initialize a Git repository
                local init_repo
                init_repo=$(prompt_user "Do you want to initialize a Git repository in $dest_dir? (y/n): ")
                if [[ "$init_repo" =~ ^[Yy]$ ]]; then
                    git init "$dest_dir"
                    if [[ $? -eq 0 ]]; then
                        echo_success "Initialized Git repository in $dest_dir."
                    else
                        echo_error "Failed to initialize Git repository in $dest_dir."
                        exit 1
                    fi
                else
                    echo_warning "Skipping Git repository initialization."
                fi
            fi
        fi

        # Determine the shell
        local current_shell
        current_shell=$(basename "$SHELL")
        local shell_dir rc_file

        if [[ "$current_shell" == "bash" ]]; then
            shell_dir="bash"
            rc_file=".bashrc"
        elif [[ "$current_shell" == "zsh" ]]; then
            shell_dir="zsh"
            rc_file=".zshrc"
        else
            echo_error "Unsupported shell: $current_shell"
            exit 1
        fi

        # Backup existing rc file
        create_backup ~/"$rc_file"

        # Check if rc file exists before moving
        if [ -f ~/"$rc_file" ]; then
            mv ~/"$rc_file" "$dest_dir/$shell_dir/"
            echo_success "Moved $rc_file to $dest_dir/$shell_dir/"
        elif [ -L ~/"$rc_file" ]; then
            echo_warning "$rc_file is a symlink and has been handled in backup."
        else
            echo_warning "No existing $rc_file to move."
        fi

        # Stow the shell configurations
        cd "$dest_dir" || { echo_error "Failed to navigate to $dest_dir. Exiting."; exit 1; }
        stow "$shell_dir"
        if [[ $? -eq 0 ]]; then
            echo_success "Stowed $shell_dir configurations."
        else
            echo_error "Failed to stow $shell_dir configurations."
            exit 1
        fi
    else
        echo_warning "Skipping dotfiles management."
    fi
}

# Function to manage trash
manage_trash() {
    manage_trash=$(prompt_user "Do you want to manage trash using trash-put? (y/n): ")
    if [[ "$manage_trash" =~ ^[Yy]$ ]]; then
        install_package "trash-cli"
        
        # Determine the current shell configuration file
        local shell_rc
        if [[ "$SHELL" == *"bash"* ]]; then
            shell_rc="$HOME/.bashrc"
        elif [[ "$SHELL" == *"zsh"* ]]; then
            shell_rc="$HOME/.zshrc"
        else
            echo_error "Unsupported shell. Exiting."
            return
        fi

        alias_command="alias rm='trash-put'"
        
        # Handle symlink for rc file
        if [ -L "$shell_rc" ]; then
            echo_warning "$shell_rc is a symlink."
            read -rp "$(echo -e "${YELLOW}Do you want to modify the target file of the symlink directly? (y/n): ${NC}")" modify_confirm
            if [[ "$modify_confirm" =~ ^[Yy]$ ]]; then
                shell_rc=$(readlink "$shell_rc")
                echo_info "Modifying target file: $shell_rc"
            else
                echo_warning "Skipping alias addition to $shell_rc."
                return
            fi
        fi

        # Backup before making changes
        create_backup "$shell_rc"

        # Add alias only if it doesn't already exist
        if grep -Fxq "$alias_command" "$shell_rc"; then
            echo_success "Alias for rm already exists in $shell_rc."
        else
            echo_info "Adding alias for rm in $shell_rc..."
            echo "$alias_command" >> "$shell_rc"
            echo_success "Alias added for rm in $shell_rc."
            print_changes "$shell_rc"
        fi
    else
        echo_warning "Skipping trash management."
    fi
}

# Function to configure zsh
configure_zsh() {
    # Install zsh if not installed
    if ! command -v zsh &>/dev/null; then
        install_package "zsh"
    else
        echo_success "zsh is already installed."
    fi

    # Change default shell to zsh if not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        local confirm
        confirm=$(prompt_user "Do you want to change your default shell to zsh? (y/n): ")
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            chsh -s "$(which zsh)"
            if [[ $? -eq 0 ]]; then
                echo_success "Default shell changed to zsh. Please log out and log back in to apply the changes."
            else
                echo_error "Failed to change default shell to zsh."
                exit 1
            fi
        else
            echo_warning "Default shell remains as $SHELL."
        fi
    else
        echo_success "zsh is already the default shell."
    fi

    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        local confirm
        confirm=$(prompt_user "Do you want to install Oh My Zsh? (y/n): ")
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo_info "Installing Oh My Zsh..."
            RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
            if [[ $? -eq 0 ]]; then
                echo_success "Oh My Zsh installed successfully."
            else
                echo_error "Failed to install Oh My Zsh."
                exit 1
            fi
        else
            echo_warning "Skipping Oh My Zsh installation."
        fi
    else
        echo_success "Oh My Zsh is already installed."
    fi

    local rc_path="$HOME/.zshrc"

    # Backup .zshrc before modifying
    create_backup "$rc_path"

    # Install plugins
    local plugins_to_install=()
    local plugins_to_add=()

    local autosugg
    autosugg=$(prompt_user "Do you want to install zsh-autosuggestions? (y/n): ")
    if [[ "$autosugg" =~ ^[Yy]$ ]]; then
        plugins_to_install+=("zsh-autosuggestions")
        plugins_to_add+=("zsh-autosuggestions")
    fi

    local completions
    completions=$(prompt_user "Do you want to install zsh-completions? (y/n): ")
    if [[ "$completions" =~ ^[Yy]$ ]]; then
        plugins_to_install+=("zsh-completions")
    fi

    for plugin in "${plugins_to_install[@]}"; do
        local ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
        if [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
            echo_info "Installing $plugin..."
            git clone "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM/plugins/$plugin"
            if [[ $? -eq 0 ]]; then
                echo_success "$plugin installed successfully."
            else
                echo_error "Failed to install $plugin."
            fi
        else
            echo_success "$plugin is already installed."
        fi
    done

    # Update .zshrc with plugins
     if [ ${#plugins_to_add[@]} -gt 0 ]; then
      # Read the existing plugins block using awk to handle multi-line plugins block
      existing_plugins=$(awk '/^plugins=\(/,/\)/' "$rc_path")

      # Extract the existing plugins, removing parentheses and newlines
      existing_plugins_array=($(echo "$existing_plugins" | sed -e 's/plugins=(//' -e 's/)//g' | tr '\n' ' '))

      # Combine existing plugins with new plugins, excluding duplicates
      combined_plugins=($(echo "${existing_plugins_array[@]} ${plugins_to_add[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

      # Escape slashes and parentheses for use in sed
      combined_plugins_string=$(printf "%s " "${combined_plugins[@]}")
      combined_plugins_string=$(echo "$combined_plugins_string" | sed 's/[\/&]/\\&/g')

      # Escape special characters in combined_plugins_string
      escaped_plugins_string=$(echo "$combined_plugins_string" | sed 's/[\/&()]/\\&/g')

      # Update the plugins block in place
      sed -i "/^plugins=(/,/)/c\\plugins=(${combined_plugins_string})" "$rc_path"

      # Print the new plugins block
      echo "New plugins block: plugins=(${combined_plugins_string})"

      # Ensure fpath for zsh-completions is added after the plugins line, if not already present
      if ! grep -q "fpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" "$rc_path"; then
          # Add it before the line: source $ZSH/oh-my-zsh.sh
          sed -i "/^source \$ZSH\/oh-my-zsh.sh/i fpath+=\${ZSH_CUSTOM:-\${ZSH:-~\/.oh-my-zsh}\/custom}\/plugins\/zsh-completions\/src" "$rc_path"
      fi

      echo_success "Updated plugins in $rc_path."
     fi


    # Install Powerlevel10k theme
    local theme_choice
    theme_choice=$(prompt_user "Do you want to install the Powerlevel10k theme? (y/n): ")
    if [[ "$theme_choice" =~ ^[Yy]$ ]]; then
        local ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
        if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
            echo_info "Installing Powerlevel10k..."
            git clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
            if [[ $? -eq 0 ]]; then
                echo_success "Powerlevel10k installed successfully."
            else
                echo_error "Failed to install Powerlevel10k."
            fi
        else
            echo_success "Powerlevel10k is already installed."
        fi

        # Set ZSH_THEME in .zshrc
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$rc_path"
        echo_success "Set Powerlevel10k as the ZSH theme in $rc_path."
        print_changes "$rc_path"
    else
        echo_warning "Skipping Powerlevel10k installation."
    fi

    echo_success "zsh configuration complete. Please restart your terminal or run 'zsh' to apply changes."
}

# ================================
# Main Script Execution
# ================================

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN} Welcome to the Enhanced Shell Configuration Script!${NC}"
echo -e "${GREEN}=========================================${NC}"

# Determine current shell
current_shell=$(basename "$SHELL")
echo_info "Current shell: $current_shell"

if [[ "$current_shell" == "bash" ]]; then
    local customize
    customize=$(prompt_user "Do you want to customize bash or switch to zsh? (bash/zsh): ")
    case "$customize" in
        bash)
            echo_success "You chose to customize bash."
            manage_dotfiles
            manage_trash
            ;;
        zsh)
            echo_success "You chose to switch to zsh."
            configure_zsh
            manage_dotfiles
            manage_trash
            ;;
        *)
            echo_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
elif [[ "$current_shell" == "zsh" ]]; then
    echo_success "You are using zsh."
    configure_zsh
    manage_dotfiles
    manage_trash
else
    echo_error "Unsupported shell: $current_shell. Exiting."
    exit 1
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN} Configuration complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo_info "If you changed your default shell to zsh, please log out and log back in to apply the changes."
