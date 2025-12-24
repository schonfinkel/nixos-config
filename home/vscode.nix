{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.vscode;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.homeModules.vscode = {
    enable = mkEnableOption "Enable a custom VS Code setup";
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode-fhs;

      profiles.default.userSettings = {
        "update.mode" = "none";

        "editor"."fontFamily" = "Jetbrains Mono";
        "editor.formatOnSave" = false;
        "editor.inlayHints.enabled" = "offUnlessPressed";
        "editor.linkedEditing" = true;
        "editor.rulers" = [
          80
          120
        ];

        # excluded files
        "files.exclude" = {
          # removes these from the search
          "**/.direnv" = true;
          "**/.devenv" = true;
        };

        "terminal.integrated.tabs.enabled" = true;

        "workbench.tree.indent" = 15;

        "window.titleBarStyle" = "custom";
        "window.zoomLevel" = 0;

        # F#
        "FSharp.inlayHints.typeAnnotations" = false;
        "FSharp.inlayHints.parameterNames" = false;
        "FSharp.addFsiWatcher" = true;
        "FSharp.FSIExtraInteractiveParameters" = [ "--readline" ];
        "FSharp.FSIExtraSharedParameters" = [ "--readline" ];
        "FSharp.saveOnSendLastSelection" = false;

        # HTML
        "[html]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };

        # Nix
        "nix" = {
          "enableLanguageServer" = true;
          "formatterPath" = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
          "serverPath" = "${pkgs.nil}/bin/nil";
        };
        "[nix]" = {
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
        };
      };

      profiles.default.extensions = (with pkgs.vscode-extensions; [
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
      ]) ++ (with pkgs.open-vsx; [
        mtxr.sqltools
        mtxr.sqltools-driver-mssql
      ]);
    };

    home.packages = with pkgs; [ jetbrains-mono ];
  };
}
