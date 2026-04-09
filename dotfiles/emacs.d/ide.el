;; direnv
(use-package direnv
  :config
  (direnv-mode))

(use-package company
  :commands company-tng-configure-default
  :custom
  ;; delay to start completion
  (company-idle-delay 0)
  ;; nb of chars before triggering completion
  (company-minimum-prefix-length 1)

  :config
  ;; enable company-mode in all buffers
  (global-company-mode)

  :bind
  ;; use <C> instead of <M> to navigate completions
  (:map company-active-map
	      ("M-n" . nil)
	      ("M-p" . nil)
	      ("C-n" . #'company-select-next)
	      ("C-p" . #'company-select-previous)))

;; Projectile
(unless (package-installed-p 'projectile)
  (package-install 'projectile))
(require 'projectile)

(projectile-mode +1)
;;(define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

(use-package dired-sidebar
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :ensure t
  :commands (dired-sidebar-toggle-sidebar)
  :init
  (add-hook 'dired-sidebar-mode-hook
  	(lambda ()
  	  (unless (file-remote-p default-directory)
  	    (auto-revert-mode))))
  :config
  (push 'toggle-window-split dired-sidebar-toggle-hidden-commands)
  (push 'rotate-windows dired-sidebar-toggle-hidden-commands)

  ;;(setq dired-sidebar-subtree-line-prefix "__")
  (setq dired-sidebar-theme 'vscode)
  (setq dired-sidebar-use-term-integration t)
  (setq dired-sidebar-use-custom-font t))

(defun sidebar-toggle ()
  "Toggle both `dired-sidebar' and `ibuffer-sidebar'."
  (interactive)
  (dired-sidebar-toggle-sidebar)
  (ibuffer-sidebar-toggle-sidebar))

;; Aggressive Indent hooks
(add-hook 'emacs-lisp-mode-hook #'aggressive-indent-mode)
(add-hook 'css-mode-hook #'aggressive-indent-mode)

;; Language Server Protocol -- config
(require 'lsp-mode)
(use-package lsp-mode :ensure t)
(defun lsp-wrapper ()
 (let* ((programming-modes '(fsharp-mode haskell-mode nix-mode)))
 (cond ((member major-mode programming-modes) (lsp-mode))
       (t nil))))

(use-package lsp-mode
:ensure t
:config
(add-hook 'lsp-mode-hook
    (lambda ()
    (add-hook 'before-save-hook
            (lambda () (lsp-format-buffer buffer-file-name))
            nil 'local))))

(use-package prog-mode
 :init
 (add-hook 'prog-mode-hook #'lsp-wrapper))

(use-package lsp-ui
  :commands lsp-ui-mode)

;;; Flycheck
(use-package flycheck
  :commands global-flycheck-mode
  :init
  ;; (setq flycheck-mode-globals '(not rust-mode))
  (global-flycheck-mode))

;; Language suppport

;;; Dockerfile
(use-package dockerfile-mode
  :config (add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode)))


;;graphviz dot
(use-package graphviz-dot-mode :ensure t
  :mode (("\\.dot\\'" . graphviz-dot-mode)))

;;; Javascript
(use-package es-mode
  :init (add-to-list 'auto-mode-alist '("\\.es$" . es-mode))
  :hook ((es-result-mode . hs-minor-mode)))

;;; Nix
(add-to-list 'lsp-language-id-configuration '(nix-mode . "nix"))
(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection '("rnix-lsp"))
		          :major-modes '(nix-mode)
		          :server-id 'nix))

;;; F#
(use-package comint
  ;; This is based on
  ;; https://oleksandrmanzyuk.wordpress.com/2011/10/23/a-persistent-command-history-in-emacs/
  ;; The idea is to store sessions of comint based modes. For example, to enable
  ;; reading/writing of command history in, say, inferior-haskell-mode buffers,
  ;; simply add turn-on-comint-history to inferior-haskell-mode-hook by adding
  ;; it to the :hook directive
  :config
  (defun comint-write-history-on-exit (process event)
    (comint-write-input-ring)
    (let ((buf (process-buffer process)))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          (insert (format "\nProcess %s %s" process event))))))

  (defun turn-on-comint-history ()
    (let ((process (get-buffer-process (current-buffer))))
      (when process
        (setq comint-input-ring-file-name
              (format "~/.emacs.d/inferior-%s-history"
                      (process-name process)))
        (comint-read-input-ring)
        (set-process-sentinel process
                              #'comint-write-history-on-exit))))

  (defun mapc-buffers (fn)
    (mapc (lambda (buffer)
            (with-current-buffer buffer
              (funcall fn)))
          (buffer-list)))

  (defun comint-write-input-ring-all-buffers ()
    (mapc-buffers 'comint-write-input-ring))

  (add-hook 'kill-emacs-hook 'comint-write-input-ring-all-buffers)
  (add-hook 'kill-buffer-hook 'comint-write-input-ring))

;; (use-package eglot-fsharp
;;   :ensure
;;   :config
;;   (add-hook 'inferior-fsharp-mode-hook 'turn-on-comint-history))

(use-package company-quickhelp
 :ensure t
 :init
 (setq company-quickhelp-delay '1.0)
 :config (company-quickhelp-mode nil))

(use-package fsharp-mode
 :ensure t
 :mode (("\\.fs$" .  fsharp-mode)
      ("\\.fsx$" .  fsharp-mode))
 :hook (
      (fsharp-mode . company-mode))
 :config
 (setq inferior-fsharp-program "dotnet fsi")
 (add-hook 'prog-mode-hook
       (lambda ()
     (add-hook 'before-save-hook
           (lambda () (lsp-format-buffer buffer-file-name))
           nil 'local)))
 (add-hook 'inferior-fsharp-mode-hook 'turn-on-comint-history))

;;; Python
(org-babel-do-load-languages
 'org-babel-load-languages
 '((python . t)))

;;; Gleam
(use-package gleam-mode
  :mode "\\.gleam\\'"
  :hook (gleam-mode . lsp))

;;; Terraform/HCL
(require 'terraform-mode)
(add-to-list 'auto-mode-alist '("\\.tf\\'" . terraform-mode))
(add-to-list 'auto-mode-alist '("\\.tfvars\\'" . terraform-mode))
(add-to-list 'auto-mode-alist '("\\.pkr.hcl\\'" . terraform-mode))
(add-hook 'terraform-mode-hook #'terraform-format-on-save-mode)

;;; Shell
(use-package eshell-syntax-highlighting
  :after eshell-mode
  :ensure t ;; Install if not already installed.
  :config
  ;; Enable in all Eshell buffers.
  (eshell-syntax-highlighting-global-mode +1))

;;; SQL
(use-package sql
  :config
  ;; with mariadb, the default regexp used to match the prompt is a bit off. This fixes it.
  (sql-set-product-feature 'mysql :prompt-regexp "^\\(MariaDB\\|MySQL\\) \\[[_a-zA-Z]*\\]> "))

(use-package sqlformat
  :config
  (setq sqlformat-command 'pgformatter))

;;; YAML
(require 'yaml-mode)
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode))

;;; Vim
(use-package vimrc-mode
  :init (add-to-list 'auto-mode-alist '("\\.vim\\(rc\\)?\\'" . vimrc-mode)))

;;; Latex
(setq org-preview-latex-default-process 'dvisvgm) ;No blur when scaling

(add-hook 'org-mode-hook 'org-fragtog-mode)
