# Dotfiles Setup with GNU Stow and Git

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Setting Up Your Dotfiles Repository](#setting-up-your-dotfiles-repository)
4. [Organizing Your Dotfiles with GNU Stow](#organizing-your-dotfiles-with-gnu-stow)
   - [a. Directory Structure](#a-directory-structure)
   - [b. Create Package Directories](#b-create-package-directories)
   - [c. Move Existing Dotfiles into the Repository](#c-move-existing-dotfiles-into-the-repository)
   - [d. Initialize Git Repository](#d-initialize-git-repository)
5. [Using GNU Stow to Manage Symlinks](#using-gnu-stow-to-manage-symlinks)
   - [a. Symlinking the Dotfiles](#a-symlinking-the-dotfiles)
   - [b. Verify Symlinks](#b-verify-symlinks)
6. [Version Control](#version-control)
7. [Cloning and Setting Up on a New Machine](#cloning-and-setting-up-on-a-new-machine)

---

## Introduction

- **Dotfiles**: Configuration files for your applications (e.g., `.bashrc`, `.vimrc`). Managing them in a repository allows for easy backups and synchronization across systems.
  
- **GNU Stow**: A symlink manager that simplifies managing multiple dotfiles by organizing them into separate directories and creating symlinks in your home directory.

---

## Prerequisites

Ensure that you have the following tools installed on your Linux machine:

- **Git**: Version control system.
- **GNU Stow**: Symlink manager.

### Installing Git and Stow

Open your terminal and execute the following commands based on your Linux distribution.

**For Debian/Ubuntu-based systems:**

```bash
sudo apt update
sudo apt install git stow
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
