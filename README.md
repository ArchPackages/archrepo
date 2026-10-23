# ArchPackages pacman repository

A small, unsigned pacman repository for Arch Linux (x86_64), built from the
ArchPackages package forks by GitHub Actions and published on GitHub Pages.

- **Repository URL:** `https://archpackages.github.io/archrepo/$arch`
- **Source:** <https://github.com/ArchPackages/archrepo>
- **Builds:** <https://github.com/ArchPackages/archrepo/actions>

## Installation

### 1. Add the repository

Edit `/etc/pacman.conf` and add this section **above `[extra]`**:

```ini
[archpackages]
Server = https://archpackages.github.io/archrepo/$arch
SigLevel = Optional TrustAll
```

The order matters: this repository provides `libwebsockets` 5.0.0, which must
take precedence over the 4.5.8 package in Arch's `[extra]`.

### 2. Update and install

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

If pacman cannot find the `archpackages` database, refresh the sync databases
once:

```bash
sudo pacman -Syy
```

### 3. Verify

```bash
pacman -Q seafile seafile-client libwebsockets libsearpc
```

Expected versions:

```
libwebsockets 5.0.0-1
libsearpc 2:3.3.0-5
seafile 9.0.22-2
seafile-client 9.0.22-1
```

Restart the Seafile applet after installing or upgrading it.

## Available packages

| Package | Version | Notes |
|---|---|---|
| `libwebsockets` | 5.0.0-1 | Required by Seafile; shadows Arch's 4.5.8 |
| `libsearpc` | 2:3.3.0-5 | Seafile RPC dependency, built from AUR |
| `seafile` | 9.0.22-2 | Sync daemon |
| `seafile-client` | 9.0.22-1 | Qt 6 desktop applet |
| `brother-mfc-l3760cdw` | 3.5.1-4 | LPR/CUPS printer drivers |
| `brscan5` | 1.7.0_0-1 | SANE scanner driver |
| `brscan-skey` | 0.3.5_0-1 | Scanner S-KEY tool |

The repository is x86_64 only.

## Signing

Packages are **unsigned**, hence `SigLevel = Optional TrustAll`. Only add this
repository if you trust its GitHub Actions builds and the package sources
listed below. GPG signing can be added later.

## Updating the repository

The repository is built manually or by the weekly schedule. To rebuild it now:

```bash
gh workflow run build.yml -R ArchPackages/archrepo
```

or use **Actions → build-pacman-repo → Run workflow** on GitHub. Pushing to
`archrepo/main` also triggers a build.

## How it works

- `.github/workflows/build.yml` checks out the package repos, runs
  `build.sh` inside an `archlinux:base-devel` Docker container, generates the
  pacman database with `repo-add`, and deploys `repo/` through GitHub Pages.
- Build order is `libwebsockets` → `libsearpc` → `seafile` →
  `seafile-client` → Brother packages, installing local packages before their
  dependents.
- Debug packages are excluded from the published repository.

Package sources:

- <https://github.com/ArchPackages/libwebsockets>
- <https://github.com/ArchPackages/seafile>
- <https://github.com/ArchPackages/seafile-client>
- <https://github.com/ArchPackages/brother>
- `libsearpc` is built from the AUR: <https://aur.archlinux.org/packages/libsearpc>
