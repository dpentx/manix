#!/usr/bin/env bash
# Sets up manix on a fresh Manjaro: pacman packages, Nix, home-manager, optional One UI login screen.
#   ./scripts/manjaro-install.sh              # everything except the login screen
#   ./scripts/manjaro-install.sh --greetd     # also replace SDDM with greetd + the One UI greeter
#   ./scripts/manjaro-install.sh --greetd-only  # only the greeter part (used by CI)
# Safe to run again. Run it as your normal user (it uses sudo where needed).
set -euo pipefail

[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user, not root." >&2; exit 1; }
command -v pacman >/dev/null || { echo "This script is for Manjaro/Arch." >&2; exit 1; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GREETD=0; ONLY=0
case "${1:-}" in --greetd) GREETD=1 ;; --greetd-only) GREETD=1; ONLY=1 ;; esac
# Branch of github:dpentx/qs-niri used for the shell (flake input) and for the greeter checkout.
QS_BRANCH="${QS_BRANCH:-oneui8-adapt}"

say() { printf '\n==> %s\n' "$*"; }

if [ "$ONLY" -eq 0 ]; then
# Nix already installed (e.g. the official multi-user installer)? Then pacman's nix is skipped,
# so the two do not fight over /nix, nix-daemon and the nixbld users.
NIX_PROFILE_BIN=/nix/var/nix/profiles/default/bin
HAVE_NIX=0
if [ -x "$NIX_PROFILE_BIN/nix" ] || command -v nix >/dev/null; then
  HAVE_NIX=1
  case ":$PATH:" in *":$NIX_PROFILE_BIN:"*) ;; *) export PATH="$NIX_PROFILE_BIN:$PATH" ;; esac
  echo "Existing Nix found ($(command -v nix)); skipping the pacman nix package."
fi

say "Packages (pacman)"
PKGS=(git niri xwayland-satellite xdg-desktop-portal-gtk xdg-desktop-portal-gnome polkit-gnome)
[ "$HAVE_NIX" -eq 1 ] || PKGS+=(nix)
sudo pacman -S --needed --noconfirm "${PKGS[@]}"

say "Nix daemon"
sudo systemctl enable --now nix-daemon.socket
[ "$HAVE_NIX" -eq 1 ] || sudo usermod -aG nix-users "$USER"
touch_conf() { grep -qxF "$1" /etc/nix/nix.conf 2>/dev/null || echo "$1" | sudo tee -a /etc/nix/nix.conf >/dev/null; }
touch_conf 'experimental-features = nix-command flakes'
touch_conf 'trusted-users = root @wheel'
sudo systemctl restart nix-daemon.service

say "Login name in manjaro/home.nix -> $USER"
sed -i "s/home.username = \"[^\"]*\"/home.username = \"$USER\"/" "$REPO/manjaro/home.nix"

# Flakes in a git checkout only see tracked files.
if git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$REPO" add -N manjaro/home.nix 2>/dev/null || true
fi

say "home-manager switch (first run downloads a lot)"
# --accept-flake-config must come before home-manager: `nix run` itself builds home-manager and needs the cache.
HM_CMD="cd '$REPO' && nix run --accept-flake-config home-manager -- switch --flake .#manjaro -b backup --override-input qs-niri github:dpentx/qs-niri/$QS_BRANCH"
if [ "$HAVE_NIX" -eq 1 ]; then
  bash -c "$HM_CMD"
else
  # sg: the nix-users group is not active in this shell until the next login
  sg nix-users -c "$HM_CMD"
fi
fi

if [ "$GREETD" -eq 1 ]; then
  say "One UI login screen (greetd)"
  sudo pacman -S --needed --noconfirm greetd cage
  # The greeter runs as the "greeter" user with a bare PATH: it cannot see the Nix quickshell in your
  # home (and that one is nixGL-wrapped for your session anyway). It needs the pacman/AUR build.
  if [ ! -x /usr/bin/quickshell ]; then
    command -v yay >/dev/null || command -v paru >/dev/null || { echo "Install an AUR helper (yay) first: quickshell is AUR-only." >&2; exit 1; }
    "$(command -v yay || command -v paru)" -S --needed --noconfirm quickshell
  fi
  [ -x /usr/bin/quickshell ] || { echo "/usr/bin/quickshell is missing after the install; the greeter cannot start." >&2; exit 1; }
  QS=/opt/qs-niri
  if [ -d "$QS/.git" ]; then
    sudo git -C "$QS" fetch -q origin "$QS_BRANCH" && sudo git -C "$QS" checkout -q -B "$QS_BRANCH" FETCH_HEAD
  else
    sudo git clone -q -b "$QS_BRANCH" https://github.com/dpentx/qs-niri "$QS"
  fi
  sudo chmod -R a+rX "$QS"
  sudo tee /etc/greetd/config.toml >/dev/null <<TOML
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "/usr/bin/cage -s -d -- /usr/bin/env QS_GREETER_USER=$USER QS_GREETER_CMD=niri-session /usr/bin/quickshell -p $QS/greeter.qml"
TOML
  sudo systemctl disable sddm 2>/dev/null || true
  sudo systemctl enable greetd
  echo "Greeter enabled for the next boot. If it fails: Ctrl+Alt+F3, then 'sudo systemctl enable sddm'."
fi

say "Done"
echo "Log out and in (or reboot), pick the niri session. Later changes: run 'rebuild' in a terminal."
