{ pkgs, home, ... }:

{
  # Treemacs requires python3
  home.packages = with pkgs; [
    emacs-all-the-icons-fonts
    python3
  ];

  services.emacs.enable = true;

  programs.emacs = {
    enable = true;
    extraPackages = (epkgs:
      (with epkgs; [
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
        ## Languages
        dockerfile-mode
        elpy
        eshell-syntax-highlighting
        fsharp-mode
        # graphviz
        graphviz-dot-mode
        # haskell-mode
        nix-mode
        sqlformat
        # Latex
        org-fragtog
        ## Tooling
        direnv
        lsp-mode
        lsp-ui
        magit
        ## Ops
        plantuml-mode
        terraform-mode
        yaml-mode
        # Email
        #notmuch
        # Extra
        auto-dim-other-buffers
        atom-one-dark-theme
        command-log-mode
        evil
        evil-collection
        flycheck
        helpful
        projectile
        treemacs
        treemacs-evil
        treemacs-projectile
        treemacs-all-the-icons
        treemacs-magit
        swiper
        rainbow-delimiters
        #rg
        undo-tree
        vimrc-mode
        web-mode
        which-key
        # Notifications
        alert
        # Org
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
      ]));
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
}
