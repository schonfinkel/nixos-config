set dotenv-load := true
set export := true

dotfiles_dir := justfile_directory() + "/dotfiles"
home_dir := justfile_directory() + "/home"
hosts_dir := justfile_directory() + "/hosts"
modules_dir := justfile_directory() + "/modules"
overlay_dir := justfile_directory() + "/overlays"
secrets_dir := justfile_directory() + "/secrets"
target_flake := env_var_or_default("TARGET_FLAKE", "euclid")

# For lazy people

alias b := build
alias bq := build-qemu

# Lists all availiable targets
default:
    just --list

# Default Build, uses `nixosConfiguration`
build:
    nix build ".#nixosConfigurations.{{ target_flake }}.config.system.build.toplevel"

# Builds the QEMU VM
build-qemu:
    nix build ".#nixosConfigurations.{{ target_flake }}_vm.config.system.build.vm"

# Loads the current Flake into a REPL
repl:
    nix repl "#nixosConfigurations.{{ target_flake }}"

# ----------------------------
# Age-related Commands
# ----------------------------
# Resets the agenix file
rekey:
    cd {{ secrets_dir }} && nix run github:ryantm/agenix -- -r
