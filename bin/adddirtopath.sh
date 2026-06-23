#!/bin/zsh
# Check if the script is being sourced in zsh or bash
if [[ -n "$ZSH_VERSION" ]]; then
    # zsh specific check using ZSH_EVAL_CONTEXT
    # https://www.zsh.org/mla/users/2014/msg00812.html
    if [[ "$ZSH_EVAL_CONTEXT" == *":file"* ]]; then
        sourced=true
    else
        sourced=false
    fi
elif [[ -n "$BASH_VERSION" ]]; then
    # bash specific check
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        sourced=true
    else
        sourced=false
    fi
else
    # Fallback (assume not sourced)
    sourced=false
fi

# Get the directory from which the script is run
current_dir=$(pwd)

# Check if the directory is already in the PATH
if [[ ":$PATH:" == *":$current_dir:"* ]]; then
    echo "The directory $current_dir is already in your PATH."
else
    # Add the directory to the PATH temporarily
    export PATH="$PATH:$current_dir"
    echo "The directory $current_dir has been added to your PATH temporarily."
fi