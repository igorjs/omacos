# Rose Pine (Main) colors for zsh-autosuggestions and zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: muted overlay so completions are subtle.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6e6a86"

# Syntax highlighting palette: valid command green, path blue, string yellow,
# unknown command red, reserved word purple, on the Rose Pine palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#e0def4"
ZSH_HIGHLIGHT_STYLES[command]="fg=#31748f"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#31748f"
ZSH_HIGHLIGHT_STYLES[function]="fg=#31748f"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#31748f"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#31748f"
ZSH_HIGHLIGHT_STYLES[path]="fg=#9ccfd8"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#6e6a86"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#ebbcba"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#f6c177"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#f6c177"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#f6c177"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#eb6f92"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#c4a7e7"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#6e6a86"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#ebbcba,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#9ccfd8,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#c4a7e7,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#31748f,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#eb6f92,bold"

# bat: no built-in Rose Pine; base16 is the closest neutral dark approximation.
export BAT_THEME="base16"
