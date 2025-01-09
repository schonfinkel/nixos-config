# treefmt.nix
{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  programs = {
    gleam.enable = true;
    just.enable = true;
    nixfmt.enable = true;
    sqruff.enable = true;
  };
}
