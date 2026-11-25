# Using a private registry proxy

Some organisations require every dependency to flow through a private virtual
registry (JFrog Artifactory, Sonatype Nexus, or similar) instead of the public
internet. The proxy caches, scans, and audits what your machine downloads.

If that's your situation, configure your package managers to point at the proxy
**before** you run `./install.sh`. OmacOS itself has no registry settings. It
uses whatever npm, pip, uv, Go, Cargo, and Docker already read from your home
directory, so the config below is all that's needed.

If you don't work behind a registry proxy, skip this file and run the installer
normally.

## What OmacOS downloads, and what a proxy covers

| Install step | Pulls from | Proxy a virtual registry? |
| --- | --- | --- |
| Homebrew formulae and bottles | `ghcr.io`, `formulae.brew.sh` | Only if your org proxies Homebrew (see note below) |
| Language runtimes (mise: node, python, go, rust, uv) | nodejs.org, python-build-standalone, go.dev, static.rust-lang.org | No (downloaded by mise from upstream) |
| Python packages (uv, pip) | PyPI | Yes |
| Mason LSP servers | npm, PyPI, Go module proxy, GitHub Releases | npm/PyPI/Go yes; GitHub Releases direct |
| Global npm packages | npm registry | Yes |
| Go modules | Go module proxy | Yes |
| Rust crates | crates.io | Yes, if your org has a Cargo repo |
| Container images (Docker or Podman) | Docker Hub and other registries | Yes, if your repo proxies them (see below) |
| Homebrew install script, `claude.ai/install.sh`, TPM, Neovim Lazy plugins | `raw.githubusercontent.com`, `github.com`, `claude.ai` | No (plain git clone / curl over HTTPS) |

This guide covers the registries OmacOS pulls from: npm, PyPI (pip and uv), Go,
Cargo, and container images (Docker or Podman).

Homebrew, GitHub clones, and the `curl | bash` installers reach the public
internet directly. If your network blocks that too, you need an HTTP proxy or
Homebrew-specific settings (`HOMEBREW_API_DOMAIN`, `HOMEBREW_BOTTLE_DOMAIN`,
`HOMEBREW_ARTIFACT_DOMAIN`). Those are out of scope here. Ask your platform team.

## Before you start

Get these from your platform team:

- The proxy base URL, for example `https://<jfrog-host>/artifactory`.
- One virtual repository name per ecosystem you use (npm, PyPI, Go, Cargo,
  Docker). Names vary by org.
- A credential. JFrog calls it an identity token. Generate it from the web UI
  under your profile, or via your org's SSO flow.

Throughout this guide, replace the `<placeholders>` with your real values.

## Step 1: store your credential once

Most tools authenticate to the proxy with the same token. Two places hold it:

1. An environment variable, so npm can read it without writing the secret to a
   file.
2. `~/.netrc`, which pip, uv, Go, and Cargo read for HTTP auth.

Add the environment variable to your shell profile (`~/.zshrc` or `~/.zprofile`):

```bash
export REGISTRY_TOKEN="<your-identity-token>"
```

Add the matching `~/.netrc` entry, then lock down its permissions:

```bash
cat >> ~/.netrc <<EOF
machine <jfrog-host>
  login <your-username>
  password <your-identity-token>
EOF
chmod 600 ~/.netrc
```

Some setups use a token as both login and password, others use your email as the
login. Confirm the pair with your platform team.

## Step 2: configure each ecosystem

Do only the ones you use. OmacOS uses all of them except Cargo by default, and
Cargo only if you write Rust.

### npm

Write `~/.npmrc`. The first two lines route the default registry. Add a scoped
block for each private scope your org publishes:

```ini
registry=https://<jfrog-host>/artifactory/api/npm/<npm-virtual>/
//<jfrog-host>/artifactory/api/npm/<npm-virtual>/:_authToken=${REGISTRY_TOKEN}

@<your-scope>:registry=https://<jfrog-host>/artifactory/api/npm/<npm-scoped-virtual>/
//<jfrog-host>/artifactory/api/npm/<npm-scoped-virtual>/:_authToken=${REGISTRY_TOKEN}
```

npm expands `${REGISTRY_TOKEN}` from the environment at read time, so the secret
stays out of the file.

### PyPI: pip

Write `~/.config/pip/pip.conf`:

```ini
[global]
index-url = https://<jfrog-host>/artifactory/api/pypi/<pypi-virtual>/simple
```

pip picks up auth from `~/.netrc`. To embed credentials in the URL instead, use
`https://<user>:<token>@<jfrog-host>/...`.

### PyPI: uv

uv does **not** read `pip.conf`. Configure it separately, or it silently falls
back to public PyPI. OmacOS relies on uv for Python packaging, so this step
matters.

Write `~/.config/uv/uv.toml`:

```toml
[[index]]
url = "https://<jfrog-host>/artifactory/api/pypi/<pypi-virtual>/simple"
default = true
```

uv reads `~/.netrc` for auth. You can also set `UV_DEFAULT_INDEX` in your shell
profile to the same URL.

### Go

Point the module proxy at the registry and let Go read `~/.netrc` for auth. Add
to your shell profile:

```bash
export GOPROXY="https://<jfrog-host>/artifactory/api/go/<go-virtual>"
export GOSUMDB=off
```

`GOSUMDB=off` skips the public checksum database at `sum.golang.org`, which is
usually unreachable behind a proxy. If your proxy serves the checksum database,
your platform team can give you the value to use instead of `off`.

### Cargo (Rust only)

Skip this unless your org runs a Cargo (crates) virtual repository. Many don't.
If yours doesn't, Rust builds either reach `crates.io` directly or fail, so check
first.

Write `~/.cargo/config.toml`:

```toml
[registries.proxy]
index = "sparse+https://<jfrog-host>/artifactory/api/cargo/<cargo-virtual>/index/"

[source.crates-io]
replace-with = "proxy"
```

Set the token in your shell profile:

```bash
export CARGO_REGISTRIES_PROXY_TOKEN="Bearer <your-identity-token>"
```

### Container images (Docker or Podman)

Log in once, then reference images by their full registry path. Both engines
take the same commands:

```bash
docker login <jfrog-host>      # or: podman login <jfrog-host>
docker pull <jfrog-host>/<docker-virtual>/<image>:<tag>
```

Two things to confirm with your platform team:

- Whether the repo is a pull-through cache for a public registry (so public base
  images flow through it) or hosts only your org's own images. If it hosts only
  internal images, pull public base images from their original registry.
- The reference form. Some setups use a subdomain instead of a path:
  `<docker-virtual>.<jfrog-host>/<image>:<tag>`. The repo's "Set Me Up" panel
  shows the exact form.

On macOS, Podman runs the engine in a Linux VM. `podman login` stores
credentials on the host and pulls use them, so login alone is enough for the
full-path approach. A transparent Docker Hub mirror (so `docker.io/...` rewrites
to the proxy automatically) needs `registries.conf` inside the VM, which is lost
when the machine is recreated. The full-path approach avoids that.

## Step 3: verify before installing

Open a fresh shell so the new environment variables load, then check each tool
you configured:

```bash
# npm: should print the proxy URL, not registry.npmjs.org
npm config get registry

# pip: dry run resolves against the proxy
pip download --no-deps --dest /tmp/pip-check requests

# uv: should resolve from the proxy index
uv pip install --dry-run requests

# Go: confirm the proxy URL
go env GOPROXY

# Container images: pull a known image through the proxy (docker or podman)
podman pull <jfrog-host>/<docker-virtual>/<known-image>:<tag>
```

A 401 or 403 means the token is wrong, expired, or lacks access to that repo. A
timeout usually means the URL or repo name is off.

## Step 4: run OmacOS

```bash
./install.sh
```

The Neovim step installs LSP servers through Mason, which pulls from npm, PyPI,
and the Go proxy (all routed through your registry now) plus GitHub Releases
(direct). If Mason reports network failures, recheck the npm/PyPI/Go config
above.

## Optional: configure everything with the JFrog CLI

If your org uses the JFrog CLI (`jf`), it can write most of the per-tool config
for you after one login:

```bash
jf config add        # or: jf login   (SSO)
jf npm-config
jf pip-config
jf go-config
```

Test this against your instance before standardising on it. The CLI behaviour
depends on your JFrog version and how the repos are set up. The manual config
above always works and stays version-controllable, so it's the safer default.

## Troubleshooting

- **uv installs from public PyPI despite pip.conf.** Expected. uv ignores
  `pip.conf`. Configure `~/.config/uv/uv.toml` (see above).
- **401 / 403 on any tool.** Token expired or has no access to that repo.
  Regenerate the token and update both your env var and `~/.netrc`.
- **Go fails with a checksum mismatch or `sum.golang.org` timeout.** Set
  `GOSUMDB=off`, or use the proxied checksum DB value from your platform team.
- **`~/.netrc` ignored.** Check `chmod 600 ~/.netrc` and that the `machine` line
  matches the host exactly (no `https://`, no path).
- **Image pulls return "manifest unknown" or 403/404.** Either the reference
  form is wrong (check repository-path vs subdomain in "Set Me Up"), or the repo
  hosts only internal images and the public image isn't proxied. Pull public
  base images from their original registry, or ask your platform team to enable
  pull-through caching.
