# ArchPackages pacman repository

A small pacman repository built from the ArchPackages forks by GitHub Actions
and published to GitHub Pages.

## Packages

- `libwebsockets` 5.0.0 — required by Seafile
- `seafile` 9.0.22
- `seafile-client` 9.0.22
- `brother-mfc-l3760cdw` 3.5.1
- `brscan5` 1.7.0
- `brscan-skey` 0.3.5

## Install

Add this to `/etc/pacman.conf`, **before** `[extra]` so the packaged
libwebsockets 5.0.0 takes precedence over Arch's 4.5.8:

```ini
[archpackages]
Server = https://archpackages.github.io/archrepo/$arch
SigLevel = Optional TrustAll
```

Then:

```bash
sudo pacman -Syu
sudo pacman -S seafile seafile-client
# optional printer/scanner packages:
sudo pacman -S brother-mfc-l3760cdw brscan5 brscan-skey
```

The repository is unsigned, hence `SigLevel = Optional TrustAll`. It is built
from source in an `archlinux:base-devel` container on every run; packages are
not signed.

## How it works

- `.github/workflows/build.yml` checks out the package repos, builds in an
  Arch Linux container on an Ubuntu runner, generates the pacman database with
  `repo-add`, and deploys `repo/` through GitHub Pages.
- `build.sh` contains the container-side build: dependency-ordered builds,
  local package installation, and repository generation.
- Unsigned packages are acceptable for a personal repository; add GPG signing
  later if the repository is shared more widely.

Package sources live in the sibling ArchPackages repos:

- https://github.com/ArchPackages/libwebsockets
- https://github.com/ArchPackages/seafile
- https://github.com/ArchPackages/seafile-client
- https://github.com/ArchPackages/brother
