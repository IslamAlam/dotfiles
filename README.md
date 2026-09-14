# dotfiles — chezmoi

Personal shell & tool config managed with [chezmoi](https://www.chezmoi.io/).

## Layout

| Source file | Installs to |
|---|---|
| `dot_zshrc.tmpl` | `~/.zshrc` (Nix-aware: full config on Nix, lean fallback otherwise) |
| `dot_zshrc.d/zinit.zsh.tmpl` | `~/.zshrc.d/zinit.zsh` |
| `dot_config/starship.toml` | `~/.config/starship.toml` |
| `private_encrypted_dot_gitconfig…age` | `~/.gitconfig` (**private**, age-encrypted) |

### Nix detection (`~/.zshrc`)
At shell-load time the `.zshrc` checks for a Nix install:
- **Nix present** → full config: loads Nix profiles + powerlevel10k, then sources
  `~/.zshrc.d/zinit.zsh`.
- **No Nix** → lean dependency-free fallback that still sources
  `~/.zshrc.d/zinit.zsh` when available.

Machine-specific bits in templates are gated on `{{ .chezmoi.hostname }}`
(see the `/data-local/mans_is/.conda` and `.lesspipe` entries — currently set for
host `vega-air`). Adjust hostnames to match your machines.

## First-time setup (this machine)

Encryption uses **age with a passphrase** (`[age] passphrase = true`), so no key
file is stored on disk. You'll be prompted for the passphrase each time chezmoi
encrypts or decrypts — this is the secret protecting your private files.

```sh
# chezmoi is installed via zinit at:
chezmoi=$HOME/.local/share/zinit/plugins/twpayne---chezmoi/chezmoi

# 1) Point chezmoi at this repo as its source directory.
$chezmoi init --source "$PWD"

# 2) Enable age passphrase encryption (one-time).
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
encryption = "age"
[age]
    passphrase = true
EOF

# 3) Import your real ~/.gitconfig as an encrypted entry.
#    You'll be prompted to set a passphrase (twice). Remember it!
$chezmoi add --force --encrypt ~/.gitconfig
```

> `passphrase = true` makes chezmoi (via the external `age` binary on PATH)
> prompt for a passphrase interactively each time it encrypts/decrypts.
> No identity key, no recipient, nothing stored at rest.

## Manage the encrypted `.gitconfig`

The entry lives in source as an armored blob (`private_encrypted_dot_gitconfig…age`)
and is never written as plaintext. Edit it through chezmoi so decrypt/re-encrypt
happens transparently (you'll be asked for the passphrase):

```sh
$chezmoi edit-encrypted .gitconfig   # decrypt -> $EDITOR -> re-encrypt
# or refresh from home:
$chezmoi add --force --encrypt ~/.gitconfig
```

The signing key and `credential.helper = store` live only inside that armored
file — nothing sensitive is ever committed to this repository.

## Daily workflow

```sh
# Preview what would change.
$chezmoi diff

# Apply changes to your home directory (prompts for passphrase).
$chezmoi apply -v

# Track a new non-secret file from $HOME into the repo (edit then re-run).
$chezmoi add ~/.zshrc.d/something.zsh
```

## SSH config & keys (encrypted)

Private SSH material is managed the same way as `.gitconfig`: age-passphrase-encrypted,
never committed in plaintext. Run these interactively so chezmoi can prompt for your passphrase.
(You'll be asked each time; a small loop prompts once per file.)

### Private keys — encrypt (`add --force --encrypt`)
```sh
$chezmoi add --force --encrypt ~/.ssh/id_ed25519 \
                            ~/.ssh/id_devman \
                            ~/.ssh/id_github \
                            ~/.ssh/id_ed25519_agenix \
                            ~/.ssh/id_ed25519_old
```
These become `private_dot_ssh/encrypted_private_id_*.age`.

### Custom configs (`~/.ssh/config_*`) — encrypt (contain host/proxy info)
```sh
$chezmoi add --force --encrypt ~/.ssh/config_personal \
                            ~/.ssh/config_external \
                            ~/.ssh/config_tailscale \
                            ~/.ssh/config_unibw
```
These become `private_dot_ssh/encrypted_config_*.age`.

### Public material — plain (safe to commit)
```sh
$chezmoi add --force ~/.ssh/id_ed25519.pub \
                    ~/.ssh/id_github.pub \
                    ~/.ssh/id_ed25519_agenix.pub
# known_hosts is machine-local; skip it unless you want to share it.
```

> Note: your top-level `~/.ssh/config` is a symlink into the Nix store (home-manager)
on this machine, so leave it unmanaged by chezmoi here. The custom `config_*` files it
`Include`s are what gets tracked.

## Notes / decisions
- `~/.gitconfig` is managed as an age-passphrase-encrypted, private entry. Never
  commit its plaintext.
- ghostty / tmux / nvim are intentionally left out of this repo to keep it
  focused on shell config — ask and I'll add them if you want them here too.
