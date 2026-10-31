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

# --- 4. Cihaza özgü: AMD iGPU + NVIDIA dGPU'lu ASUS dizüstü ----------------
# Yalnızca --hybrid-gpu ile çalışır. KWin'i iGPU'ya sabitler ki dGPU boşta uyuyabilsin.
# KWIN_DRM_DEVICES ':' ile bölündüğü için by-path yolu kullanılamaz; udev kuralı
# iGPU için ':' içermeyen /dev/dri/igpu bağlantısını üretir.
hybrid_gpu_kur() {
  local kaynak="$DOTFILES/cihaza-ozel/hybrid-gpu" pci="" d kural
  # AMD ekran denetleyicisini (vendor 0x1002, sınıf 0x03xxxx) PCI'dan bul; adres makineye göre değişir.
  for d in /sys/bus/pci/devices/*; do
    if [ "$(cat "$d/vendor" 2>/dev/null)" = 0x1002 ] && [[ "$(cat "$d/class" 2>/dev/null)" == 0x03* ]]; then
      pci="$(basename "$d")"
      break
    fi
  done
  if [ -z "$pci" ]; then
    uyari "AMD GPU bulunamadı; bu cihazda hybrid-gpu ayarı atlandı"
    return
  fi
  bilgi "AMD GPU bulundu: $pci"
  bilgi "udev kuralı kuruluyor"
  kural="$(mktemp)"
  sed "s/0000:65:00\.0/$pci/" "$kaynak/61-igpu.rules" > "$kural"
  sudo install -m 644 "$kural" /etc/udev/rules.d/61-igpu.rules
  rm -f "$kural"
  sudo udevadm control --reload
  sudo udevadm trigger --action=add --subsystem-match=drm
  sudo udevadm settle
  # Bağlantı oluşmadan KWin ayarı yazılmaz: yanlış yol oturumun açılmasını engeller.
  if [ ! -e /dev/dri/igpu ]; then
    uyari "/dev/dri/igpu oluşmadı; KWin ayarı yazılmadı"
    return
  fi
  mkdir -p "$HOME/.config/environment.d" "$HOME/.local/bin" "$HOME/.local/share/applications"
  ln -sfn "$kaynak/kwin-gpu.conf" "$HOME/.config/environment.d/kwin-gpu.conf"
  # gpu-run: güç profiline göre iGPU/dGPU seçen başlatıcı; Steam onun üzerinden açılır.
  ln -sfn "$kaynak/gpu-run" "$HOME/.local/bin/gpu-run"
  ln -sfn "$kaynak/steam.desktop" "$HOME/.local/share/applications/steam.desktop"
  # gpu-profil-izle: profil değişince Steam yeniden açılmalıysa bildirim gönderir.
  ln -sfn "$kaynak/gpu-profil-izle" "$HOME/.local/bin/gpu-profil-izle"
  mkdir -p "$HOME/.config/systemd/user"
  ln -sfn "$kaynak/gpu-profil-izle.service" "$HOME/.config/systemd/user/gpu-profil-izle.service"
  systemctl --user daemon-reload
  systemctl --user enable --now gpu-profil-izle.service || uyari "gpu-profil-izle servisi başlatılamadı (grafik oturumu dışında olabilir)"
  bilgi "KWin iGPU'ya sabitlendi. Çıkış yapıp tekrar gir."
}

# --- 5. Cihaza özgü: ASUS TUF A16 (parlaklık servisi + klavye RGB) ----------
# Yalnızca --asus-tuf ile çalışır. Sistem dosyalarını /etc ve /usr/local altına KOPYALAR.
asus_tuf_kur() {
  local kaynak="$DOTFILES/cihaza-ozel/asus-tuf"
  bilgi "ASUS TUF dosyaları kuruluyor (sudo ister)"
  sudo install -m 755 "$kaynak/klavye-rgb" /usr/local/bin/klavye-rgb
  sudo install -m 644 "$kaynak/klavye-rgb.service" "$kaynak/screen-auto-brightness.service" /etc/systemd/system/
  sudo install -m 644 "$kaynak/61-klavye-rgb.rules" /etc/udev/rules.d/61-klavye-rgb.rules
  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=hidraw --action=add
  sudo systemctl daemon-reload
  sudo systemctl enable --now screen-auto-brightness.service || uyari "screen-auto-brightness.service başlatılamadı (bu cihazda asus-armoury yolu olmayabilir)"
  sudo systemctl enable --now klavye-rgb.service || uyari "klavye-rgb.service başlatılamadı (denetleyici bulunamadı mı? 'klavye-rgb bilgi' ile bak)"
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$kaynak/klavye-rgb" "$HOME/.local/bin/klavye-rgb"
  bilgi "Klavye rengi: klavye-rgb sonraki | onceki | renk R G B | varsayilan"
}

# Bu betik ASUS TUF Gaming A16 (FA608UM) için yazıldı; başka modelde cihaza özgü kısımları
# çalıştırmadan önce uyarır ve onay ister (--zorla ile atlanır).
model_kontrol() {
  local model
  model="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
  case "$model" in
    *FA608UM*) return 0 ;;
  esac
  uyari "Bu cihaz: '${model:-bilinmiyor}'. Cihaza özgü ayarlar ASUS TUF Gaming A16 (FA608UM) içindir."
  [ "$durum_zorla" = 1 ] && return 0
  if [ -t 0 ]; then
    read -r -p "Yine de devam edilsin mi? [e/H] " cevap
    case "$cevap" in e|E|evet) return 0 ;; esac
  fi
  uyari "Cihaza özgü ayarlar atlandı (zorlamak için --zorla)"
  return 1
}

kullanim() {
  cat <<'EOF'
Kullanım: ./install.sh [seçenekler]

  (seçeneksiz)       Paketler + pokemon + kitty/fish ayarları
  --sadece-baglanti  Paket kurma, yalnızca ayar dosyalarını bağla
  --hybrid-gpu       iGPU/dGPU ayarı (dGPU boşta uyusun; sudo ister)
  --asus-tuf         Parlaklık servisi + klavye RGB (sudo ister)
  --hepsi            Hepsi: paketler, bağlantılar, hybrid-gpu, asus-tuf
  --zorla            Model kontrolünü sormadan geç
  -h, --help         Bu yardım
EOF
}

durum_paket=1; durum_hybrid=0; durum_asus=0; durum_zorla=0
for arg in "$@"; do
  case "$arg" in
    --sadece-baglanti) durum_paket=0 ;;
    --hybrid-gpu) durum_hybrid=1 ;;
    --asus-tuf) durum_asus=1 ;;
    --hepsi) durum_hybrid=1; durum_asus=1 ;;
    --zorla) durum_zorla=1 ;;
    -h|--help) kullanim; exit 0 ;;
    *) uyari "Bilinmeyen seçenek: $arg"; kullanim; exit 1 ;;
  esac
done

if [ "$durum_hybrid" = 1 ] || [ "$durum_asus" = 1 ]; then
  model_kontrol || { durum_hybrid=0; durum_asus=0; }
fi

[ "$durum_paket" = 0 ] || { paketleri_kur; pokemon_kur; }
for p in kitty fish; do bagla "$p"; done
[ "$durum_hybrid" = 0 ] || hybrid_gpu_kur
[ "$durum_asus" = 0 ] || asus_tuf_kur

# $SHELL o anki oturumdan gelir; asıl giriş kabuğu passwd kaydındadır.
giris_kabugu="$(getent passwd "$(id -un)" | cut -d: -f7)"
if [ "$(basename "${giris_kabugu:-$SHELL}")" != fish ]; then
  uyari "Varsayılan kabuk fish değil. Değiştirmek için: chsh -s \"\$(command -v fish)\""
fi
bilgi "Bitti. Yeni bir kitty penceresi aç."
