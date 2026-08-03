# Kanagawa Wave colors for zsh-autosuggestions and zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: Fuji Gray so completions are subtle.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#727169"

# Syntax highlighting palette: valid command green, path blue, string yellow,
# unknown command red, reserved word purple, on the Kanagawa Wave palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#dcd7ba"
ZSH_HIGHLIGHT_STYLES[command]="fg=#98bb6c"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#98bb6c"
ZSH_HIGHLIGHT_STYLES[function]="fg=#98bb6c"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#98bb6c"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#98bb6c"
ZSH_HIGHLIGHT_STYLES[path]="fg=#7e9cd8"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#727169"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#7fb4ca"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#e6c384"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#e6c384"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#e6c384"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#e82424"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#938aa9"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#727169"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#7aa89f,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#7e9cd8,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#957fb8,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#98bb6c,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#e82424,bold"

# bat: no built-in Kanagawa; base16 is the closest neutral dark approximation.
export BAT_THEME="base16"
