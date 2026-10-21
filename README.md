not usable. i trying something, don't care.

## Manjaro (Nix + standalone home-manager)

Short version: `./scripts/manjaro-install.sh` (add `--greetd` for the One UI login screen). The manual steps follow.

NixOS is not needed. The compositor and login session stay on pacman; the user-level
setup (niri config, quickshell, kitty, zsh, GTK) comes from this flake.

```sh
# 1. System side (pacman)
sudo pacman -S --needed nix niri xdg-desktop-portal-gtk xdg-desktop-portal-gnome polkit-gnome xwayland-satellite
sudo systemctl enable --now nix-daemon.socket
sudo usermod -aG nix-users "$USER"
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
echo 'trusted-users = root @wheel' | sudo tee -a /etc/nix/nix.conf   # lets the flake use the cachix cache
# log out and in once

# 2. User side
git clone https://github.com/dpentx/manix && cd manix
nix run --accept-flake-config home-manager -- switch --flake .#manjaro -b backup --accept-flake-config
```

Then pick the "niri" session in the login screen. Afterwards `rebuild` re-applies the config.

Notes:
- `manjaro/home.nix` has `home.username = "asus"`; change it if the Manjaro login name differs.
- GPU: `nixGL` is set to `mesa` (Intel/AMD). NVIDIA needs the `nixGLNvidia` wrapper, which is evaluated impurely (`--impure`).
- Not carried over from the NixOS host: greetd, NVIDIA, Steam, zapret, QEMU and the Limine entry.
- Screen locking with PAM and GPU recording are untested on this host.

Layout: the NixOS host (`nixos/`, `home/home.nix`, `modules/`) and the Manjaro host (`manjaro/`) share nothing but `flake.nix`. The Manjaro host has its own copies of the niri, GTK, shell and terminal modules under `manjaro/modules/`; change them there.
