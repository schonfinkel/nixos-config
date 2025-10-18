{ pkgs, config, ... }:

{
  # fonts.fontDir.enable = true;
  # fonts.enableDefaultFonts = true;
  # fonts.fontconfig = {
  #   enable = true;
  #   hinting.enable = true;
  #   defaultFonts = {
  #     serif = [ "Hack" "Ubuntu" ];
  #     sansSerif = [ "Hack" "Ubuntu" ];
  #     monospace = [ "Hack" "Ubuntu" ];
  #   };
  # };

  fonts.packages = with pkgs; [
    # Other
    font-awesome_5
    iosevka
    # Nerdfonts
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.iosevka
    nerd-fonts.monoid
    nerd-fonts.symbols-only
    nerd-fonts.space-mono
    powerline-fonts
    profont
    recursive
    roboto
    roboto-mono
    roboto-slab
  ];
}
