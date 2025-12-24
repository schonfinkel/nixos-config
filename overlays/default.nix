{
  pkgs,
  inputs,
  system,
  ...
}:

{
  nixpkgs.overlays = [
    inputs.emacs.overlay
    inputs.nix-vscode-extensions.overlays.default
  ];
}
