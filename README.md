# ArchPackages pacman repository

A small, signed pacman repository for Arch Linux (x86_64), built from the
ArchPackages package forks (Seafile, Brother, Mattermost Desktop, the Electron
45 runtime, Viber and Signed) by GitHub Actions and published on GitHub Pages.

- **Repository URL:** `https://archpackages.github.io/archrepo/$arch`
- **Source:** <https://github.com/ArchPackages/archrepo>
- **Builds:** <https://github.com/ArchPackages/archrepo/actions>

## Installation

### 1. Add the repository

Pacman does not auto-load files from `/etc/pacman.d`, so it needs one `Include`
line in `/etc/pacman.conf`. Keep the repository definition itself in
`/etc/pacman.d/archpackages.conf`:

```ini
[archpackages]
Server = https://archpackages.github.io/archrepo/$arch
SigLevel = Required DatabaseOptional
```

Then add this line to `/etc/pacman.conf`, **above `[extra]`**:

```ini
Include = /etc/pacman.d/archpackages.conf
```

The order matters: this repository provides `libwebsockets` 5.0.0, which must
take precedence over the 4.5.8 package in Arch's `[extra]`.

`/etc/pacman.conf` is owned by the `pacman` package and may be replaced or
produce a `.pacnew` on updates. Keeping the repository in
`/etc/pacman.d/archpackages.conf` means only the one-line `Include` ever needs
merging; the `[omarchy]`, `[core]`, `[extra]` and `[multilib]` sections remain
untouched.

### 2. Import and trust the signing key

```bash
curl -O https://archpackages.github.io/archrepo/archpackages.asc

sudo pacman-key --add archpackages.asc

FPR=$(gpg --show-keys --with-colons archpackages.asc |
      awk -F: '/^fpr:/ {print $10; exit}')
sudo pacman-key --lsign-key "$FPR"
```

The fingerprint is also shown on
<https://archpackages.github.io/archrepo/>. `gpg` is provided by the `gnupg`
package, which is normally installed on Arch.

### 3. Update and install

```bash
sudo pacman -Syu
sudo pacman -S seafile seafile-client
```

`libsearpc`, a dependency of Seafile, is also provided by this repository and
is installed automatically.

For the Brother printer and scanner:

```bash
sudo pacman -S brother-mfc-l3760cdw brscan5 brscan-skey
```

For Mattermost Desktop:

```bash
sudo pacman -S mattermost-desktop
```

Mattermost Desktop 6.4.0 uses Electron 45. Arch does not package `electron45`
yet, so this repository provides the prebuilt `electron45-bin` runtime, which
is installed automatically as `mattermost-desktop`'s dependency.

For Viber:

```bash
sudo pacman -S viber
```

Viber is repackaged from the vendor's official Debian build. It is proprietary
software; review Viber's terms before redistributing it.

For Signed:

```bash
sudo pacman -S signed
```

Signed's recipe comes from Omarchy's package repository but builds the
<https://github.com/MPavleski/signed> fork rather than `omacom/signed`.

If pacman cannot find the `archpackages` database, refresh the sync databases
once:

```bash
sudo pacman -Syy
```

### 4. Verify

```bash
pacman -Q seafile seafile-client libwebsockets libsearpc
pacman -Q mattermost-desktop electron45-bin viber signed
```

Expected versions:

```
libwebsockets 5.0.0-1
libsearpc 2:3.3.0-5
seafile 9.0.22-2
seafile-client 9.0.22-1
mattermost-desktop 6.4.0-2
electron45-bin 45.3.4-1
viber 29.4.0.7-1
signed 0.4.0-1
```

Restart the Seafile applet after installing or upgrading it.

## Available packages

| Package | Version | Notes |
|---|---|---|
| `libwebsockets` | 5.0.0-1 | Required by Seafile; shadows Arch's 4.5.8 |
| `libsearpc` | 2:3.3.0-5 | Seafile RPC dependency; ArchPackages fork |
| `seafile` | 9.0.22-2 | Sync daemon |
| `seafile-client` | 9.0.22-1 | Qt 6 desktop applet |
| `brother-mfc-l3760cdw` | 3.5.1-4 | LPR/CUPS printer drivers |
| `brscan5` | 1.7.0_0-1 | SANE scanner driver |
| `brscan-skey` | 0.3.5_0-1 | Scanner S-KEY tool |
| `electron45-bin` | 45.3.4-1 | Electron 45 runtime for Mattermost; provides `electron45` |
| `mattermost-desktop` | 6.4.0-2 | Mattermost Desktop client |
| `viber` | 29.4.0.7-1 | Proprietary Viber desktop client |
| `signed` | 0.4.0-1 | PDF signing app; built from the `MPavleski/signed` fork |

The repository is x86_64 only.

## Signing

Packages and the pacman database are signed by a dedicated Ed25519 repository
key. The public key is published as
<https://archpackages.github.io/archrepo/archpackages.asc>, and its fingerprint
is shown on the repository index page.

The repository snippet uses `SigLevel = Required DatabaseOptional`, so package
signatures are required and the database signature is verified when present.
Do not replace this with `Optional TrustAll`.

The signing key is kept in the GitHub `signing` environment. If the key is ever
compromised or rotated, the old key will be revoked and a new public key
published.

## Updating the repository

The repository is built manually or by the weekly schedule. To rebuild it now:

```bash
gh workflow run build.yml -R ArchPackages/archrepo
```

or use **Actions → build-pacman-repo → Run workflow** on GitHub. Pushing to
`archrepo/main` also triggers a build.

## How it works

- `.github/workflows/build.yml` has three stages:
  - `build`: checks out the package repos and runs `build.sh` inside an
    `archlinux:base-devel` Docker container, producing unsigned packages.
  - `sign`: runs in the GitHub `signing` environment, imports the private key
    in a throwaway container, signs every package and the pacman database,
    exports the public key, and generates the index page.
  - `deploy`: publishes `repo/` through GitHub Pages.
- Build order is `libwebsockets` → `libsearpc` → `seafile` →
  `seafile-client` → Brother packages → `electron45-bin` →
  `mattermost-desktop` → `viber` → `signed`, installing local packages before
  their dependents.
- Debug packages are excluded from the published repository.

Package sources:

- <https://github.com/ArchPackages/libwebsockets>
- <https://github.com/ArchPackages/seafile>
- <https://github.com/ArchPackages/seafile-client>
- <https://github.com/ArchPackages/brother>
- <https://github.com/ArchPackages/libsearpc>
  (forked from <https://aur.archlinux.org/packages/libsearpc>)
- <https://github.com/ArchPackages/electron45-bin>
  (forked from <https://aur.archlinux.org/packages/electron45-bin>)
- <https://github.com/ArchPackages/mattermost-desktop>
  (forked from <https://archlinux.org/packages/extra/x86_64/mattermost-desktop/>)
- <https://github.com/ArchPackages/viber>
  (forked from <https://aur.archlinux.org/packages/viber>)
- <https://github.com/ArchPackages/signed>
  (recipe forked from
  <https://github.com/omacom/omarchy-pkgs/tree/master/pkgbuilds/signed>;
  source is <https://github.com/MPavleski/signed>)

## Troubleshooting

### `Maximum file size exceeded`

Pacman limits a download to the package size recorded in the synced database.
Immediately after a repository rebuild, GitHub Pages can briefly serve a cached
database and a package file from different builds. If the package file is
larger than the size in the database, libcurl stops with:

```
Maximum file size exceeded
```

Refresh the sync database and retry:

```bash
sudo rm -f /var/lib/pacman/sync/archpackages.db*
sudo pacman -Syy
sudo pacman -Syu
```

If it persists, wait a few minutes for the Pages CDN cache to expire and repeat.
Removing the sync database is safe; installed packages and the trusted key are
unaffected.
