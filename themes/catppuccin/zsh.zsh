# Catppuccin Mocha colors for zsh-autosuggestions and zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: muted overlay so completions are subtle.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70"

# Syntax highlighting palette: valid command green, path blue, string yellow,
# unknown command red, reserved word purple, on the Catppuccin Mocha palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#cdd6f4"
ZSH_HIGHLIGHT_STYLES[command]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[function]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#a6e3a1"
ZSH_HIGHLIGHT_STYLES[path]="fg=#89b4fa"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#585b70"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#94e2d5"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#f9e2af"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#f9e2af"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#f9e2af"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#f38ba8"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#cba6f7"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#585b70"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#94e2d5,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#89b4fa,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#cba6f7,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#a6e3a1,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#f38ba8,bold"

# bat: Dracula is the closest built-in approximation of Catppuccin Mocha.
# Drop a Catppuccin .tmTheme into $(bat --config-dir)/themes and `bat cache --build`
# for an exact match.
export BAT_THEME="Dracula"
