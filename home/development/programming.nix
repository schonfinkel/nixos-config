{pkgs, ...}:

{
  home.packages = with pkgs; [
    # Language-Related
    lua-language-server
    nil
    # Tools
    hoppscotch
    shellcheck
  ];
}
