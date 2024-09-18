# Dotfiles

## Introduction

- **Dotfiles**: Configuration files for your applications (e.g., `.bashrc`, `.vimrc`). Managing them in a repository allows for easy backups and synchronization across systems.
  
- **GNU Stow**: A symlink manager that simplifies managing multiple dotfiles by organizing them into separate directories and creating symlinks in your home directory.

## Prerequisites

Ensure that you have the following tools installed on your Linux machine:

- **GNU Stow**: Symlink manager.

### Installing Git and Stow

Open your terminal and execute the following commands based on your Linux distribution.

**For Debian/Ubuntu-based systems:**

```bash
sudo apt update
sudo apt install stow
```

## Setting Up Your Dotfiles Repository

1. **Create a New Repository**: Create a new repository on GitHub or GitLab to store your dotfiles.

2. **Clone the Repository**: Clone the repository to your local machine using the following command:

   ```bash
   cd ~
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```

   - Replace `yourusername` with your GitHub username.

## Organizing Your Dotfiles with GNU Stow

### a. Directory Structure

Create a directory structure for your dotfiles repository as follows:

```
dotfiles/
├── bash/
├── vim/
├── zsh/
└── ...
```

### b. Create Package Directories

Create directories for each package (e.g., `bash`, `vim`) inside your dotfiles repository:

```bash
mkdir bash vim
```

### c. Move Existing Dotfiles into the Repository

Move your existing dotfiles into the corresponding package directories. For example, move `.bashrc` to the `bash` directory:

```bash
mv ~/.bashrc ~/dotfiles/bash/
```

### d. Initialize Git Repository

Initialize a Git repository in your dotfiles directory and commit the changes:

```bash
git init
git add .
git commit -m "Initial commit"
```

## Using GNU Stow to Manage Symlinks

### a. Symlinking the Dotfiles

To symlink the dotfiles from the `bash` package, navigate to the `dotfiles` directory and run the following command:

```bash
cd ~/dotfiles
stow bash
```

This will create symlinks for the files in the `bash` directory in your home directory.

### b. Verify Symlinks

To verify that the symlinks have been created successfully, use the following command:

```bash
ls -la ~
```

You should see the symlinks pointing to the files in the `bash` directory.

## Version Control

### a. Making Changes

Whenever you want to make changes to your dotfiles, edit the files in the corresponding package directories (e.g., `bash`, `vim`).

### b. Committing Changes

After making changes, commit the changes to your Git repository:

```bash
git add .
git commit -m "Updated .bashrc"
```

### c. Pushing Changes

Push the changes to your remote repository:

```bash
git push
```

## Cloning and Setting Up on a New Machine

To clone and set up your dotfiles on a new machine, follow these steps:

1. **Clone the Repository**: Clone your dotfiles repository to the new machine:

   ```bash
   cd ~
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```

2. **Symlink the Dotfiles**: Use GNU Stow to symlink the dotfiles on the new machine:

   ```bash
   stow bash
   ```


## Zsh, Oh My Zsh, and Powerlevel10k

### Installing Zsh

1. **Install Zsh**: Install Zsh using the package manager of your Linux distribution.

   **For Debian/Ubuntu-based systems:**

   ```bash
   sudo apt update
   sudo apt install zsh
   ```

2. **Set Zsh as the Default Shell**: Change your default shell to Zsh by running the following command:

   ```bash
   chsh -s $(which zsh)
   ```

3. **Log Out and Log Back In**: Log out of your session and log back in to apply the changes.

### Installing Oh My Zsh

1. **Install Oh My Zsh**: Install Oh My Zsh by running the following command:

   ```bash
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

2. **Customize Oh My Zsh**: Edit the `~/.zshrc` file to customize your Oh My Zsh configuration.

### Installing Powerlevel10k Theme

1. **Install Powerlevel10k**: Install the Powerlevel10k theme.

   ```bash
   git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
   ```

2. **Set ZSH_THEME**: Set the `ZSH_THEME` variable in your `~/.zshrc` file to `powerlevel10k/powerlevel10k`.

3. Configure Powerlevel10k

   Run `p10k configure` to customize your Powerlevel10k theme.

   