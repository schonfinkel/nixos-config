# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal, flake-based NixOS configuration covering multiple machines (hosts) plus Home Manager
user configs and dotfiles. There is no application code to compile — "building" means evaluating
Nix expressions into a system closure, and "testing" means building (and optionally booting) that
closure.

## Commands

Enter the dev shell first (provides `just`, `age`, `agenix`):

```shell
direnv allow
# or
nix develop --impure
```

Common tasks are wrapped in the `justfile` (run `just --list` for the full set). `TARGET_FLAKE` env
var selects the host and defaults to `peano`:

```shell
just build                 # nix build .#nixosConfigurations.<TARGET_FLAKE>...toplevel
TARGET_FLAKE=euclid just build
just build-iso              # nix build .#peano (custom ISO/qcow via nixos-generators)
just build-qemu              # build a bootable QEMU VM (with disko) for TARGET_FLAKE
just run-qemu                 # build-qemu, then boot it (SSH forwarded to localhost:2222)
just repl                       # nix repl on the TARGET_FLAKE's nixosConfiguration
just rekey                       # re-encrypt agenix secrets in the nix-secrets checkout (SECRETS_DIR)
just secrets-update              # re-pin the nix-secrets input after pushing that repo
```

Applying a config to a real machine (destructive on that machine — only do this if explicitly asked).
Use `--sudo` rather than `sudo nixos-rebuild`: the private `nix-secrets` input is fetched over SSH
during evaluation, and root has no key for it, so evaluate as the user and elevate only to activate:

```shell
nixos-rebuild switch --flake .#schonfinkel --sudo
nixos-rebuild switch --flake .#euclid --sudo
```

Formatting/linting: `nix fmt` runs `treefmt` (`nixfmt` for `*.nix`, `just` formatter for the
`justfile`) — see `treefmt.nix`. There is no separate lint step or test suite beyond "does it
evaluate/build."

CI (`.github/workflows/qemu_build.yml`) runs on push/PR to `master` when Nix/home/hosts/modules
files change, and simply does `nix develop .#ci --impure -c just bq` (build the `peano` QEMU
image). That's the closest thing to a test — if you change shared modules, home-manager config, or
overlays, a successful `just build` (or `just bq` for a fuller build) for the affected host(s) is
the bar to clear before calling the work done.

To validate a single host without a full build, `nix flake check` or evaluating
`nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` is faster than a full
`just build`.

## Architecture

### Flake structure (`flake.nix`)

- `flake-parts` splits the flake into `perSystem` (packages/apps/devShells/formatter, real
  multi-system) and `flake` (the `nixosConfigurations`, hardcoded to `x86_64-linux` via a local
  `mkHost` helper).
- `mkHost host user extraModules` is the standard way hosts are assembled: it always pulls in
  `documentation.nix`, `fonts.nix`, `hosts/<host>/configuration.nix`, `./overlays`, the
  StevenBlack hosts blocklist, and wires `home-manager.users.<user>` to
  `hosts/<host>/home.nix`. `caladan` and `euclid` are built this way, each adding
  `agenix` + `impermanence` + `stylix` (and `euclid` further adds a lenovo-thinkpad hardware
  module from `nixos-hardware`).
- `peano` is a special case: it's built by hand (not via `mkHost`), has no `home.nix` and no
  home-manager module wired in, and is the host used for the CI QEMU build and the `.#qemu`
  package/app (disk image generation via `nixos-generators` + `disko`). It also needs
  `hostId`/`profile`/`target` `specialArgs` because its `configuration.nix` takes them as
  function arguments. That is a property of how peano was written, not a requirement of
  `disko` — `schonfinkel` uses `disko` through `mkHost` with no `specialArgs` at all, by
  setting `hostModules.disko.{profile,target}` directly and letting `modules/disko.nix` read
  `profiles/settings.nix` itself. Prefer that pattern for new hosts.
- `schonfinkel` is the reference for the "full" setup: `mkHost` + `disko` + a tmpfs root, so
  `impermanence` is load-bearing rather than decorative. It is *not* encrypted — it uses the
  `ext4_ephemeral` profile; the `luks`/`luks_multi` profiles exist and keep the same LVM shape
  under a LUKS container if it ever needs to be. Because `impermanence` builds its bind mounts
  in stage 1, every persistence root needs `neededForBoot = true` (and on a LUKS profile every
  container has to be opened in the initrd, which systemd stage 1 does from one cached
  passphrase).
- **`hosts/tarski` exists on disk (`configuration.nix`, `home.nix`) and is referenced in
  `profiles/settings.nix`, but is not wired into `flake.nix`'s `nixosConfigurations`.** If asked to
  work on tarski, check whether it needs to be added to the flake outputs, or whether it's
  intentionally not yet active.

### Host modules pattern (`modules/*.nix`)

Every reusable module (other than `documentation.nix`, `fonts.nix`) follows the same shape and is
namespaced under `hostModules.<name>` (not the typical `services.*`):

```nix
options.hostModules.<name> = {
  enable = mkEnableOption "...";
  # other options
};
config = mkIf cfg.enable (mkMerge [ { ... } ]);
```

`modules/default.nix` imports the shared set (`agenix`, `audio`, `battery_notifier`, `commons`,
`hyprland`, `impermanence`, `themes`, `ssh`); `disko.nix` is imported explicitly only by hosts that
need it (`peano` and `schonfinkel`), since it depends on
`profiles/settings.nix` + `profiles/disko/<profile>.nix`. Each `hosts/<host>/configuration.nix`
enables the modules it needs by setting `hostModules.<name>.enable = true` plus that module's
options — this is the main place host-specific behavior (hostname, timezone, ssh allowed users,
NVIDIA/GPU config, etc.) is declared. When adding a new tunable to a module, add it as an
`mkOption` under `hostModules.<name>` rather than hardcoding it, so other hosts can opt in/out.

### Disko / disk layout (`modules/disko.nix`, `profiles/disko/*.nix`, `profiles/settings.nix`)

`profiles/settings.nix` maps host name -> `{ hostname, device, swap.size }` (plus optional
`dataDevice` for two-disk hosts and `rootSize` to size the tmpfs root). `modules/disko.nix`
reads `hostModules.disko.{profile,target}`, loads `profiles/settings.nix.<target>`, and imports
`profiles/disko/<profile>.nix` (`ext4` plain single-disk, `ext4_ephemeral` single-disk + tmpfs
root, `luks` same but encrypted, `luks_multi` two-disk + LUKS) to produce
`disko.devices`. It also has special-cased boot/kernel tweaks for `target == "aws"`, `"mgc"`, and
`"peano"` — these are hosting-provider/VM quirks, not generic behavior; follow the same
`mkIf (cfg.target == "...")` pattern if adding another one rather than branching more broadly.

### Impermanence (`modules/impermanence.nix`)

Declares exactly which system/user paths survive an impermanent root. If new stateful tools/apps
are added system-wide or to a persisted user's home, their state directories need to be added here
or their state silently disappears on reboot for hosts with this module enabled.

`persistDirectory` defaults to `/nix/persist` (what `euclid` uses), but the disko profiles mount
the persist volume at `/persist` — disko-managed hosts must set it explicitly. `dataDirectory` +
`dataUserDirectories` optionally declare a *second* persistence root on another disk; names listed
in `dataUserDirectories` are filtered out of the default set, so a directory is never claimed by
two roots. Both default to no-ops, so hosts that don't set them are unaffected.

### Home Manager (`home/*.nix`, `home/neovim/`, `home/hyprland/`)

`home/default.nix` is the top-level import list for all Home Manager modules (chats, commons,
emacs, ghostty, hyprland, llms, media, neovim, programming, security, themes, vscode, zshell). Each
`hosts/<host>/home.nix` is the per-host/per-user Home Manager entrypoint (imports `../../home` and
sets user-specific bits). `home/neovim/` is itself a small module (`default.nix` +
`packages.nix` + `private.nix`) rather than a flat file, and `home/hyprland/hyprland.lua` is Lua
config consumed by the Hyprland home-module, mirroring the plain-file dotfiles under `dotfiles/`
(zsh, emacs, mpv, ncmpcpp, zathura) that are symlinked in rather than templated.

### LLM agents and MCP servers (`home/llms.nix`, `overlays/default.nix`)

AI coding agents (claude-code, codex, cursor-agent, opencode) come from the `llm-agents` input via
its `shared-nixpkgs` overlay, which adds a `pkgs.llm-agents.<name>` scope without shadowing
nixpkgs. `home/llms.nix` installs them and renders MCP servers declared once in
`homeModules.llms.{personalMcpServers,mcpServers}` into each client's native config: Claude Code
via the profile-aware `cc` wrapper (`--mcp-config`, rendered per launch), Codex via a declarative
`~/.codex/config.toml` plus the `codexw` wrapper, and Cursor/OpenCode via real files materialised
by a Home Manager activation script (Cursor cannot follow symlinks). Claude Code subscriptions are
split per project with direnv: a `claude_profile personal|work` helper (in `direnvrc`) exports
`CLAUDE_CONFIG_DIR` into the persisted `~/.claude/{personal,work}` profile dirs. Secrets
(`urlSecret`/`secretHeaders` referencing agenix names) are only ever read from `/run/agenix` at
runtime or activation time — secret values never enter the Nix store; rotating one requires
re-running the switch. Servers with secrets need `hostModules.agenix` on the host and the matching
declarations in `modules/agenix.nix` (currently `jenkins_staging_url`/`jenkins_staging_token`,
enabled with `enableWorkProfile`).

`schonfinkel` also runs the upstream `ai-memory` NixOS module on loopback. `homeModules.llms.aiMemory`
adds its MCP endpoint to every client while leaving the existing MCP files under Home Manager control;
an activation step uses ai-memory's version-aware installers only for lifecycle hooks/plugins and routing
skills. Capture defaults to allowlist mode, so a checkout emits nothing until it contains an
`.ai-memory.toml` marker. Server state is persisted at `/var/lib/ai-memory`, while the user's hook spool,
capture policy, and global skills use persisted `~/.local/share/ai-memory` and `~/.agents`. Claude hooks
and skills are installed separately into both persisted `CLAUDE_CONFIG_DIR` profiles. Do not run
`ai-memory setup`: the NixOS module already owns the service, and setup would try to start a second user
service on the same port.

### Secrets (`nix-secrets` input, `modules/agenix.nix`)

Secrets are managed with `agenix` but live in a separate **private** flake,
`git+ssh://git@github.com/schonfinkel/nix-secrets` (the `nix-secrets` input; this repo is public).
Its `secrets.nix` lists the authorized public keys and maps them to `.age` files at the repo root:
`hashed_password.age` (`root`/user login hashes across hosts), `luks_data.age` (the data-disk LUKS
key for a `luks_multi` host; no host sets it today), `jumpcloud_<profile>_ovpn.age`
(`modules/jumpcloud.nix`), `mail_{ol,fat}.age` + `jenkins_staging_{url,token}.age` (work git
identities and the Jenkins MCP, enabled via `homeModules.programming.enableWorkProfile` /
`homeModules.llms` in `modules/agenix.nix`). Modules reference them as
`"${inputs.nix-secrets}/<name>.age"`.

The local checkout defaults to `../Personal/nix-secrets` (override with `SECRETS_DIR`; `install.sh`
takes `--secrets DIR`). Edit with `agenix -e` from that checkout, re-key with `just rekey` after
changing `secrets.nix` or the key list, commit + push there, then `just secrets-update` here —
the lock pins a rev, so nothing changes until it is re-pinned. To test unpushed changes, pass
`--override-input nix-secrets path:<checkout>`. Don't hand-edit `.age` files — they're ciphertext.
Inputs are fetched lazily, so hosts that never touch `age.secrets` (peano, i.e. CI) build without
access to the private repo.

Note the identity chain: `modules/agenix.nix` sets `identityPaths` under `persistDirectory` when
impermanence is on, so decryption depends on the persisted SSH keys already being in place. Since
the repo doesn't enable `systemd.sysusers`/`userborn`, agenix runs as an *activation script*
(before systemd starts), not as a unit — that ordering is what makes early-boot secrets work, and
enabling sysusers would change it.

### Overlays (`overlays/default.nix`)

Currently just wires in the `emacs-overlay` and `nix-vscode-extensions` flake inputs as nixpkgs
overlays; `peano`'s definition in `flake.nix` additionally layers a one-off overlay patching
`aggregateModules` (kernel target selection) directly in the flake, not in `overlays/`.
