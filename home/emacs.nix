{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homeModules.emacs;
  epkgs = pkgs.emacs.pkgs;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;

  programming = with epkgs; [
    dockerfile-mode
    elpy
    eshell-syntax-highlighting
    fsharp-mode
    # Diagrams
    graphviz-dot-mode
    plantuml-mode
    # haskell-mode
    # Latex
    org-fragtog
    nix-mode
    sqlformat
    # Ops
    terraform-mode
    yaml-mode
  ];
  evilEtAl = with epkgs; [
    evil
    evil-collection
    treemacs-evil
  ];
  orgmode = with epkgs; [
    citeproc
    helm-org-rifle
    org-appear
    org-books
    org-drill
    org-elp
    org-pdftools
    org-ql
    org-roam
    org-roam-ui
    org-superstar
    org-tree-slide
    # For org-publish
    htmlize
    ox-rss
  ];
  treemacsEtAl = with epkgs; [
    treemacs
    treemacs-projectile
    treemacs-all-the-icons
    treemacs-magit
  ];
  emacsExtras = evilEtAl ++ orgmode ++ programming ++ treemacsEtAl;
in
{
  options.homeModules.emacs = {
    enable = mkEnableOption "Enable a custom Emacs installation";
  };

  config = mkIf cfg.enable {
    # Treemacs requires python3
    home.packages = with pkgs; [
      emacs-all-the-icons-fonts
      plantuml
      python3
    ];

    services.emacs.enable = true;

    programs.emacs = {
      enable = true;
      extraPackages = (
        epkgs:
        (
          with epkgs;
          [
            # Common
            aggressive-indent
            all-the-icons
            auto-complete
            auto-compile
            company
            company-quickhelp
            dired-sidebar
            rainbow-mode
            rainbow-delimiters
            rainbow-blocks
            use-package
            use-package-chords
            s
            # Formatting
            format-all
            # Deveopment
            ## Tooling
            direnv
            lsp-mode
            lsp-ui
            magit
            # Email
            #notmuch
            # Extra
            auto-dim-other-buffers
            atom-one-dark-theme
            command-log-mode
            flycheck
            helpful
            projectile
            swiper
            rainbow-delimiters
            rg
            undo-tree
            vimrc-mode
            web-mode
            which-key
            # Notifications
            alert
          ]
          ++ emacsExtras
        )
      );
    };

    home.file = {
      ".emacs.d" = {
        source = ../dotfiles/emacs.d;
        recursive = true;
      };
    };

    xresources.properties = {
      # Set some Emacs GUI properties in the .Xresources file because they are
      # expensive to set during initialization in Emacs lisp. This saves about
      # half a second on startup time. See the following link for more options:
      # https://www.gnu.org/software/emacs/manual/html_node/emacs/Table-of-Resources.html
      "Emacs.menuBar" = false;
      "Emacs.toolBar" = false;
      "Emacs.verticalScrollBars" = false;
      "Emacs.internalBorder" = 0;
      "Emacs.borderWidth" = 0;
      "Emacs.leftFringe" = 0;
      "Emacs.rightFringe" = 0;
      "Emacs.fullscreen" = "fullheight";
    };
  };
}
