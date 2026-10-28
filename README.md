# dotfiles

Kişisel yapılandırma dosyaları: kitty terminali, fish kabuğu (pure teması), açılışta rastgele pokemon ve ASUS TUF Gaming A16 (FA608UM) için cihaza özgü ayarlar.

- [Yeni bilgisayara kurulum](#yeni-bilgisayara-kurulum)
- [Dosyalar](#dosyalar)
- [Cihaza özgü ayarlar](#cihaza-özgü-ayarlar)
- [Depoda olmayan ayarlar](#depoda-olmayan-ayarlar)
- [Değişiklik yapınca](#değişiklik-yapınca)

## Yeni bilgisayara kurulum

```bash
git clone https://github.com/Helyosfer/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Betik şunları yapar:

1. **Paketler** (Arch/CachyOS, `pacman`): kitty, fish, git, python, JetBrainsMono Nerd Font. pure teması CachyOS'ta paketten, diğer dağıtımlarda fisher ile kurulur.
2. **Pokemon**: [pokemon-colorscripts](https://gitlab.com/phoneybadger/pokemon-colorscripts) asıl kaynağından `~/.local/opt/pokemon-colorscripts` içine indirilir, `~/.local/bin/pokemon-colorscripts` olarak bağlanır.
3. **Ayar dosyaları**: `kitty/` ve `fish/` içindeki dosyalar `~/` altındaki aynı yollara sembolik bağlantı olarak konur. Var olan dosyalar silinmez, önce `~/.dotfiles-yedek/<tarih>/` altına taşınır.

Tekrar çalıştırmak güvenlidir.

| Seçenek | Ne yapar |
|---|---|
| `--sadece-baglanti` | Paket kurmaz, pokemon indirmez; yalnızca bağlantıları yeniler |
| `--hybrid-gpu` | Cihaza özgü iGPU/dGPU ayarını kurar ([ayrıntı](#igpu-ve-dgpu-hybrid-gpu)), varsayılan olarak kapalı |

```bash
~/dotfiles/install.sh --sadece-baglanti --hybrid-gpu
```

Varsayılan kabuk fish değilse betik sonunda `chsh` komutunu hatırlatır.

## Dosyalar

| Yol | Ne yapar |
|---|---|
| `kitty/.config/kitty/kitty.conf` | JetBrainsMono Nerd Font, Catppuccin Mocha, saydamlık ve blur, imleç izi, `shell /usr/bin/fish`, sabit pencere boyutu (108×34 hücre, fastfetch çıktısı sığar) |
| `fish/.config/fish/config.fish` | `~/.local/bin` PATH'te, pure istemi (Arch logosu, cyan), açılışta pokemon |
| `cihaza-ozel/hybrid-gpu/` | iGPU/dGPU yönetimi: KWin ayarı, `gpu-run`, profil izleyici, Steam başlatıcısı |
| `cihaza-ozel/asus-tuf/` | Ekran otomatik parlaklığı ve klavye RGB aydınlatması |
| `install.sh` | Kurulum betiği |

`kitty` ve `fish` klasörleri [GNU Stow](https://www.gnu.org/software/stow/) düzeninde, betik yerine `stow kitty fish` de kullanılabilir. `cihaza-ozel/` Stow düzeninde değildir, ayrı kurulur.

## Cihaza özgü ayarlar

Bunlar ASUS TUF Gaming A16 (FA608UM; AMD Radeon 780M + NVIDIA RTX 5060) içindir, başka donanımda çalıştırma.

### iGPU ve dGPU (`hybrid-gpu`)

Kurulum: `install.sh --hybrid-gpu` (udev kuralı ve `sudo` ister). Betik AMD GPU'nun beklenen PCI adresinde (`0000:65:00.0`) olduğunu kontrol eder ve `/dev/dri/igpu` oluşmadan KWin ayarını yazmaz.

| Dosya | Ne yapar |
|---|---|
| `61-igpu.rules` | AMD GPU için `:` içermeyen `/dev/dri/igpu` bağlantısı üretir. KWin `KWIN_DRM_DEVICES` değerini `:` ile böldüğü için `by-path` yolu kullanılamaz |
| `kwin-gpu.conf` | KWin'i yalnızca iGPU'ya sabitler; dGPU boşta uyur (boşta ~15 W yerine ~9 W) |
| `gpu-run` | Komutu güç profiline göre başlatır: **power-saver** → iGPU, **performance** → dGPU, **balanced** → uygulamaya dokunmaz. `gpu-run -i\|-d komut` ile elle seçilir |
| `steam.desktop` | Steam'i `gpu-run` üzerinden açar; oyunlar Steam'in ortamını devralır |
| `gpu-profil-izle` + `.service` | Profil değişince, Steam başka profille açılmışsa bildirim gönderir (kullanıcı servisi) |

Notlar:

- Profil, uygulama **başlarken** okunur; çalışan uygulama GPU değiştirmez. Profili değiştirince Steam'i tamamen kapatıp yeniden aç.
- KWin'in kullandığı GPU oturum açılırken seçilir, canlı değişmez.
- Harici ekran dGPU'ya bağlı portlardaysa görüntü gelmeyebilir; o zaman `~/.config/environment.d/kwin-gpu.conf` silinip yeniden giriş yapılır.
- Oyunlarda manuel dGPU için Steam başlatma seçeneği: `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only gamemoderun %command%`

### ASUS TUF (`asus-tuf`)

`install.sh` bunları kurmaz; sistem dosyaları olduğu için `sudo` ile elle kurulur:

```bash
cd ~/dotfiles/cihaza-ozel/asus-tuf
sudo install -m 755 klavye-rgb /usr/local/bin/klavye-rgb
sudo install -m 644 klavye-rgb.service screen-auto-brightness.service /etc/systemd/system/
sudo install -m 644 61-klavye-rgb.rules /etc/udev/rules.d/
sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=hidraw --action=add
sudo systemctl daemon-reload
sudo systemctl enable --now klavye-rgb.service screen-auto-brightness.service
ln -sfn ~/dotfiles/cihaza-ozel/asus-tuf/klavye-rgb ~/.local/bin/klavye-rgb
```

| Dosya | Ne yapar |
|---|---|
| `screen-auto-brightness.service` | BIOS'un otomatik parlaklığını (`asus-armoury/screen_auto_brightness`) açılışta kapatır. Açıkken ekran girişten sonra kısılıyordu. Servis yolun oluşmasını en fazla 30 sn bekler |
| `klavye-rgb` | Klavye aydınlatmasını HID LampArray ile yönetir (aşağıya bak) |
| `klavye-rgb.service` | Açılışta ve uykudan sonra açılış rengini (amber) uygular |
| `61-klavye-rgb.rules` | Klavye denetleyicisinin hidraw'ına oturumdaki kullanıcıya yazma izni verir (`uaccess`); `klavye-rgb` root istemesin diye |

**Klavye RGB.** Denetleyici ITE `0B05:19B6` (I2C) ASUS'un Aura protokolünü değil, HID LampArray (Dynamic Lighting) konuşur; bu yüzden `asusctl` işe yaramaz. Aydınlatma **tek bölgedir** (tek lamba, tüm klavye), tuş başına renk yapılamaz. Açılışta çekirdek aydınlatmayı kimseye bağlamadığı için ışıklar sönük kalır; servis bunu çözer.

```bash
klavye-rgb sonraki | onceki   # paletteki sonraki / önceki renk (amber, mor, mavi, ...)
klavye-rgb varsayilan         # açılış rengi (amber)
klavye-rgb renk R G B [YOG]   # sabit renk, 0-255
klavye-rgb otonom 1           # cihazın kendi (beyaz) moduna dön
klavye-rgb kapat | bilgi
```

Renkler doygun seçilmiştir: LED'ler kanalları karıştırınca beyaza kaydığı için en az bir kanal sıfıra yakındır, pastel tonlar soluk görünür. `klavye-rgb` dosyasını değiştirirsen `/usr/local/bin` kopyasını yeniden kur (yukarıdaki `install` komutu); `~/.local/bin` bağlantısı zaten depodaki dosyayı gösterir.

## Depoda olmayan ayarlar

Bunlar uygulamaların kendi dosyalarında durur, yeni bilgisayarda elle yapılır:

- **KWin penceresi (kitty'yi ortalamak):** `~/.config/kwinrulesrc` içinde `kitty` sınıfı için `placement=Centered`. Wayland'de kitty pencere konumunu kendisi belirleyemez. KDE bu dosyayı yeniden yazarken sembolik bağı bozabildiği için depoya konmadı.
- **Fn+F4 kısayolu:** Sistem Ayarları → Kısayollar → Özel Kısayollar → komut `klavye-rgb sonraki`.
- **Proton VPN:** Split tunneling "include" modunda VPN'e yalnızca Discord girer. Bu modda sistem DNS'i VPN'in `10.2.0.1` adresine çevrilir ve VPN dışı uygulamalar ona ulaşamaz; çözüm Settings → Advanced → Custom DNS: `1.1.1.1`, `9.9.9.9`.
- **SSH:** `~/.ssh/` bilerek depoda yok. Özel anahtar asla depoya konmamalı.

## Değişiklik yapınca

Bağlantılar sayesinde `~/.config/...` altındaki dosyayı düzenlemek, repodaki dosyayı düzenlemek demektir:

```bash
cd ~/dotfiles && git add -A && git commit -m "..." && git push
```

Diğer bilgisayarda `git -C ~/dotfiles pull` yeterli. `/etc` ve `/usr/local` altındaki sistem kopyaları bağlantı değil, kopyadır: bu klasördeki kaynak dosyayı değiştirince ilgili `sudo install ...` komutunu yeniden çalıştır.
