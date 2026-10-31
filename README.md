# ASUS TUF Gaming A16 (FA608UM) on Arch Linux

**English** | [Türkçe](README.tr.md)

Linux fixes for the **ASUS TUF Gaming A16 (FA608UM)** (Radeon 780M + RTX 5060), plus my kitty and fish setup.

> Tested only on FA608UM, Arch Linux, KDE Plasma 6 (Wayland). Read `install.sh` before running it: it uses `sudo`.

## Install

```bash
git clone https://github.com/Helyosfer/dotfiles.git ~/dotfiles
~/dotfiles/install.sh --hepsi
```

Then log out and back in. The script checks your laptop model and finds the GPU address by itself. Existing files are backed up, never deleted. Running it again is safe.

| Option | What it does |
|---|---|
| `--hepsi` | Everything (packages, configs, GPU, ASUS fixes) |
| `--hybrid-gpu` | GPU setup only |
| `--asus-tuf` | Brightness and keyboard RGB only |
| `--sadece-baglanti` | Only link configs, install nothing |
| `--zorla` | Skip the model check |

## What it fixes

| Problem | Fix |
|---|---|
| dGPU never sleeps (~15 W idle) | KWin uses only the iGPU. dGPU sleeps, idle drops to ~9 W |
| Games on the wrong GPU | `gpu-run` picks the GPU from the power profile |
| Screen dims itself after login | A service turns off the firmware auto brightness |
| Keyboard light is off after boot | A service sets the colour at boot and after sleep |
| `asusctl` can't control the keyboard | `klavye-rgb`, a small tool for this keyboard |

## Using it

**Run a program on a GPU**

```bash
gpu-run -d program    # dGPU (NVIDIA)
gpu-run -i program    # iGPU (AMD)
gpu-run program       # follows the power profile
```

Steam launch option for a game that needs the dGPU:

```
gpu-run -d %command%
```

**Keyboard colour** (the whole keyboard is one light, no per-key colours)

```bash
klavye-rgb sonraki    # next colour (bind to Fn+F4 in KDE shortcuts)
klavye-rgb renk 255 0 0
klavye-rgb kapat      # off
```

**Check that the dGPU sleeps.** Don't use `nvidia-smi`, it wakes the GPU:

```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status   # "suspended" = good
```

## Good to know

- The power profile is read when an app **starts**. Start Steam in Balanced or Power Saver, otherwise it keeps the dGPU awake.
- An external monitor on the dGPU ports won't work while KWin is pinned to the iGPU. Delete `~/.config/environment.d/kwin-gpu.conf` and log in again.
- Fan curves are not supported on this model in Linux, and `asusctl` does not support this keyboard, so it is not used.
- Black lines or flicker on the screen: turn VRR off with `kscreen-doctor output.eDP-1.vrrpolicy.never`.
- Battery charge limit works without extra tools: `echo 80 | sudo tee /sys/class/power_supply/BAT1/charge_control_end_threshold` (resets on reboot).

## Files

| Path | What |
|---|---|
| `install.sh` | The installer |
| `cihaza-ozel/hybrid-gpu/` | GPU setup (`gpu-run`, KWin, Steam launcher) |
| `cihaza-ozel/asus-tuf/` | Keyboard RGB and brightness services |
| `kitty/`, `fish/` | My terminal and shell config |

System files (`/etc`, `/usr/local`) are **copies**. After you edit a file here, run `install.sh` again.

Not in the repo on purpose: SSH keys, VPN settings, KDE window rules.

## License

[MIT](LICENSE). No warranty, and some files run as root: use at your own risk.
