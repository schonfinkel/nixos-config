{ pkgs, lib, config, ... }:

let
  inherit (pkgs)
    nixpkgs-fmt
    nil
    ;
in
{
  imports =
    [
      ./neovim
    ];

  programs.vscode = {
    enable = true;
    # package = pkgs.vscodium;
    package = pkgs.vscode-fhs;
  
    profiles.default.userSettings = {
      "update.mode" = "none";

      "editor"."fontFamily" = "Jetbrains Mono";
      "editor.formatOnSave" = false;
      "editor.linkedEditing" = true;
      "editor.rulers" = [ 80 120 ];

      # excluded files
      "files.exclude" = {
        # removes these from the search
        "**/.direnv" = true;
        "**/.devenv" = true;
      };

      "workbench.tree.indent" = 15;

      "terminal.integrated.tabs.enabled" = true;

      "window.titleBarStyle" = "custom";
      "window.zoomLevel" = 0;

      # F#
      "FSharp.inlayHints.enabled" = false;
      "FSharp.inlayHints.typeAnnotations" = false;
      "FSharp.inlayHints.parameterNames" = false;

      # HTML
      "[html]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      # Nix
      "nix" = {
        "enableLanguageServer" = true;
        "formatterPath" = "${nixpkgs-fmt}/bin/nixpkgs-fmt";
        "serverPath" = "${nil}/bin/nil";
      };
      "[nix]" = {
        "editor.insertSpaces" = true;
        "editor.tabSize" = 2;
      };
    };

    profiles.default.extensions = with pkgs.vscode-extensions; [
      # .NET
      ms-dotnettools.csharp
      ionide.ionide-fsharp

      # Nix
      jnoortheen.nix-ide

      # Markdown
      yzhang.markdown-all-in-one

      # Misc
      eamodio.gitlens
      editorconfig.editorconfig
      esbenp.prettier-vscode
      gruntfuggly.todo-tree
      mkhl.direnv

      vscodevim.vim
      ms-vsliveshare.vsliveshare
    ];
  };

  home.packages = with pkgs; [ jetbrains-mono ];
}

