#!/usr/bin/env bash
set -euo pipefail

WORK=/work
OUT="$WORK/out"
REPO="$WORK/repo"

if [[ ! -f /etc/arch-release ]]; then
  echo "error: build.sh must run inside an Arch Linux container" >&2
  exit 1
fi

echo '==> Updating Arch container'
if ! pacman -Syu --noconfirm --needed; then
  pacman-key --init
  pacman-key --populate archlinux
  pacman -Syu --noconfirm --needed
fi
pacman -S --noconfirm --needed base-devel git sudo

if ! id builder >/dev/null 2>&1; then
  useradd -m builder
fi
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
chmod 440 /etc/sudoers.d/builder

cd "$WORK"
mkdir -p "$OUT" "$REPO/x86_64"
chown -R builder:builder "$WORK"

build_pkg() {
  local dir="$1"
  echo "==> Building $dir"
  ( cd "$WORK/$dir" && \
    sudo -u builder -H env PKGDEST="$OUT" \
      makepkg -f -s --noconfirm --noprogressbar )
}

install_built() {
  local pattern="$1"
  local files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(find "$OUT" -maxdepth 1 -type f -name "$pattern" ! -name '*-debug-*')
  if ((${#files[@]} == 0)); then
    echo "error: no built package matched $pattern" >&2
    exit 1
  fi
  pacman -U --noconfirm "${files[@]}"
}

# Dependency order matters: libsearpc and libwebsockets must be installed
# before seafile, seafile-client needs local seafile, and brscan-skey needs
# local brscan5.
build_pkg src/libwebsockets
install_built 'libwebsockets-*.pkg.tar.zst'

build_pkg src/libsearpc
install_built 'libsearpc-*.pkg.tar.zst'

build_pkg src/seafile
install_built 'seafile-9*.pkg.tar.zst'

build_pkg src/seafile-client
build_pkg src/brother/printer
build_pkg src/brother/scanner
install_built 'brscan5-*.pkg.tar.zst'
build_pkg src/brother/scanner/brscan-skey

echo '==> Collecting packages'
find "$OUT" -maxdepth 1 -type f -name '*.pkg.tar.zst' \
  ! -name '*-debug-*' -exec cp -f {} "$REPO/x86_64/" \;

echo '==> Staging packages'
touch "$REPO/.nojekyll"
chmod -R a+rX "$REPO"

echo '==> Done'
find "$REPO" -maxdepth 2 -type f -printf '%P\n' | sort
