# Overview

This repository hosts multiple Docker images, each defined under the `images/` directory.

GitHub Actions workflows automatically **build, validate, and publish** images to [GitHub Container Registry (GHCR)](https://ghcr.io).

```bash
├── build-defaults.json                   # repo-wide build defaults
├── images/                               # hosts all image subdirectories
│   ├── python/scientific/Dockerfile      # builds → python-scientific
│   ├── python/scientific-gpu/Dockerfile  # builds → python-scientific-gpu
│   └── ...
└── .github/
    ├── workflows/
    │   ├── build-images.yml              # CI builds on push / PR / manual
    │   └── release-images.yml            # builds on release tag
    └── scripts/                          # helper scripts
```

# Image naming

- The image name is inferred from its path under `images/`, with `/` replaced by `-`.
- Example:
  - `images/python/scientific/Dockerfile` → `python-scientific`
  - `images/python/scientific-gpu/Dockerfile` → `python-scientific-gpu`
- The image name can optionally be **overridden** in a `build.json`.

# Build configuration

## Repo-wide defaults

Default build parameters are specified in `build-defaults.json`:

| Key              | Type            | Default           | Description |
|------------------|-----------------|-------------------|-------------|
| `image_name`     | string \| null  | `null`            | Override the inferred image name. Normally left `null`. |
| `platforms`      | list \| string  | `["linux/amd64"]` | Platform(s) to build. |
| `rebuild_policy` | string          | `"project"`       | What triggers a rebuild: `project` (any file in dir) or `file` (Dockerfile only). |
| `hidden`         | boolean         | `false`           | If `true`, the image is skipped entirely. |

## Per-image overrides

Each image may override defaults with a `build.json` placed alongside its Dockerfile.

Example:

```jsonc
{
  "image_name": "your-desired-name-here",        // optional, override inferred name
  "platforms": ["linux/amd64", "linux/arm64"],   // multiple platforms
  "rebuild_policy": "file",                      // rebuild only if Dockerfile changes
  "hidden": false                                // optional, override visibility
}
```

# Build workflows

## Build workflow (`build-images.yml`)

**Triggers:**
- Pushes (all branches)
- Pull requests (validate only, no push)
- Manual dispatch

**Behavior:**
- Detects which images changed (based on `rebuild_policy`).
- Builds changed, non-hidden images.
- Tags:
  - Always: `sha-<shortSHA>` (immutable commit SHA tag)
  - Default branch: `edge`
  - Other branches: sanitized branch name

## Release workflow (`release-images.yml`)

**Triggers:**
- Publishing a GitHub Release
- Tag push (`v*`)
- Manual dispatch with version input

**Behavior:**
- Builds **all non-hidden images** at the tagged commit.
- Tags:
  - `vX.Y.Z` (semantic version, immutable)
  - `latest`
  - `sha-<shortSHA>`

# Adding a new image

1. Create a new directory under `images/`:
   ```bash
   images/myapp/base/
   ```
2. Add a Dockerfile:
   ```bash
   images/myapp/base/Dockerfile
   ```
3. (Optional) Add a `build.json` if you need to override defaults:
   ```bash
   images/myapp/base/build.json
   ```
4. Commit & push.

**Outcomes:**
- On PR: builds to validate only (no push).
- On merge to main: published as
  - `ghcr.io/<owner>/<repo>/myapp-base:sha-<shortSHA>`
  - `ghcr.io/<owner>/<repo>/myapp-base:edge`
- On other branches: published as
  - `ghcr.io/<owner>/<repo>/myapp-base:sha-<shortSHA>`
  - `ghcr.io/<owner>/<repo>/myapp-base:<branch>`
- On release: published as
  - `ghcr.io/<owner>/<repo>/myapp-base:sha-<shortSHA>`
  - `ghcr.io/<owner>/<repo>/myapp-base:vX.Y.Z`
  - `ghcr.io/<owner>/<repo>/myapp-base:latest`