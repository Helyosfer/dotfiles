# CachyOS'un hazır fish ayarları (yalnızca CachyOS'ta bulunur)
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# Ensure local bin is in PATH
fish_add_path ~/.local/bin

# Set Arch Linux logo as prompt symbol with cyan color
set -U pure_symbol_prompt "󰣇 "
set -U pure_color_prompt_on_success cyan

# Pokemon startup greeting (isimsiz, sadece sprite)
function fish_greeting
    if test -x ~/.local/bin/pokemon-colorscripts
        ~/.local/bin/pokemon-colorscripts -r --no-title
    else if type -q pokemon-colorscripts
        pokemon-colorscripts -r --no-title
    end
end
