# ~/.zshrc (symlinked from agentrc/zsh/.zshrc)
# Portable across machines. Tool hooks are guarded so a machine missing a
# tool still gets a working shell. Machine-specific config goes in
# ~/.zshrc.local, sourced at the end.

### zsh defaults
skip_global_compinit=1
autoload -U colors && colors
autoload zmv
HISTSIZE=10000
SAVEHIST=10000
# Fix home/end keys
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line

### Editor
if command -v code >/dev/null 2>&1; then
  export EDITOR="code -w"
fi

### PATH
export PATH="$HOME/.local/bin:$PATH"
[[ -d /opt/nvim-linux-x86_64/bin ]] && export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

### Prompt
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

### Node (fnm first, volta prepended after — volta's shims win for plain `node`)
command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd)"
[[ -d "$HOME/.volta/bin" ]] && export PATH="$HOME/.volta/bin:$PATH"

### WSL helpers (no-ops on non-WSL machines)
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  # Fix for WSL interop sockets going away
  function cd () {
    builtin cd "$@"

    export WSL_INTEROP=
    for socket in /run/WSL/*; do
      if ss -elx | grep -q "$socket"; then
        export WSL_INTEROP=$socket
      else
        rm -v $socket
      fi
    done

    if [[ -z $WSL_INTEROP ]]; then
      echo -e "\033[31mNo working WSL_INTEROP socket found !\033[0m"
    fi
  }

  alias open='explorer.exe'
  alias wsl='wsl.exe'
  alias newtab='wt.exe -w 0 new-tab -d "$(wslpath -w "$PWD")"'
fi

# Source the private/machine-local layer last so it can override anything above.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
