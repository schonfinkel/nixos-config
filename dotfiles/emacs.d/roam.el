(use-package org-roam
  :ensure t
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory (file-truename "~/Code/Personal/schonfinkel.github.io/notes"))
  (org-roam-db-location (file-truename "~/Code/Personal/schonfinkel.github.io/notes/org-roam.db"))
  (org-roam-completion-everywhere t)
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         :map org-mode-map
         ("C-M-i"   . completion-at-point))
  :config
  (org-roam-setup))

;; This would only display the title, without any extra whitespace
(setq org-roam-node-display-template "${title}")
;; https://jeffkreeftmeijer.com/org-unable-to-resolve-link/
;;(org-id-update-id-locations (directory-files-recursively (file-truename "~/Code/Personal/schonfinkel.github.io/notes") "\\.org$") )
