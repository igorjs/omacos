# Gruvbox Dark colors for zsh-autosuggestions and zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: warm grey so completions are subtle.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#928374"

# Syntax highlighting palette: valid command green, path blue, string yellow,
# unknown command red, reserved word purple, on the Gruvbox Dark palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#ebdbb2"
ZSH_HIGHLIGHT_STYLES[command]="fg=#b8bb26"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#b8bb26"
ZSH_HIGHLIGHT_STYLES[function]="fg=#b8bb26"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#b8bb26"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#b8bb26"
ZSH_HIGHLIGHT_STYLES[path]="fg=#83a598"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#928374"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#8ec07c"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#fabd2f"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#fabd2f"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#fabd2f"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#fb4934"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#d3869b"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#928374"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#8ec07c,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#83a598,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#d3869b,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#b8bb26,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#fb4934,bold"

# bat: gruvbox-dark is a built-in bat theme.
export BAT_THEME="gruvbox-dark"
