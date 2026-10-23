#!/usr/bin/env bash
set -euo pipefail

REPO=/work/repo

if [[ ! -f /etc/arch-release ]]; then
  echo "error: sign.sh must run inside an Arch Linux container" >&2
  exit 1
fi

if [[ -z "${GPG_PRIVATE_KEY:-}" || -z "${GPG_PASSPHRASE:-}" || -z "${GPG_KEY_ID:-}" ]]; then
  echo "error: GPG_PRIVATE_KEY, GPG_PASSPHRASE and GPG_KEY_ID must be set" >&2
  exit 1
fi

if [[ ! -d "$REPO/x86_64" ]]; then
  echo "error: $REPO/x86_64 is missing; download the build artifact first" >&2
  exit 1
fi

echo '==> Preparing signing environment'
pacman -Syu --noconfirm --needed
pacman -S --noconfirm --needed gnupg

GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
chmod 700 "$GNUPGHOME"
trap 'rm -rf "$GNUPGHOME"' EXIT

printf '%s\n' "$GPG_PRIVATE_KEY" | gpg --batch --import

if ! gpg --list-secret-keys --with-colons "$GPG_KEY_ID" >/dev/null 2>&1; then
  echo "error: signing key $GPG_KEY_ID was not imported" >&2
  exit 1
fi

FPR="$(gpg --list-secret-keys --with-colons "$GPG_KEY_ID" \
  | awk -F: '/^fpr:/ {print $10; exit}')"
if [[ -z "$FPR" ]]; then
  echo "error: could not determine signing key fingerprint" >&2
  exit 1
fi

sign_file() {
  gpg --batch --yes --pinentry-mode loopback \
    --passphrase "$GPG_PASSPHRASE" \
    --local-user "$FPR" \
    --detach-sign --output "$1.sig" "$1"
}

echo '==> Signing packages'
shopt -s nullglob
packages=("$REPO"/x86_64/*.pkg.tar.zst)
if ((${#packages[@]} == 0)); then
  echo "error: no packages found to sign" >&2
  exit 1
fi
for pkg in "${packages[@]}"; do
  [[ "$pkg" == *-debug-* ]] && continue
  echo "    $(basename "$pkg")"
  sign_file "$pkg"
done

echo '==> Generating pacman database'
cd "$REPO/x86_64"
rm -f archpackages.db archpackages.db.tar.gz \
      archpackages.db.sig archpackages.db.tar.gz.sig \
      archpackages.files archpackages.files.tar.gz \
      archpackages.files.sig archpackages.files.tar.gz.sig
repo-add archpackages.db.tar.gz ./*.pkg.tar.zst

# GitHub Pages does not reliably serve symlinks, so publish real copies.
rm -f archpackages.db archpackages.files
cp -f archpackages.db.tar.gz archpackages.db
cp -f archpackages.files.tar.gz archpackages.files

echo '==> Signing database'
sign_file archpackages.db
sign_file archpackages.db.tar.gz
sign_file archpackages.files
sign_file archpackages.files.tar.gz

echo '==> Publishing public key'
gpg --armor --export "$FPR" > "$REPO/archpackages.asc"

# Fail closed if the public export is not exactly a public key.
if ! grep -q '^-----BEGIN PGP PUBLIC KEY BLOCK-----$' "$REPO/archpackages.asc" \
   || grep -q 'PRIVATE KEY' "$REPO/archpackages.asc"; then
  echo "error: refusing to publish a non-public key file" >&2
  exit 1
fi

CHECKHOME="$(mktemp -d)"
chmod 700 "$CHECKHOME"
if ! gpg --homedir "$CHECKHOME" --batch --import "$REPO/archpackages.asc" >/dev/null 2>&1; then
  echo "error: published public key could not be imported" >&2
  rm -rf "$CHECKHOME"
  exit 1
fi
if gpg --homedir "$CHECKHOME" --list-secret-keys --with-colons | grep -q '^sec:'; then
  echo "error: published key file contains secret key material" >&2
  rm -rf "$CHECKHOME"
  exit 1
fi
rm -rf "$CHECKHOME"

echo '==> Writing index page'
cat > "$REPO/index.html" <<HTML
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>ArchPackages repository</title></head>
<body>
<h1>ArchPackages pacman repository</h1>
<p>Add this to <code>/etc/pacman.conf</code>, before <code>[extra]</code>:</p>
<pre>[archpackages]
Server = https://archpackages.github.io/archrepo/\$arch
SigLevel = Required DatabaseOptional</pre>
<p>Import and locally trust the repository key:</p>
<pre>curl -O https://archpackages.github.io/archrepo/archpackages.asc
sudo pacman-key --add archpackages.asc
sudo pacman-key --lsign-key $FPR</pre>
<p>Key fingerprint: <code>$FPR</code></p>
<p>Then run <code>sudo pacman -Syu</code>.</p>
<p>Packages: libwebsockets 5.0.0, libsearpc, seafile, seafile-client,
brother-mfc-l3760cdw, brscan5, brscan-skey.</p>
<p>Built from source by GitHub Actions from the
<a href="https://github.com/ArchPackages">ArchPackages</a> repos.</p>
</body>
</html>
HTML

touch "$REPO/.nojekyll"
chmod -R a+rX "$REPO"

echo '==> Done'
find "$REPO" -maxdepth 2 -type f -printf '%P\n' | sort
