# Everforest Dark Hard colors for zsh-autosuggestions and zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: muted grey-green so completions are subtle.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#5c6a72"

# Syntax highlighting palette: valid command green, path blue, string yellow,
# unknown command red, reserved word purple, on the Everforest Dark palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#d3c6aa"
ZSH_HIGHLIGHT_STYLES[command]="fg=#a7c080"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#a7c080"
ZSH_HIGHLIGHT_STYLES[function]="fg=#a7c080"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#a7c080"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#a7c080"
ZSH_HIGHLIGHT_STYLES[path]="fg=#7fbbb3"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#5c6a72"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#83c092"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#dbbc7f"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#dbbc7f"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#dbbc7f"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#e67e80"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#d699b6"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#5c6a72"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#83c092,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#7fbbb3,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#d699b6,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#a7c080,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#e67e80,bold"

# bat: no built-in Everforest; base16 is the closest neutral dark approximation.
export BAT_THEME="base16"
