# Matte Black (vague.nvim palette) colors for zsh-autosuggestions and
# zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: near-invisible on the dark matte background.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#2a2a2d"

# Syntax highlighting palette: desaturated tones on the vague dark palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#a8a8b3"
ZSH_HIGHLIGHT_STYLES[command]="fg=#7b9c7b"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#7b9c7b"
ZSH_HIGHLIGHT_STYLES[function]="fg=#7b9c7b"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#7b9c7b"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#7b9c7b"
ZSH_HIGHLIGHT_STYLES[path]="fg=#7b8fa8"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#404045"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#7ba8a8"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#c0b07b"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#c0b07b"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#c0b07b"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#c07b7b"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#9b7ba8"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#404045"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#7ba8a8,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#7b8fa8,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#9b7ba8,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#7b9c7b,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#c07b7b,bold"

# bat: base16 is the closest neutral dark approximation.
export BAT_THEME="base16"
