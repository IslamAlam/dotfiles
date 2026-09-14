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

```sh
# chezmoi is installed via zinit at:
chezmoi=$HOME/.local/share/zinit/plugins/twpayne---chezmoi/chezmoi

# 1) Point chezmoi at this repo as its source directory.
$chezmoi init --source "$PWD"

# 2) Configure age encryption + generate an identity (one-time).
mkdir -p ~/.config/chezmoi
age-keygen > ~/.config/chezmoi/key.txt          # or: chezmoi generate age-key
chmod 600 ~/.config/chezmoi/key.txt

#   The key.txt comment line prints the public "recipient" — add it to config:
cat >> ~/.config/chezmoi/chezmoi.toml <<'EOF'
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "<paste your age1... public key here>"
EOF
```

## Manage the encrypted `.gitconfig` (never store secrets in git)

Because `private_encrypted_dot_gitconfig…age` is an age-encrypted blob, you never
hand-write it. Edit it through chezmoi so it decrypts/re-encrypts transparently:

```sh
# Import the real ~/.gitconfig from home into the repo (creates/updates the .age file).
$chezmoi add --force --encrypt ~/.gitconfig

# Or edit the encrypted entry in place.
$chezmoi edit-encrypted .gitconfig      # decrypt -> $EDITOR -> re-encrypt
```

The raw signing key and `credential.helper = store` live only inside that
armored file — nothing sensitive is ever committed to this repository.

## Daily workflow

```sh
# Preview what would change.
$chezmoi diff

# Apply changes to your home directory.
$chezmoi apply -v

# Track a new non-secret file from $HOME into the repo (edit then re-run).
$chezmoi add ~/.zshrc.d/something.zsh
```

## Notes / decisions
- `~/.gitconfig` is managed as an age-encrypted, private entry. Never commit its
  plaintext.
- ghostty / tmux / nvim are intentionally left out of this repo to keep it
  focused on shell config — ask and I'll add them if you want them here too.
