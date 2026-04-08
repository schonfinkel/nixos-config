(eval-when-compile
  (require 'use-package))
(setq use-package-compute-statistics t)

;; Allows to see which commands are being called:
;; - command-log-mode
;; - clm/open-command-log-buffer
(use-package command-log-mode)

;; (use-package rg
;;   :config (rg-enable-default-bindings))

(use-package undo-tree
  :init (global-undo-tree-mode))

;; Set default font
(set-face-attribute 'default nil
                    :family "Iosevka"
                    :height 150
                    :weight 'normal
                    :width 'normal)
(set-fontset-font "fontset-default" 'han (font-spec :family "WenQuanYi Zen Hei"))
;; (set-fontset-font "fontset-default" 'han (font-spec :family "WenQuanYi Zen Hei Mono"))

;; <ESC> cancels all
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; Backup policy
(setq backup-directory-alist `(("." . "~/.saves")))
(setq version-control t     ;; Use version numbers for backups.
      kept-new-versions 5   ;; Number of newest versions to keep.
      kept-old-versions 0   ;; Number of oldest versions to keep.
      delete-old-versions t ;; Don't ask to delete excess backup versions.
      backup-by-copying t)  ;; Copy all files, don't rename them.

;; Stolen from here 
;; https://emacsredux.com/blog/2026/04/07/stealing-from-the-best-emacs-configs/
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

(setq redisplay-skip-fontification-on-input t)

(setq read-process-output-max (* 4 1024 1024)) ; 4MB

(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

;; Extra settings
(load-file "~/.emacs.d/edit.el")
(load-file "~/.emacs.d/evil.el")
(load-file "~/.emacs.d/git.el")
(load-file "~/.emacs.d/ide.el")
(load-file "~/.emacs.d/org.el")
(load-file "~/.emacs.d/roam.el")
(load-file "~/.emacs.d/ui.el")
