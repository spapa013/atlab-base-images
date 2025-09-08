# Overview

This repository hosts multiple Docker images, each defined under the `images/` directory.

GitHub Actions workflows automatically **build, validate, and publish** images to [GitHub Container Registry (GHCR)](https://ghcr.io).

```bash
├── build-defaults.json                   # repo-wide build defaults
├── images/                               # hosts all image subdirectories
│   ├── python/scientific/Dockerfile      # builds -> python-scientific
│   ├── python/scientific-gpu/Dockerfile  # builds -> python-scientific-gpu
│   └── ...
└── .github/
    ├── workflows/
    │   ├── build-images.yml              # orchestrator (discover -> matrix -> call reusable)
    │   └── _build-image.yml              # reusable per-image workflow steps
    └── scripts/                          # helper scripts used by workflows
```

---

## Image naming

- The **image name** is inferred from its path under `images/`, with `/` replaced by `-`.
  - `images/python/scientific/Dockerfile` -> `python-scientific`
  - `images/python/scientific-gpu/Dockerfile` -> `python-scientific-gpu`
- You can optionally **override** the inferred name in a per-image `build.json` via `image_name`.

### Branch-scoped package names

Packages live under `ghcr.io/<owner>/<repo>/…`.

- **Default branch** (e.g., `main`):  
  `ghcr.io/<owner>/<repo>/<image_name>`
- **Other branches**:  
  `ghcr.io/<owner>/<repo>/<image_name>-br-<sanitized-branch>`

> Branches get their **own package namespace**. This means a branch can safely publish its own tags (including `latest`) without affecting the default branch package.

---

## Build configuration

### Repo-wide defaults (`build-defaults.json`)

Default build parameters:

| Key              | Type            | Default             | Description |
|------------------|-----------------|---------------------|-------------|
| `image_name`     | string \| null  | `null`              | Override the inferred image name (normally `null`). |
| `platforms`      | list \| string  | `["linux/amd64"]`   | Platform(s) to build (e.g., `"linux/amd64,linux/arm64"`). |
| `rebuild_policy` | string          | `"project"`         | What triggers a rebuild: `project` (any file in the directory) or `file` (Dockerfile only). |
| `hidden`         | boolean         | `false`             | If `true`, the image is **skipped** entirely by CI. (Already published images remain available on GHCR.) |
| `version`        | string \| null  | `null`              | Optional semantic/app version for this image. When changed, CI also publishes a version tag and `latest` (see below). |

### Per-image overrides (`images/**/build.json`)

Place a `build.json` alongside the Dockerfile to override defaults for that image only.

```jsonc
{
  "image_name": "your-desired-name",           // optional: override inferred name
  "platforms": ["linux/amd64", "linux/arm64"], // optional: multi-arch build
  "rebuild_policy": "file",                     // optional: rebuild only if Dockerfile changes
  "hidden": false,                              // optional: skip this image if true
  "version": "v1.2.3"                           // optional: publish :v1.2.3 + :latest on change
}
```

---

## Workflow behavior

We use two workflows: an **orchestrator** (`build-images.yml`) that discovers images and fans out a matrix, and a **reusable** workflow (`_build-image.yml`) that performs the per-image steps.

### Triggers

- **Pushes** (all branches)
- **Pull requests** (validate only, **no push**)
- **Manual dispatch** (from the Actions tab)

### Change detection

Per-image rebuilds are triggered according to `rebuild_policy`:

- `project`: rebuild if **any file** inside the image directory changed.
- `file`: rebuild only if the **Dockerfile** changed.

If CI can’t determine a base commit (e.g., first commit / new branch), it rebuilds.

### Tagging rules

For each image that rebuilds:

- Always publish an immutable **commit tag**: `sha-<shortSHA>`.
- Always publish a **lifecycle tag**:
  - Default branch package: `edge`
  - Branch-scoped package: `edge` (applies within that branch’s package)
- **Versioning (optional):** if `version` in `build.json` is present and **changed** since the base commit:
  - Also publish `:<version>` (immutable)
  - And update `:latest` (within that package namespace)

> Because branch packages are separate (suffix `-br-<branch>`), a branch can have its own `:latest` without impacting the default-branch package.

### PR validation

On pull requests, we **build only** (no registry push). By default we validate for `linux/amd64` for speed.

---

## Adding a new image

1. Create a directory under `images/` and add a Dockerfile:
   ```bash
   images/myapp/base/Dockerfile
   ```
2. (Optional) Add a `build.json` to override defaults and/or set a version:
   ```bash
   images/myapp/base/build.json
   ```
3. Commit & push.

**What happens:**

- **PRs**: the image is built for validation (no push).
- **Default branch pushes**: the image is published as  
  - `ghcr.io/<owner>/<repo>/myapp-base:sha-<shortSHA>`  
  - `ghcr.io/<owner>/<repo>/myapp-base:edge`  
  - If `version` changed: `:vX.Y.Z` and `:latest`
- **Other branches**: the image is published under a **branch-scoped package**, e.g.:  
  - `ghcr.io/<owner>/<repo>/myapp-base-br-feature-foo:sha-<shortSHA>`  
  - `ghcr.io/<owner>/<repo>/myapp-base-br-feature-foo:edge`  
  - If `version` changed: `:vX.Y.Z` and `:latest` (scoped to that branch package)

---

## Scripts & internals (for maintainers)

The reusable workflow calls small scripts in `.github/scripts/`:

- `discover_images.py` — emits the build matrix from `images/**/Dockerfile` and `build.json` overrides.
- `pick_base.sh` — selects the comparison base commit (PR base, previous push, or none).
- `check_for_changes.sh` — computes `changed=true|false` per `rebuild_policy`.
- `build_for_pr.sh` — local build (no push) for PR validation.
- `derive_image.sh` — derives the fully qualified package name, branch-scoped if needed.
- `detect_version.sh` — reads current/previous `version` from `build.json` and flags changes.
- `guard_version.sh` — prevents overwriting an existing `:<version>` tag.
- `build_and_push.sh` — single `buildx` invocation with all applicable tags and GHA cache.

---

## FAQ

- **What does `hidden: true` do?**  
  It **skips building** that image in CI. It does **not** delete or hide a package already on GHCR.

- **Why branch-scoped packages?**  
  To avoid tag collisions and confusion. A branch can publish its own `:edge`, `:latest`, and `:vX.Y.Z` without affecting the default branch’s package.

- **Do we need a separate release workflow?**  
  No. Versioning is **per image** via `build.json: "version"`. When you bump it, CI publishes `:<version>` and rolls `:latest` for that package automatically.

---
