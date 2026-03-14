# -----------------------------------------------------
# Bash Configuration
# -----------------------------------------------------

# Load shared environment and aliases
[[ -f ~/.config/sh/env ]] && source ~/.config/sh/env
[[ -f ~/.config/sh/aliases ]] && source ~/.config/sh/aliases

# -----------------------------------------------------
# Bash Specifics
# -----------------------------------------------------

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Shell Prompt
PS1='[\u@\h \W]\$ '

# Load single customization file (if exists)
[[ -f ~/.bashrc_custom ]] && source ~/.bashrc_custom
