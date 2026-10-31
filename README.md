# dotfiles: ASUS TUF Gaming A16 (FA608UM) on Arch Linux

**English** | [Türkçe](README.tr.md)

Fixes and tweaks for the **ASUS TUF Gaming A16 (FA608UM)**: AMD Radeon 780M + NVIDIA RTX 5060, running Arch Linux with KDE Plasma (Wayland). Plus my kitty and fish setup.

> **Tested only on:** FA608UM, Arch Linux, kernel 7.2 (zen), KDE Plasma 6.8 Wayland. Other TUF/ROG models may use different PCI addresses or a different keyboard controller. Read each script before you run it, and never run system-level files blindly.

- [What this solves](#what-this-solves)
- [Quick start](#quick-start)
- [Hybrid GPU: dGPU sleeps when idle](#hybrid-gpu-dgpu-sleeps-when-idle)
- [Screen dims after login](#screen-dims-after-login)
- [Keyboard RGB (HID LampArray)](#keyboard-rgb-hid-lamparray)
- [Power profiles and fans](#power-profiles-and-fans)
- [Other things I ran into](#other-things-i-ran-into)
- [Not in this repo](#not-in-this-repo)
- [Personal dotfiles](#personal-dotfiles)

## What this solves

| Problem | Fix | Result |
|---|---|---|
| dGPU never sleeps, ~15 W idle | Pin KWin to the iGPU | dGPU `suspended` when idle, ~9 W |
| Games run on the wrong GPU | `gpu-run` picks the GPU from the power profile | Performance runs on the dGPU, Power Saver on the iGPU |
| Screen dims by itself after login | Firmware `screen_auto_brightness` switched off | Brightness stays where you set it |
| Keyboard backlight is dark after boot | Controller autonomous mode off, colour sent by a service | Lights on at boot and after sleep |
| `asusctl` does not control the keyboard | Own tool for the HID LampArray controller | Colours and Fn+F4 cycling |
| Black lines / flicker on the internal panel | Disable VRR, keep 165 Hz | See [other things](#other-things-i-ran-into) |

## Quick start

```bash
git clone https://github.com/Helyosfer/dotfiles.git ~/dotfiles
cd ~/dotfiles
less install.sh          # read it first, it uses sudo
./install.sh --hepsi     # everything: packages, configs, hybrid GPU, ASUS TUF fixes
```

Then log out and back in (KWin reads the GPU setting at login). `install.sh` checks the model (`FA608UM`) and asks before touching a different laptop, and it detects the AMD GPU's PCI address by itself.

`install.sh` options (messages are currently in Turkish):

| Option | What it does |
|---|---|
| *(none)* | Installs packages (`pacman`), downloads pokemon-colorscripts, links kitty and fish configs |
| `--hepsi` ("all") | Everything below plus the defaults |
| `--hybrid-gpu` | Hybrid GPU setup (dGPU sleeps when idle) |
| `--asus-tuf` | Brightness service + keyboard RGB service |
| `--sadece-baglanti` | "Links only": no packages, no downloads |
| `--zorla` ("force") | Skip the model check prompt |

Existing files are never deleted: they are moved to `~/.dotfiles-yedek/<date>/` first. Re-running is safe.

## Hybrid GPU: dGPU sleeps when idle

Files in [`cihaza-ozel/hybrid-gpu/`](cihaza-ozel/hybrid-gpu/).

By default KWin opens both GPUs, so the NVIDIA card never reaches runtime suspend. The fix is to tell KWin to use only the AMD iGPU.

1. **`61-igpu.rules`** (udev) creates `/dev/dri/igpu` for the AMD GPU. The by-path name contains `:` and `KWIN_DRM_DEVICES` splits on `:`, so it cannot be used directly. Using it breaks the login: the session never starts.
2. **`kwin-gpu.conf`** goes into `~/.config/environment.d/` and sets `KWIN_DRM_DEVICES=/dev/dri/igpu`.
3. **`gpu-run`** launches a program on the GPU that matches the current power profile:
   - `power-saver` → iGPU, `performance` → dGPU, `balanced` → leaves the app alone.
   - `gpu-run -d program` forces the dGPU, `gpu-run -i program` the iGPU.
4. **`steam.desktop`** starts Steam through `gpu-run`.
5. **`gpu-profil-izle`** (user service) notifies you when the profile changed after Steam was started, because the profile is only read at launch.

**Check the PCI address first.** On my machine the AMD GPU is `0000:65:00.0` and the NVIDIA GPU `0000:01:00.0`. Look at yours with `ls -l /dev/dri/by-path/` and edit `61-igpu.rules`. A wrong path makes KWin fail at login. If that happens, delete `~/.config/environment.d/kwin-gpu.conf` from a TTY.

Check that the dGPU sleeps (do **not** use `nvidia-smi`, it wakes the GPU):

```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status   # should say "suspended" when idle
```

Steam launch options for a game that must use the dGPU:

```
gpu-run -d %command%
powerprofilesctl launch -p performance -- gamemoderun gpu-run -d %command%
```

Notes:

- Start Steam in Balanced or Power Saver. If Steam is started with dGPU environment, `steam` and `steamwebhelper` keep `/dev/nvidia*` open and the dGPU never sleeps.
- Firefox's RDD process can hold the NVIDIA device through the VA-API driver (not verified).
- An external monitor wired to the dGPU ports will not work while KWin is pinned to the iGPU. Remove `kwin-gpu.conf` and log in again to get it back.
- Measured, Prism Launcher with the Minecraft instance on the dGPU: 447 fps, GPU 55 W power cap, no thermal throttling, fan 4000-5000 RPM. On the iGPU it was 226 fps.

## Screen dims after login

Files in [`cihaza-ozel/asus-tuf/`](cihaza-ozel/asus-tuf/).

The firmware option `asus-armoury/screen_auto_brightness` dims the panel after login. `screen-auto-brightness.service` writes `0` to it at boot (it waits up to 30 s for the sysfs path).

## Keyboard RGB (HID LampArray)

The keyboard controller is an ITE `0B05:19B6` on I2C. It speaks the standard **HID LampArray** (Dynamic Lighting) protocol, not ASUS Aura, so `asusctl` cannot drive it. The backlight is **one single lamp**: you cannot colour individual keys.

After boot the lights stay dark because the lamp array is not in autonomous mode and nobody sends a colour. `klavye-rgb.service` fixes that at boot and after sleep.

```bash
klavye-rgb sonraki | onceki   # next / previous colour in the palette
klavye-rgb varsayilan         # boot colour (amber)
klavye-rgb renk R G B [I]     # fixed colour, 0-255
klavye-rgb otonom 1           # back to the device's own white mode
klavye-rgb kapat | bilgi
```

Install by hand (system files, needs `sudo`):

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

`61-klavye-rgb.rules` gives the logged-in user write access to the controller (`uaccess`) so you do not need root. Bind **Fn+F4** to `klavye-rgb sonraki` in System Settings → Shortcuts → Custom Shortcuts. Fn+F2/F3 already work in hardware.

Colours are saturated on purpose: the LEDs mix towards white, so at least one channel stays near zero.

## Power profiles and fans

- Profiles come from `power-profiles-daemon` (`platform_profile`: quiet / balanced / performance). KDE switches them fine.
- Measured fan speeds: Performance 2300-2500 RPM at light load (4000-5000 under a game), Balanced 900-1600, Power Saver 0 RPM at idle.
- The kernel log shows `fan_curve_get_factory_default failed -19`: custom fan curves are **not supported** on this model, so fan curves cannot be changed on Linux.
- **Why not `asusctl`?** It does not support this keyboard (no Aura, no LampArray), and its profile daemon conflicts with `power-profiles-daemon`. I did not install it.
- Battery charge limit works without `asusctl`: `echo 80 | sudo tee /sys/class/power_supply/BAT1/charge_control_end_threshold` (resets on reboot; use a systemd service to persist it).

## Other things I ran into

- **Black lines and the screen going away and back** on the internal panel were caused by VRR (set to Automatic). Fix: keep 165 Hz and turn VRR off:
  `kscreen-doctor output.eDP-1.mode.1 output.eDP-1.vrrpolicy.never`
  If it still happens, try the kernel parameter `amdgpu.dcdebugmask=0x10` (disables PSR; not needed for me).
- **Minecraft's official launcher** crashed on start (uncaught C++ exception in `liblauncher.so`). **Prism Launcher** works. For the dGPU, set the instance's wrapper command to `/path/to/gpu-run -d`.

## Not in this repo

These live in each app's own files and are set by hand on a new machine:

- **kitty window position:** a KWin window rule with `placement=Centered` for class `kitty` (Wayland apps cannot place themselves). KDE rewrites the rules file, so it stays out of the repo.
- **Proton VPN split tunneling ("include" mode):** the system DNS becomes the VPN's `10.2.0.1` and apps outside the VPN cannot reach it. Set Settings → Advanced → Custom DNS to `1.1.1.1`, `9.9.9.9`.
- **SSH keys:** `~/.ssh/` is intentionally not here. A private key must never be committed.

## Personal dotfiles

| Path | What it does |
|---|---|
| `kitty/.config/kitty/kitty.conf` | JetBrainsMono Nerd Font, Catppuccin Mocha, transparency and blur, fixed 108×34 window |
| `fish/.config/fish/config.fish` | pure prompt, random pokemon on start |

They are in [GNU Stow](https://www.gnu.org/software/stow/) layout. `cihaza-ozel/` ("device-specific") is not.

Files under `/etc` and `/usr/local` are **copies**, not links: after you edit the source file, run the matching `sudo install ...` command again.

## License

[MIT](LICENSE). Use it, change it, share it. No warranty: you run these files on your own system at your own risk, and some of them run as root.
