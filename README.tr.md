# ASUS TUF Gaming A16 (FA608UM) için Arch Linux ayarları

[English](README.md) | **Türkçe**

**ASUS TUF Gaming A16 (FA608UM)** (Radeon 780M + RTX 5060) için Linux düzeltmeleri, ayrıca kitty ve fish ayarlarım.

> Yalnızca FA608UM, Arch Linux, KDE Plasma 6 (Wayland) üzerinde denendi. Çalıştırmadan önce `install.sh`'ı oku: `sudo` kullanır.

## Kurulum

```bash
git clone https://github.com/Helyosfer/dotfiles.git ~/dotfiles
~/dotfiles/install.sh --hepsi
```

Sonra çıkış yapıp tekrar gir. Betik dizüstü modelini kontrol eder, GPU adresini kendisi bulur. Var olan dosyalar yedeklenir, silinmez. Tekrar çalıştırmak güvenlidir.

| Seçenek | Ne yapar |
|---|---|
| `--hepsi` | Her şey (paketler, ayarlar, GPU, ASUS düzeltmeleri) |
| `--hybrid-gpu` | Yalnızca GPU ayarı |
| `--asus-tuf` | Yalnızca parlaklık ve klavye RGB |
| `--sadece-baglanti` | Sadece ayar dosyalarını bağlar, bir şey kurmaz |
| `--zorla` | Model kontrolünü atlar |

## Ne düzeltir

| Sorun | Çözüm |
|---|---|
| dGPU hiç uyumuyor (boşta ~15 W) | KWin yalnızca iGPU'yu kullanır. dGPU uyur, boşta ~9 W |
| Oyun yanlış GPU'da açılıyor | `gpu-run` GPU'yu güç profiline göre seçer |
| Ekran girişten sonra kendiliğinden kısılıyor | Bir servis BIOS'un otomatik parlaklığını kapatır |
| Açılışta klavye ışığı kapalı | Bir servis açılışta ve uykudan sonra rengi ayarlar |
| `asusctl` klavyeyi yönetemiyor | `klavye-rgb`, bu klavye için küçük bir araç |

## Kullanım

**Programı bir GPU'da çalıştır**

```bash
gpu-run -d program    # dGPU (NVIDIA)
gpu-run -i program    # iGPU (AMD)
gpu-run program       # güç profilini izler
```

dGPU isteyen oyun için Steam başlatma seçeneği:

```
gpu-run -d %command%
```

**Klavye rengi** (tüm klavye tek lamba, tuş başına renk yok)

```bash
klavye-rgb sonraki    # sonraki renk (KDE kısayollarında Fn+F4'e bağla)
klavye-rgb renk 255 0 0
klavye-rgb kapat      # söndür
```

**dGPU uyuyor mu?** `nvidia-smi` kullanma, GPU'yu uyandırır:

```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status   # "suspended" = iyi
```

## Bilmekte fayda var

- Güç profili uygulama **başlarken** okunur. Steam'i Balanced ya da Power Save'de aç, yoksa dGPU'yu uyanık tutar.
- dGPU portlarına bağlı harici ekran, KWin iGPU'ya sabitliyken çalışmaz. `~/.config/environment.d/kwin-gpu.conf` dosyasını sil, yeniden giriş yap.
- Bu modelde fan eğrisi Linux'ta desteklenmiyor, `asusctl` de bu klavyeyi tanımıyor; o yüzden kullanılmadı.
- Ekranda siyah çizgi ya da titreme: VRR'yi kapat, `kscreen-doctor output.eDP-1.vrrpolicy.never`.
- Pil şarj sınırı ek araç olmadan çalışır: `echo 80 | sudo tee /sys/class/power_supply/BAT1/charge_control_end_threshold` (yeniden başlatınca sıfırlanır).

## Dosyalar

| Yol | Ne |
|---|---|
| `install.sh` | Kurulum betiği |
| `cihaza-ozel/hybrid-gpu/` | GPU ayarı (`gpu-run`, KWin, Steam başlatıcı) |
| `cihaza-ozel/asus-tuf/` | Klavye RGB ve parlaklık servisleri |
| `kitty/`, `fish/` | Terminal ve kabuk ayarlarım |

Sistem dosyaları (`/etc`, `/usr/local`) **kopyadır**. Burada bir dosyayı düzenleyince `install.sh`'ı tekrar çalıştır.

Bilerek depoda olmayanlar: SSH anahtarları, VPN ayarları, KDE pencere kuralları.

## Lisans

[MIT](LICENSE). Garanti yok, bazı dosyalar root olarak çalışır: sorumluluk sende.
