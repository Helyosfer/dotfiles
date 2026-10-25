#!/usr/bin/env bash
# Dotfiles kurulumu: paketleri kurar, pokemon-colorscripts'i indirir,
# ayar dosyalarını ~/ altına bağlar. Tekrar çalıştırmak güvenlidir.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YEDEK="$HOME/.dotfiles-yedek/$(date +%Y%m%d-%H%M%S)"
POKE_DIR="$HOME/.local/opt/pokemon-colorscripts"
POKE_REPO="https://gitlab.com/phoneybadger/pokemon-colorscripts.git"

bilgi() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
uyari() { printf '\033[1;33m!!\033[0m  %s\n' "$*"; }

# --- 1. Paketler -----------------------------------------------------------
paketleri_kur() {
  if ! command -v pacman >/dev/null; then
    uyari "pacman yok; şunları elle kur: kitty fish git python, JetBrainsMono Nerd Font, pure (fish teması)"
    return
  fi
  bilgi "Paketler kuruluyor"
  sudo pacman -S --needed --noconfirm kitty fish git python ttf-jetbrains-mono-nerd

  # pure teması CachyOS deposunda paket olarak var; yoksa fisher ile kurulur.
  if pacman -Si fish-pure-prompt >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm fish-pure-prompt
  else
    bilgi "pure, fisher ile kuruluyor"
    fish -c 'type -q fisher; or begin
      curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
      and fisher install jorgebucaran/fisher
    end; fisher install pure-fish/pure'
  fi
}

# --- 2. Pokemon ------------------------------------------------------------
pokemon_kur() {
  if [ -d "$POKE_DIR/.git" ]; then
    bilgi "pokemon-colorscripts güncelleniyor"
    git -C "$POKE_DIR" pull -q --ff-only
  elif [ -e "$POKE_DIR" ]; then
    bilgi "pokemon-colorscripts zaten kurulu, dokunulmadı"
  else
    bilgi "pokemon-colorscripts indiriliyor"
    mkdir -p "$(dirname "$POKE_DIR")"
    git clone -q --depth 1 "$POKE_REPO" "$POKE_DIR"
  fi
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$POKE_DIR/pokemon-colorscripts.py" "$HOME/.local/bin/pokemon-colorscripts"
}

# --- 3. Ayar dosyaları -----------------------------------------------------
# Her klasördeki (kitty, fish) dosyalar ~/ altındaki aynı yola bağlanır.
# Var olan dosya önce ~/.dotfiles-yedek altına taşınır.
bagla() {
  local paket="$1" kaynak hedef
  while IFS= read -r -d '' kaynak; do
    hedef="$HOME/${kaynak#"$DOTFILES/$paket/"}"
    if [ "$(readlink -f "$hedef" 2>/dev/null)" = "$kaynak" ]; then
      continue
    fi
    if [ -e "$hedef" ] || [ -L "$hedef" ]; then
      mkdir -p "$YEDEK/$(dirname "${hedef#"$HOME/"}")"
      mv "$hedef" "$YEDEK/${hedef#"$HOME/"}"
      uyari "Eski dosya yedeklendi: ${hedef/#$HOME/~}"
    fi
    mkdir -p "$(dirname "$hedef")"
    ln -s "$kaynak" "$hedef"
    bilgi "Bağlandı: ${hedef/#$HOME/~}"
  done < <(find "$DOTFILES/$paket" -type f -print0)
}

[ "${1:-}" = "--sadece-baglanti" ] || { paketleri_kur; pokemon_kur; }
for p in kitty fish; do bagla "$p"; done

# $SHELL o anki oturumdan gelir; asıl giriş kabuğu passwd kaydındadır.
giris_kabugu="$(getent passwd "$(id -un)" | cut -d: -f7)"
if [ "$(basename "${giris_kabugu:-$SHELL}")" != fish ]; then
  uyari "Varsayılan kabuk fish değil. Değiştirmek için: chsh -s \"\$(command -v fish)\""
fi
bilgi "Bitti. Yeni bir kitty penceresi aç."
