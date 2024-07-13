(add-to-list 'default-frame-alist '(undecorated . t))
(setq default-frame-alist '((font . "Fantasque Sans Mono 22")))
(scroll-bar-mode -1)
(tooltip-mode -1)
(menu-bar-mode 1)
(set-fringe-mode 10)
(setq visible-bell nil
      ring-bell-function 'double-flash-mode-line)
(defun double-flash-mode-line ()
  (let ((flash-sec (/ 1.0 20)))
    (invert-face 'mode-line)
    (run-with-timer flash-sec nil #'invert-face 'mode-line)
    (run-with-timer (* 2 flash-sec) nil #'invert-face 'mode-line)
    (run-with-timer (* 3 flash-sec) nil #'invert-face 'mode-line)))
(global-display-line-numbers-mode)
(setq display-line-numbers-type 'relative)
(setq base16-theme-256-color-source "base16-shell")
(load-theme 'base16-material-darker t)
(require 'nix-mode)
(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(setq org-directory "~/Documents/Org")
(setq org-agenda-files (directory-files-recursively org-directory "\\.org$"))
(require 'lsp-mode)
(require 'which-key)
(use-package which-key
  :init
  (which-key-mode 1)
  :config
  (setq which-key-side-window-location 'bottom
        which-key-sort-order #'which-key-key-order-alpha
        which-key-sort-uppercase-first nil
        which-key-add-column-padding 1
        which-key-max-display-columns nil
        which-key-min-display-lines 6
        which-key-side-window-slot -10
        which-key-side-window-max-height 0.25
        which-key-idle-delay 0.8
        which-key-max-description-length 25
        which-key-allow-imprecise-window-fit t
        which-key-separator " -> " ))

(setq evil-want-keybinding nil)
(setq evil-want-C-u-scroll t)
(require 'evil)
(evil-mode 1)
(setq evil-jumps-across-buffers t)
(require 'evil-org)
(add-hook 'org-mode-hook 'evil-org-mode)
(evil-org-set-key-theme '(navigation insert textobjects additional calendar))
(require 'evil-org-agenda)
(evil-org-agenda-set-keys)
(evil-collection-init)
(global-evil-surround-mode 1)
(add-hook 'prog-mode-hook 'format-all-mode)
(add-hook 'after-init-hook 'global-company-mode)
(setq org-fold-core-style  'overlay)
(doom-modeline-mode 1)
(setq doom-modeline-icon nil)

