{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hostModules.noctalia;
  inherit (lib)
    attrByPath
    mkEnableOption
    mkIf
    mkMerge
    ;

  # The greeter's keyboard follows the host's XKB settings, which are the single
  # source of truth (same convention as home/hyprland.nix). `variant` is `null`
  # by default in nixpkgs, but the greeter expects a string.
  xkb = config.services.xserver.xkb or { };
  kbLayout = xkb.layout or "us";
  kbVariant = if (xkb.variant or null) == null then "" else xkb.variant;
  kbOptions = if (xkb.options or null) == null then "" else xkb.options;

  # Cursor size follows hostModules.themes so the greeter and the session agree.
  cursorSize = attrByPath [ "hostModules" "themes" "cursorSize" ] 24 config;
in
{
  imports = [
    inputs.noctalia.nixosModules.default
  ];

  options.hostModules.noctalia = {
    enable = mkEnableOption "Enable Noctalia shell (bar/panels) and the Noctalia Greeter";

    greeter.enable = mkEnableOption "Enable the Noctalia Greeter (greetd)" // {
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Installs the package system-wide and pulls in the recommended services
      # (NetworkManager, Bluetooth, UPower, power-profiles-daemon). NetworkManager
      # is already enabled by hostModules.commons; the rest are opt-in mkDefaults
      # and the power-profile service only appears when `tuned` is absent, so it
      # does not fight nixos-hardware's tlp on the ThinkPad.
      programs.noctalia = {
        enable = true;
        recommendedServices.enable = true;
      };

      # Prebuilt Noctalia binaries come from the Cachix cache. We deliberately do
      # NOT follow our nixpkgs input for `noctalia` (see flake.nix), which keeps
      # the derivation hash stable so the cache hits.
      nix.settings = {
        substituters = [ "https://noctalia.cachix.org" ];
        trusted-public-keys = [
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };
    }

    # Noctalia Greeter replaces SDDM (which hosts must disable themselves).
    (mkIf cfg.greeter.enable {
      services.displayManager.noctalia-greeter = {
        enable = true;

        settings = {
          session.default = "Hyprland (uwsm-managed)";

          keyboard = {
            layout = kbLayout;
            variant = kbVariant;
            options = kbOptions;
          };

          cursor.size = cursorSize;
        };

        cursorTheme = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Ice";
        };
      };
    })
  ]);
}
