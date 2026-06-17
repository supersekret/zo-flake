# Zo Nix Flake

This flake packages the upstream Linux Debian release of Zo `1.5.6` as a Nix app.

## What it does

- Downloads the official `Zo-1.5.6-amd64.deb`
- Extracts the Electron app bundle from `/opt/Zo`
- Auto-patches the bundled ELF binaries for Nix
- Installs a `zo` launcher plus desktop entry and icon

## Usage

```bash
cd /home/workspace/zo-flake
nix build
./result/bin/zo
```

Or run it directly:

```bash
nix run
```

## Install directly from GitHub

```bash
nix run github:codegod100/zo-flake
```

Or install it into your profile:

```bash
nix profile install github:codegod100/zo-flake
```

## CI and Cachix

The repository includes a GitHub Actions workflow that:

- installs Nix
- builds `.#zo`
- pushes build outputs to Cachix when both of these are configured in the GitHub repo

Required GitHub repo settings:

- Actions variable: `CACHIX_CACHE`
- Actions secret: `CACHIX_API_KEY`

Once those are set, the workflow will use:

```bash
cachix use <your-cache-name>
```

## Notes

- This is currently targeted at `x86_64-linux`.
- If Chromium sandboxing needs extra flags on your machine, set them through `NIX_ZO_FLAGS`, for example:

```bash
NIX_ZO_FLAGS="--disable-setuid-sandbox" nix run
```
