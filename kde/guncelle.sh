#!/usr/bin/env bash
# Canlı KDE ve Hyprland ayarlarını ve paket listelerini bu depoya kopyalar (bağlantı değil, anlık görüntü).
# KDE dosyaları atomik yazdığı için symlink kırılır; bu yüzden kopyalıyoruz.
set -euo pipefail
cd "$(dirname "$0")/.."
for pkg in kde hypr; do
  for f in $(cd "$pkg/.config" && find . -type f | sed 's|^\./||'); do
    [ -f "$HOME/.config/$f" ] && cp "$HOME/.config/$f" "$pkg/.config/$f"
  done
done
pacman -Qqen | sort > packages/pacman.txt
pacman -Qqem | sort > packages/aur.txt
git status --short
