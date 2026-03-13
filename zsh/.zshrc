#            _
#    _______| |__  _ __ ___
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__
# (_)___|___/_| |_|_|  \___|
#
# -----------------------------------------------------
# Optimized zshrc loader
# -----------------------------------------------------

# Load modular configuration
# Sources files from ~/.config/zshrc/ unless a version exists in custom/
for f in ~/.config/zshrc/*(N-.); do
    if [[ -f ~/.config/zshrc/custom/${f:t} ]]; then
        source ~/.config/zshrc/custom/${f:t}
    else
        source "$f"
    fi
done

# Load single customization file (if exists)
[[ -f ~/.zshrc_custom ]] && source ~/.zshrc_custom

# Load environment
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
