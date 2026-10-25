# dotfiles

Kişisel yapılandırma dosyaları: kitty terminali, fish kabuğu (pure teması) ve açılışta rastgele pokemon.

## Yeni bilgisayara kurulum

```bash
git clone https://github.com/Helyosfer/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Betik şunları yapar:

1. **Paketler** (Arch/CachyOS, `pacman`): kitty, fish, git, python, JetBrainsMono Nerd Font. pure teması CachyOS'ta paketten, diğer dağıtımlarda fisher ile kurulur.
2. **Pokemon**: [pokemon-colorscripts](https://gitlab.com/phoneybadger/pokemon-colorscripts) asıl kaynağından `~/.local/opt/pokemon-colorscripts` içine indirilir, `~/.local/bin/pokemon-colorscripts` olarak bağlanır.
3. **Ayar dosyaları**: `kitty/` ve `fish/` içindeki dosyalar `~/` altındaki aynı yollara sembolik bağlantı olarak konur. Var olan dosyalar silinmez, önce `~/.dotfiles-yedek/<tarih>/` altına taşınır.

Tekrar çalıştırmak güvenlidir. Paket kurmadan yalnızca bağlantıları yenilemek için:

```bash
~/dotfiles/install.sh --sadece-baglanti
```

Varsayılan kabuk fish değilse betik sonunda `chsh` komutunu hatırlatır.

## İçerik

| Klasör  | Dosya                      | Ne yapar |
|---------|----------------------------|----------|
| `kitty` | `.config/kitty/kitty.conf` | JetBrainsMono Nerd Font, Catppuccin Mocha teması, saydamlık ve blur, imleç izi |
| `fish`  | `.config/fish/config.fish` | `~/.local/bin` PATH'te, pure istemi (Arch logosu, cyan), açılışta pokemon |

Dosyalar [GNU Stow](https://www.gnu.org/software/stow/) düzeninde olduğu için betik yerine `stow kitty fish` de kullanılabilir.

## Değişiklik yapınca

Bağlantılar sayesinde `~/.config/...` altındaki dosyayı düzenlemek, repodaki dosyayı düzenlemek demektir:

```bash
cd ~/dotfiles && git commit -am "..." && git push
```

Diğer bilgisayarda `git -C ~/dotfiles pull` yeterli.
