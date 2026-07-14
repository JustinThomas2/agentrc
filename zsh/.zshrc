# ~/.zshrc (symlinked from agentrc/zsh/.zshrc)
#
# PLACEHOLDER: real zsh config goes here (exports, aliases, plugins, prompt).
# Keep anything private or machine-specific in ~/.zshrc.local (private repo).

# Source the private/machine-local layer last so it can override anything above.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
