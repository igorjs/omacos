# Ristretto (Monokai Pro ristretto filter) colors for zsh-autosuggestions
# and zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: dark plum so completions are subtle.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#3e2633"

# Syntax highlighting palette on the Monokai Pro ristretto palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#fff1f3"
ZSH_HIGHLIGHT_STYLES[command]="fg=#7bd88f"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#7bd88f"
ZSH_HIGHLIGHT_STYLES[function]="fg=#7bd88f"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#7bd88f"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#7bd88f"
ZSH_HIGHLIGHT_STYLES[path]="fg=#fd9353"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#5c3d4a"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#5ad4e6"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#fce566"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#fce566"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#fce566"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#fc618d"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#948ae3"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#5c3d4a"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#5ad4e6,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#fd9353,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#948ae3,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#7bd88f,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#fc618d,bold"

# bat: Monokai Extended is the closest built-in approximation.
export BAT_THEME="Monokai Extended"
