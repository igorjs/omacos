# Tokyo Night colors for zsh-autosuggestions and zsh-syntax-highlighting.
# Sourced from the OmacOS managed block in ~/.zshrc, between the autosuggest
# source and the syntax-highlight source (see install/shell.sh).

# Autosuggestions: muted grey so completions are subtle.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#565f89"

# Syntax highlighting palette: valid command green, path blue, string yellow,
# unknown command red, reserved word purple, on the Tokyo Night palette.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=#c0caf5"
ZSH_HIGHLIGHT_STYLES[command]="fg=#9ece6a"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#9ece6a"
ZSH_HIGHLIGHT_STYLES[function]="fg=#9ece6a"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#9ece6a"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#9ece6a"
ZSH_HIGHLIGHT_STYLES[path]="fg=#7aa2f7"
ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#565f89"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#7dcfff"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#e0af68"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#e0af68"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#e0af68"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#f7768e"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#bb9af7"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#565f89"

# Cursor/line/bracket highlight overrides — prevent standout/reverse-video
# rendering which causes Terminal.app to paint a cyan background block.
ZSH_HIGHLIGHT_STYLES[cursor]="none"
ZSH_HIGHLIGHT_STYLES[line]="none"
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]="fg=#7dcfff,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-1]="fg=#7aa2f7,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-2]="fg=#bb9af7,bold"
ZSH_HIGHLIGHT_STYLES[bracket-level-3]="fg=#9ece6a,bold"
ZSH_HIGHLIGHT_STYLES[bracket-error]="fg=#f7768e,bold"

# bat: ship with its closest built-in for Tokyo Night feel. Drop a Tokyo Night
# .tmTheme into $(bat --config-dir)/themes and `bat cache --build` if you want
# a perfect match.
export BAT_THEME="base16"
