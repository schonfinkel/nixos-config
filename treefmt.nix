# treefmt.nix
{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  programs = {
    just.enable = true;
    nixfmt.enable = true;
  };
}
