{ pkgs, stylix, ... }:

{
  stylix = {
    enable = true;
    image = ../wallpapers/wallpaper.png;
    #base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";
    opacity.terminal = 0.9;
    cursor.package = pkgs.bibata-cursors;
    cursor.name = "Bibata-Modern-Ice";
    cursor.size = 24;
    override = {
      # catppuccin-mocha: but less blue in the background
      # <https://github.com/catppuccin/base16>
      #base00 = "1e1e1e"; # base
      #base01 = "181818"; # mantle
      #base02 = "313232"; # surface0
      #base03 = "454748"; # surface1
      #base04 = "585b5d"; # surface2 
      #base05 = "cdd6d9"; # text
      #base06 = "f5e0dc"; # rosewater
      #base07 = "b4befe"; # lavender
      #base08 = "f38ba8"; # red
      base09 = "fab387"; # peach
      base0A = "f9e2af"; # yellow
      base0B = "a6e3a1"; # green
      base0C = "94e2d5"; # teal
      base0D = "89b4fa"; # blue
      base0E = "cba6f7"; # mauve
      base0F = "f2cdcd"; # flamingo
    };
    fonts = {
    #  monospace = {
    #    package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
    #    name = "JetBrainsMono Nerd Font Mono";
    #  };
    #  sansSerif = {
    #    package = pkgs.montserrat;
    #    name = "Montserrat";
    #  };
    #  serif = {
    #    package = pkgs.montserrat;
    #    name = "Montserrat";
    #  };
      sizes = {
        applications = 16;
        terminal = 16;
        desktop = 14;
        popups = 12;
      };
    };
  };
}
