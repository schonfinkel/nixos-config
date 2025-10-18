{
  pkgs,
  inputs,
  system,
  ...
}:

{
  nixpkgs.overlays = [
    inputs.emacs.overlay
  ];
}
