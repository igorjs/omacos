# Osaka Jade (solarized-osaka.nvim) colors for zsh-autosuggestions and
# zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: muted blue-green so completions are subtle.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#586e75"

# Syntax highlighting palette on the Solarized Dark palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#839496"
ZSH_HIGHLIGHT_STYLES[command]="fg=#859900"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#859900"
ZSH_HIGHLIGHT_STYLES[function]="fg=#859900"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#859900"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#859900"
ZSH_HIGHLIGHT_STYLES[path]="fg=#268bd2"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#586e75"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#2aa198"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#b58900"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#b58900"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#b58900"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#dc322f"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#6c71c4"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#586e75"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#2aa198,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#268bd2,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#6c71c4,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#859900,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#dc322f,bold"

# bat: Solarized (dark) is a built-in bat theme.
export BAT_THEME="Solarized (dark)"
