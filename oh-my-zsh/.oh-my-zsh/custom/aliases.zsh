alias sb='source ~/.bashrc'

alias python="python3"

alias c="clear"
alias r=". ranger"

# colorise ls command
alias ls='ls --color=auto'

# colorise tree command
alias tree='tree -C'

# some ls aliases
alias ll='ls -alhF'
alias la='ls -A'
alias l='ls -CF'

# colorise grep commands
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# parent directories aliases
alias ..='cdls ..'
alias ...='cdls ../..'
alias ....='cdls ../../..'
alias .....='cdls ../../../..'

alias bat=batcat

# bash edit
alias bashrc_edit="vi ~/.bashrc"
alias aliases_edit="vi ~/.bash_aliases"

alias focal="lxc exec focal -- sudo --user ubuntu --login"

# alias sros="source /opt/ros/jazzy/setup.zsh"
alias sws="source install/local_setup.zsh"
alias rosrc_edit="vi ~/.rosrc"

alias cb="colcon build"
alias cbs="colcon build --symlink-install"
alias cbp="colcon build --packages-select"
alias cbps="colcon build --symlink-install --packages-select"

alias mendeley="~/mendeley.AppImage  --disable-gpu-sandbox"

alias prusa="~/PrusaSlicer-2.5.1.AppImage"

# git
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"

# dirs
alias rosclean="rm -rf build/ install/ log/"

#emscripten
alias semsdk="source /home/batsy/emsdk/emsdk_env.sh"

alias cal="khal --color interactive"



########## Functions ##################
ssh_color() {
    # Save the current terminal background color
    ORIGINAL_BG=$(xtermcontrol --get-bg)
    
    # Set the new background color for SSH session
    xtermcontrol --bg 'rgb:1010/1313/1b1b'

    # Ensure background color is restored on exit or interruption
    trap 'xtermcontrol --bg "$ORIGINAL_BG"' EXIT INT TERM

    # Run SSH
    ssh "$@"

    # Restore the original background color (redundant but safe)
    xtermcontrol --bg "$ORIGINAL_BG"

    # Remove the trap after SSH exits to avoid unnecessary executions
    trap - EXIT INT TERM
}

alias ssh="ssh_color"

#ros
sros(){
  source /opt/ros/jazzy/setup.zsh
  # argcomplete for ros2 & colcon
  eval "$(register-python-argcomplete ros2)"
  eval "$(register-python-argcomplete colcon)"
  eval "$(register-python-argcomplete ros2-pkg-create)"
}

#virtualenvwrapper
venv(){
  source ~/.local/bin/virtualenvwrapper.sh
  export WORKON_HOME=~/pyenvs
}

#workspace
gowsbuild() {
    local current_dir=$(pwd)
    while [[ "$current_dir" != '/' && ! -d "$current_dir/build" ]]; do
        current_dir=$(dirname "$current_dir")
    done
    if [[ -d "$current_dir/build" ]]; then
        cd "$current_dir/build" || return
    else
        echo "Build directory not found in the workspace."
    fi
}

gowssrc() {
    local current_dir=$(pwd)
    while [[ "$current_dir" != '/' && ! -d "$current_dir/src" ]]; do
        current_dir=$(dirname "$current_dir")
    done
    if [[ -d "$current_dir/src" ]]; then
        cd "$current_dir/src" || return
    else
        echo "Src directory not found in the workspace."
    fi
}

#cmake
build_package() {
    # Define options
    local OPTS=$(getopt -o cp:i --long clean,package:,install -n 'build_package' -- "$@")
    if [ $? != 0 ]; then echo "Failed parsing options." >&2; exit 1; fi

    eval set -- "$OPTS"

    local clean_build_flag=0
    local install_flag=0
    local package_name=""
    local additional_args=()

    # Extract options and their arguments
    while true; do
        case "$1" in
            -c | --clean )
                clean_build_flag=1; shift ;;
            -p | --package )
                package_name="$2"; shift; shift ;;
            -i | --install )
                install_flag=1; shift ;;
            -- )
                shift; break ;;
            * )
                break ;;
        esac
    done
    
    # The rest of the arguments are considered additional arguments for cmake
    additional_args=("$@")

    if [[ -z "$package_name" ]]; then
        echo "Please provide a package name."
        return 1
    fi

    # Start searching for the workspace root from the current directory
    local current_dir=$(pwd)
    local return_dir=$(pwd)
    local workspace_base=""

    while [[ "$current_dir" != '/' ]]; do
        if [[ -d "$current_dir/src" && -d "$current_dir/build" ]]; then
            workspace_base="$current_dir"
            break
        fi
        current_dir=$(dirname "$current_dir")
    done

    if [[ -z "$workspace_base" ]]; then
        echo "Workspace root with 'src' and 'build' directories not found."
        return 1
    fi

    local src_dir=""
    # Dynamically find the package's source directory
    # Look directly under src and then one level deeper
    if [[ -d "${workspace_base}/src/${package_name}" ]]; then
        src_dir="${workspace_base}/src/${package_name}"
    else
        # Search one level deeper
        local found=$(find "${workspace_base}/src" -maxdepth 2 -type d -name "${package_name}" -print -quit)
        if [[ -n "$found" ]]; then
            src_dir=$found
        fi
    fi

    local build_dir="${workspace_base}/build/${package_name}"
    local install_dir="${workspace_base}/install/${package_name}"

    # Check if the source directory exists
    if [[ ! -d "$src_dir" ]]; then
        echo "Source directory for package '${package_name}' does not exist."
        return 1
    fi

    # Clean build directory if flag is set
    if [[ "$clean_build_flag" == 1 ]]; then
        echo "Cleaning build directory for package '${package_name}'."
        rm -rf "$build_dir"/
    fi

    # Create the build directory if it doesn't exist
    if [[ ! -d "$build_dir" ]]; then
        echo "Creating build directory for package '${package_name}'."
        mkdir -p "$build_dir"
    fi

    # Navigate to the build directory
    cd "$build_dir" || return

    # Run CMake with the specified configurations
    echo "Running cmake for package '${package_name}'..."
    cmake -DCMAKE_INSTALL_PREFIX="${install_dir}" "${additional_args[@]}" "$src_dir"

    # Install if flag
    if [[ "$install_flag" == 1 ]]; then
        echo "Installing package '${package_name}'."
        make install -j $(nproc)
    fi

    # Navigate back to the original directory
    cd "$return_dir" || return
}

# build all packages in workspace upto depth 2
build_all() {
    # Define options
    local OPTS=$(getopt -o ci --long clean,install -n 'build_all' -- "$@")
    if [ $? != 0 ]; then
        echo "Failed parsing options."
        echo "Usage: build_all [-c|--clean] [-i|--install]"
        return 1
    fi

    eval set -- "$OPTS"

    local clean_build_flag=0
    local install_flag=0

    # Extract options and their arguments
    while true; do
        case "$1" in
            -c | --clean )
                clean_build_flag=1; shift ;;
            -i | --install )
                install_flag=1; shift ;;
            -- )
                shift; break ;;
            *)
                # Catch all unknown options
                echo "Invalid option: $1"
                echo "Usage: build_all [-c|--clean] [-i|--install]"
                return 1
                ;;
        esac
    done

    # Start searching for the workspace root from the current directory
    local current_dir=$(pwd)
    local workspace_base=""

    while [[ "$current_dir" != '/' ]]; do
        if [[ -d "$current_dir/src" && -d "$current_dir/build" ]]; then
            workspace_base="$current_dir"
            break
        fi
        current_dir=$(dirname "$current_dir")
    done

    if [[ -z "$workspace_base" ]]; then
        echo "Workspace root with 'src' and 'build' directories not found."
        return 1
    fi

    # Find directories within src up to 2 levels deep that contain a CMakeLists.txt file
    local cmake_dirs=$(find "$workspace_base/src" -maxdepth 3 -type f -name CMakeLists.txt -printf '%h\n' | sort -u)
   
    local src_dirs=""
    for dir in $cmake_dirs; do
        if [[ ! -f "$dir/CMAKE_IGNORE" ]]; then
            src_dirs+="$dir "
        fi
    done

    for src_dir in $src_dirs; do
	printf "\n$src_dir"
        local package_name=$(basename "$src_dir")

        printf "Building package: $package_name"
        
        local cmd_flags=""
        [[ $clean_build_flag -eq 1 ]] && cmd_flags+=" -c"
        [[ $install_flag -eq 1 ]] && cmd_flags+=" -i"

        # Call build_package with appropriate flags
        if ! build_package -p "$package_name" $cmd_flags; then
            echo "Error building package: $package_name"
            return 1
        fi
    done

    echo "All packages built successfully."
}



# git
check_git_remotes() {
  for d in */ ; do
    echo -e "\033[1;34mChecking '$d'...\033[0m" # Blue color for directory being checked
    if [ -d "$d/.git" ]; then
      echo -en "\033[1;32mRemote origin URL for '\033[1;33m$d\033[1;32m': \033[0m" # Green for text, Yellow for directory name
      (cd "$d" && git config --get remote.origin.url)
    else
      echo -e "\033[1;31mNot a Git repository.\033[0m" # Red color for non-Git repositories
    fi
    echo "" # Adds a newline for better separation
  done
}


