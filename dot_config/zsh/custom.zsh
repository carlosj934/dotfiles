# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_AUTO_UPDATE=1

# Ghostty
export GHOSTTY_BIN_DIR="/Applications/Ghostty.app/Contents/MacOS"
export PATH="$GHOSTTY_BIN_DIR:$PATH"

# mise - tool version management (Go, Python, Node, etc.)
eval "$(mise activate zsh)"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export GOPRIVATE="gitlab.com/*"

# Starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# Load Git completion
zstyle ':completion:*:*:git:*' script $HOME/.config/zsh/git-completion.bash
fpath=($HOME/.config/zsh $fpath)
autoload -Uz compinit && compinit

# Neovim as MANPAGER
export MANPAGER='nvim +Man!'

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_DEFAULT_COMMAND='rg --hidden -l ""' # Include hidden files

bindkey "ç" fzf-cd-widget # Fix for ALT+C on Mac

# fd - cd to selected directory
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# fh - search in your command history and execute selected command
fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

# herdr auto-launches from Ghostty's `command` setting, so there is no shell auto-start here.

# zoxide - a better cd command
eval "$(zoxide init zsh)"

# yazi shell wrapper (https://yazi-rs.github.io/docs/quick-start#shell-wrapper).
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Activate syntax highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# Disable underline
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none

# Activate autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Vi mode
bindkey -v # Enable vi keybindings
export KEYTIMEOUT=1 # Makes switching modes quicker
export VI_MODE_SET_CURSOR=true # trigger cursor shape changes when switching modes

# Gets called every time the keymap changes (insert <-> normal mode)
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]]; then
    echo -ne '\e[2 q' # block
  else
    echo -ne '\e[6 q' # beam
  fi
}
# Register this function as a ZLE (Zsh Line Editor) widget
zle -N zle-keymap-select

# Runs once when a new ZLE session starts (e.g. when a prompt appears)
zle-line-init() {
  zle -K viins # Start in vi insert mode
  echo -ne '\e[6 q'
}
zle -N zle-line-init
echo -ne '\e[6 q' # Use beam shape cursor on startup

# Yank to the system clipboard
function vi-yank-xclip {
  zle vi-yank
  echo "$CUTBUFFER" | pbcopy -i
}

zle -N vi-yank-xclip
bindkey -M vicmd 'y' vi-yank-xclip

# Press 'v' in normal mode to launch Vim with current line
autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Prevent sleep (even with the lid closed) until cancelled.
nosleep() {
  sudo pmset -a disablesleep 1
  caffeinate -si &
  local pid=$!
  trap "kill $pid 2>/dev/null; sudo pmset -a disablesleep 0; trap - INT" INT
  wait $pid
  sudo pmset -a disablesleep 0
}

movecur() {
  caffeinate -di bash -c '
    while true; do
      dx=$((RANDOM % 41 - 20))            # -20..+20 px
      dy=$((RANDOM % 41 - 20))            # -20..+20 px
      pause=$((30 + RANDOM % 120))        # 30..149 ms between out and back
      gap=$((1 + RANDOM % 4))             # 1..4 s between iterations
      cliclick "m:$(printf "%+d,%+d" $dx $dy)" "w:$pause" "m:$(printf "%+d,%+d" $((-dx)) $((-dy)))"
      sleep $gap
    done
  '
}

# opencode
alias oc='opencode'

# ocs [name] [-- opencode-args...]: start opencode as a herdr-tracked agent in a new split pane.
ocs() {
  if [ -z "$HERDR_PANE_ID" ]; then
    echo "ocs: not inside a herdr pane" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "ocs: needs jq (brew install jq)" >&2
    return 1
  fi

  local name="${1:-oc-$(date +%s)}"
  [ $# -gt 0 ] && shift

  local split pane_id
  split=$(herdr pane split --current --direction right --no-focus) || return 1
  pane_id=$(printf '%s\n' "$split" | jq -r '.result.pane.pane_id')

  if [ -z "$pane_id" ] || [ "$pane_id" = "null" ]; then
    echo "ocs: failed to split pane" >&2
    return 1
  fi

  herdr agent start "$name" --kind opencode --pane "$pane_id" -- "$@"
}

# ocp <agent-name> "<prompt>" [timeout_ms]: send a prompt to an opencode agent and wait until it settles.
ocp() {
  local name="$1"
  local prompt="$2"
  local timeout="${3:-600000}"

  if [ -z "$name" ] || [ -z "$prompt" ]; then
    echo 'usage: ocp <agent-name> "<prompt>" [timeout_ms]' >&2
    return 1
  fi

  herdr agent prompt "$name" "$prompt" --wait --timeout "$timeout"
}

# ocr <agent-name> [lines]: read an opencode agent's recent output.
ocr() {
  local name="$1"
  local lines="${2:-120}"
  if [ -z "$name" ]; then
    echo "usage: ocr <agent-name> [lines]" >&2
    return 1
  fi
  herdr agent read "$name" --source recent-unwrapped --lines "$lines"
}

# List every herdr-tracked agent and its live state (working/blocked/done/idle)
alias ocl='herdr agent list'

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
