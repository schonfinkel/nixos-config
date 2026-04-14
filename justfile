set dotenv-load := true
set export := true

dotfiles_dir := justfile_directory() + "/dotfiles"
home_dir := justfile_directory() + "/home"
hosts_dir := justfile_directory() + "/hosts"
modules_dir := justfile_directory() + "/modules"
overlay_dir := justfile_directory() + "/overlays"
secrets_dir := justfile_directory() + "/secrets"
target_flake := env_var_or_default("TARGET_FLAKE", "peano")

# For lazy people

alias bi := build-iso
alias bq := build-qemu
alias rq := run-qemu

# Lists all availiable targets
default:
    just --list

# ----------------------------
# Nix Commands
# ----------------------------

# Default Build, uses `nixosConfiguration`
[group('nix')]
build:
    nix build ".#nixosConfigurations.{{ target_flake }}.config.system.build.toplevel"

# Builds a custom ISO with the "peano" configuration
[group('nix')]
build-iso:
    nix build ".#peano"

# Builds the QEMU VM
[group('nix')]
build-qemu:
    nix build ".#nixosConfigurations.{{ target_flake }}.config.system.build.vmWithDisko"

# Boot a QEMU VM, pointing to target_flake
[group('nix')]
run-qemu: build-qemu
    nix run -L ".#nixosConfigurations.{{ target_flake }}.config.system.build.vmWithDisko"

# Loads the current Flake into a REPL
[group('nix')]
repl:
    nix repl "#nixosConfigurations.{{ target_flake }}"

# ----------------------------
# Age-related Commands
# ----------------------------

# Resets the agenix file
[group('age')]
rekey:
    cd {{ secrets_dir }} && nix run github:ryantm/agenix -- -r
