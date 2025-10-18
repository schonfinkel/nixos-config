{
  pkgs,
  config,
  inputs,
  system,
  ...
}:

{
  imports = [
    (import ./kitty.nix { inherit pkgs config; })
    #(import ./alacritty.nix { inherit pkgs config; })
  ];

  home.packages = with pkgs; [
  ];
}
