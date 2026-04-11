;; Set up package management
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")))
(package-initialize)

;; Ensure use-package is installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

(add-to-list 'default-frame-alist '(fullscreen . maximized))


(setq default-directory "~/")

;; Basic UI tweaks
(menu-bar-mode -1)           ;; Disable the menu bar
(tool-bar-mode -1)           ;; Disable the toolbar
(scroll-bar-mode -1)         ;; Disable the scroll bar
(setq inhibit-startup-screen t) ;; Disable the startup screen

;; Line numbers and syntax highlighting
(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)
(global-font-lock-mode t)
(setq ring-bell-function 'ignore)

;; Backup files management
(setq backup-directory-alist `(("." . "~/.emacs.d/backups")))
(setq auto-save-default nil)

;; Set default font size
;;:font "Consolas"
(set-face-attribute 'default nil :height 120)
(electric-pair-mode -1)

(setq history-length 20)
(savehist-mode 1)

(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)

(setq use-short-answers t)

(setq use-dialog-box nil)
(global-auto-revert-mode 1)
(delete-selection-mode 1)
(add-hook 'post-self-insert-hook (lambda() (electric-pair-post-self-insert-function) (indent-according-to-mode)))

(setq-default indent-tabs-mode nil) ;; disable tab for indent
(setq-default tab-width 4)

(setq redisplay-skip-fontification-on-input t)
(setq read-process-output-max (* 4 1024 1024)) ; 4MB
(setq save-interprogram-paste-before-kill t)
(setq kill-do-not-save-duplicates t)
(use-package go-ts-mode
  :mode ("\\.go\\'" . go-ts-mode)
  :hook (go-ts-mode . eglot-ensure)
  :config
  (setq indent-tabs-mode nil
        go-ts-mode-indent-offset 4))

;; (with-eval-after-load 'go-ts-mode
;;   (add-hook 'go-ts-mode-hook (lambda ()
;;                             (setq indent-tabs-mode nil)
;;                             (setq go-ts-mode-indent-offset 4))))

(setq compilation-scroll-output t)

;;(setq split-width-threshold nil)
(setq split-height-threshold 0)
(load-theme 'modus-vivendi t)
(setq treesit-font-lock-level 4)

(set-face-attribute 'font-lock-variable-name-face nil
                    :foreground "#ffffff")

(set-face-attribute 'font-lock-property-use-face nil
                    :foreground "#4ae2f0")

(set-face-attribute 'font-lock-number-face nil
                    :foreground "#c0965b")


(setq nov-unzip-program (executable-find "tar")
      nov-unzip-args '("-xC" directory "-xf" filename))
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))

(setq gdb-many-windows t)
(setq gdb-show-tooltip t)
(set-fringe-style '(20 . nil))
(add-hook 'gdb-mode-hook
          (lambda ()
            (set-window-fringes (selected-window) 20 nil)))

(use-package transpose-frame
  :ensure t
  :bind (("C-x t" . transpose-frame)))

(use-package dired
  :ensure nil
  :custom ((dired-listing-switches "-agho --group-directories-first")))

;; Configure some popular packages
(use-package ivy
  :config
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t
        ivy-count-format "(%d/%d) ")
  (define-key ivy-minibuffer-map (kbd "C-v") 'clipboard-yank))

(use-package counsel
  :after ivy
  :config
  (counsel-mode 1))

(use-package which-key
  :config
  (which-key-mode))

;; Org-mode settings
(use-package org
  :config
  (setq org-startup-indented t
        org-hide-leading-stars t))

(use-package markdown-mode
  :ensure t)

;; Auto-complete and snippets
(use-package company
  :config
  (add-hook 'after-init-hook 'global-company-mode)
  (setq company-backends (remove 'company-clang company-backends)))

(use-package rust-mode
                  :ensure t
                  :init
                  (setq rust-mode-treesitter-derive t)
                  :mode "\\.rs\\'"
                  :hook (rust-mode . eglot-ensure)
                  :bind (("<f5>" . cargo-process-run)
                         ("<f6>" . cargo-process-build))
                  :config
                  (setq rust-format-on-save nil)
                  (add-hook 'rust-ts-mode-hook
                            (lambda ()
                              (modify-syntax-entry ?_ "w")))
                  (setq compile-command "cargo run")
                  (electric-pair-mode -1)
                  (setq treesit-font-lock-level 4))

;; Optionally, add cargo-mode for managing Rust projects
(use-package cargo
                  :ensure t
                  :hook (rust-ts-mode . cargo-minor-mode))

;; Add LSP support
(use-package eglot
  :ensure t
  :bind (("C-c g g" . xref-find-definitions)
         ("C-c r r" . eglot-rename))
  :config
  (add-hook 'eglot-managed-mode-hook (lambda () (eglot-inlay-hints-mode -1)))
  (custom-set-faces
   '(eglot-highlight-symbol-face ((t (:inherit bold :background "dim gray"))))
   '(eglot-semantic-declaration ((t nil)))
   '(eglot-semantic-definition ((t nil))))
  :custom
  (eglot-ignored-server-capabilities
   '(:documentRangeFormattingProvider
     :documentOnTypeFormattingProvider)))

(use-package drag-stuff
  :ensure t
  :bind (("M-p" . drag-stuff-up)
         ("M-n" . drag-stuff-down))
  :config
  (drag-stuff-global-mode 1)
  (drag-stuff-define-keys))

(use-package flycheck
  :ensure t)

(load "~/.emacs.d/my-plugins/plugins.el")

(add-to-list 'load-path "~/.emacs.d/prykra-c/")
(add-to-list 'load-path "~/.emacs.d/bigun/")

(use-package prykra-c
  :ensure nil)

(use-package bigun-mode
  :ensure nil
  :bind (("<f5>" . bigun-build-and-run)
         ("<f6>" . bigun-build))
  :config
  (bigun-restore-project-state)
  (bigun-global-mode 1))

(use-package cc-mode
  :mode ("\\.c\\'" . c-mode)
  :hook ((c-mode . my/c-style-setup)
         (c-mode . my/ff-search-directories)
         (c++-mode . my/c-style-setup)
         (c++-mode . my/cpp-syntax-tweaks)
         (c++-mode . my/cpp-ff-setup))
  :init
  (defun my/c-style-setup ()
    (c-set-style "stroustrup")
    (setq c-basic-offset 4)
    (c-set-offset 'substatement-open 0)
    (modify-syntax-entry ?_ "w")
    (eglot-ensure)
    ;; (lsp)
    ;; (when (bound-and-true-p lsp-mode)
    ;;   (setq lsp-semantic-tokens-enable t)
    ;;   (set-face-attribute 'lsp-face-semhl-property nil
    ;;                       :foreground "#ff7f86"))
    (local-set-key (kbd "C-c f") 'prykra-c))
  
  (defun my/cpp-syntax-tweaks ()
    (modify-syntax-entry ?_ "w"))
  (defun my/ff-search-directories ()
    (setq-local ff-search-directories
                '("." "./include" "../" "../src" "../include")))
  
  (defun my/cpp-ff-setup ()
    "Set ff-other-file-alist and ff-search-directories for C++ projects."
    (setq-local ff-other-file-alist
                '(("\\.cpp\\'" (".h" ".hpp"))
                  ("\\.h\\'"   (".cpp" ".tpp" ".cc"))
                  ("\\.hpp\\'" (".cpp" ".cc" ".tpp"))
                  ("\\.tpp\\'" (".h" ".hpp"))))
    (my/ff-search-directories))

  :custom
  (c-default-style '((c-mode . "stroustrup")
                     (c++-mode . "stroustrup"))))


(use-package python
  :mode ("\\.py\\'" . python-ts-mode)
  :hook
  ;;(python-mode . lsp)
  
  (python-ts-mode . (lambda ()
                      ;; (lsp)
                      ;;(eglot-ensure)
                      ;; (flycheck-mode -1)
                      (modify-syntax-entry ?_ "w")
                      (global-set-key (kbd "<f5>") 'compile))))

(use-package swiper
  :ensure t
  :bind ("C-s" . swiper))

(use-package deadgrep
  :ensure t
  :bind ("<f4>" . deadgrep)
  :config
  (setq deadgrep-display-buffer-function
		(lambda (buffer &rest _)
		  (display-buffer-same-window buffer nil))))

(use-package magit
  :defer t
  :ensure t)

(use-package snap-indent
  :hook (prog-mode . snap-indent-mode))

(use-package cmake-mode
  :ensure t)

(use-package gptel
  :ensure t
  :hook (gptel-mode . visual-line-mode)
  :config
  (setq gptel-default-mode 'org-mode)
  (add-hook 'gptel-post-response-functions 'gptel-end-of-response))

(defun my-gptel-process-response ()
  "Process GPTel response to insert newlines after periods."
  (let ((response gptel-response)) ; Assume gptel-response is where the response is stored
    (setq gptel-response (gptel-insert-newline-after-period response))))

(add-hook 'gptel-after-receive-hook 'my-gptel-process-response)

(use-package smartparens
  :ensure smartparens  ;; install the package
  :hook (prog-mode text-mode markdown-mode) ;; add `smartparens-mode` to these hooks
  :config
  ;; load default config
  (require 'smartparens-config))

(use-package multiple-cursors
  :ensure t
  :bind (("C->"         . mc/mark-next-like-this)
         ("C-<"         . mc/mark-previous-like-this)
         ("C-c C-,"     . mc/mark-all-like-this)))

(use-package multiple-cursors-core
  :ensure nil
  :bind (:map mc/keymap
              ("C-v" . nil)))

(global-unset-key (kbd "M-<down-mouse-1>"))
(global-set-key   (kbd "M-<mouse-1>") 'mc/add-cursor-on-click)

(use-package sly
  :ensure t
  :config
  (setq inferior-lisp-program "sbcl.exe --dynamic-space-size 4096"))

;; Keybinding

;; TODO write function that paste without indent only in selection
(electric-indent-mode -1) ;; disable automatic indentaion for actions
(global-set-key (kbd "RET") 'newline-and-indent)

;;auto revert dired
;; (setq global-auto-revert-none-file-buffers t)

;; (setq display-buffer-alist
;;       '(("\\*compilation\\*"
;;          (display-buffer-same-window))))


(defun my-line-save ()
  (interactive)
  (if (region-active-p)
      (kill-ring-save (region-beginning) (region-end))
    (let ((start (line-beginning-position))
          (end (line-end-position)))
      (kill-ring-save start end))))

(global-set-key (kbd "C-v") 'clipboard-yank)
(global-set-key (kbd "M-v") 'yank-pop)

(global-set-key (kbd "C-k") 'kill-whole-line)
(global-set-key (kbd "C-y") 'my-line-save)
(global-set-key (kbd "M-y") 'kill-region)
(global-set-key (kbd "C-z") 'undo)
;; (global-set-key (kbd "C-r") 'counsel-rg)

(global-set-key (kbd "<mouse-4>") 'my-line-save)
(global-set-key (kbd "<mouse-5>") 'clipboard-yank)

(global-set-key (kbd "C-c <left>") 'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c p") 'windmove-up)
(global-set-key (kbd "C-c n") 'windmove-down)


(when (eq system-type 'windows-nt)
  ;; Windows-specific config here
  (setq w32-pass-lwindow-to-system nil
        w32-lwindow-modifier 'super) ;; Menu key
  (w32-register-hot-key [s-]))

;; (defun my-start-selection-and-forward-word ()
;;   "Start selection and move forward by one word."
;;   (interactive)
;;   (forward-to-word)
;;   (set-mark-command nil)
;;   (forward-word))

(defun jump-to-next-word ()
  "Move the cursor to the beginning of the next word."
  (interactive)

  (if (looking-back "\\w" 1) ;; (looking-at "\\<") beginning of the word or word-at-point
      (progn
        (forward-word)
        (backward-word))
    (forward-word)))

(defun jump-to-previous-word ()
  "Move the cursor to the beginning of the previous word."
  (interactive)

  (if (looking-at "\\<") ;; (looking-at "\\<") beginning of the word or word-at-point
      (progn
        (backward-word)
        (forward-word))
    (backward-word)))


(defun backward-same-syntax (&optional n)
  "Move backward over characters with the same syntax class."
  (interactive "p")
  (forward-same-syntax (- (or n 1))))

;; (global-set-key (kbd "C-q") 'backward-same-syntax)
;; (global-set-key (kbd "C-w") 'forward-same-syntax)

(defun my-forward-word-strictly ()
  (interactive)
  (forward-word-strictly 1))

(defun my-backward-word-strictly ()
  (interactive)
  (backward-word-strictly 1))

(global-set-key (kbd "C-q") #'my-backward-word-strictly)
(global-set-key (kbd "C-w") #'my-forward-word-strictly)

(global-set-key (kbd "C-<right>") 'jump-to-next-word)
(global-set-key (kbd "C-<left>") 'jump-to-previous-word)

(global-set-key (kbd "C-x c") 'compile)
(global-set-key (kbd "M-s M-s") 'isearch-forward)
(global-unset-key (kbd "C-x C-c"))

(global-set-key (kbd "C-M-0") 'sp-forward-slurp-sexp)
(global-set-key (kbd "C-M-9") 'sp-backward-slurp-sexp)
(global-set-key (kbd "C-}") 'sp-forward-barf-sexp)
(global-set-key (kbd "C-{") 'sp-backward-barf-sexp)

(global-set-key (kbd "M-f") 'sp-forward-sexp)
(global-set-key (kbd "M-b") 'sp-backward-sexp)

(global-set-key (kbd "C-x p a") 'ff-find-other-file)
