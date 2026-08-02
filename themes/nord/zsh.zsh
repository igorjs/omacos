# Nord colors for zsh-autosuggestions and zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: Polar Night overlay so completions are subtle.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#4c566a"

# Syntax highlighting palette: valid command green, path blue, string yellow,
# unknown command red, reserved word purple, on the Nord palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#d8dee9"
ZSH_HIGHLIGHT_STYLES[command]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[function]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#a3be8c"
ZSH_HIGHLIGHT_STYLES[path]="fg=#81a1c1"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#4c566a"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#88c0d0"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#ebcb8b"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#ebcb8b"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#ebcb8b"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#bf616a"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#b48ead"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#4c566a"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#88c0d0,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#81a1c1,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#b48ead,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#a3be8c,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#bf616a,bold"

# bat: Nord is a built-in bat theme.
export BAT_THEME="Nord"
