(defmacro use-package-work (package &rest args)
  "Expand to `(when (eq init-config 'WORK) (use-package PACKAGE ARGS...))`."
  `(when (eq init-config 'WORK)
     (use-package ,package ,@args)))

(defmacro use-package-home (package &rest args)
  "Expand to `(when (eq init-config 'WORK) (use-package PACKAGE ARGS...))`."
  `(when (eq init-config 'HOME)
     (use-package ,package ,@args)))

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

(condition-case err
    (load "~/.emacs.d/config-settings")
  (error
   (setq init-config 'HOME)))

(add-to-list 'default-frame-alist '(fullscreen . maximized))
(when (eq init-config 'WORK)
  (setq default-directory "D:/TR11/"))

(when (eq init-config 'HOME)
  (setq default-directory "~/"))

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
(setq compilation-scroll-output t)

(when (eq init-config 'WORK)
  (set-terminal-coding-system 'utf-8)
  (set-language-environment 'utf-8)
  (set-keyboard-coding-system 'utf-8)
  (prefer-coding-system 'utf-8)
  (setq locale-coding-system 'utf-8)
  (set-default-coding-systems 'utf-8)
  (set-terminal-coding-system 'utf-8))

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

;; (set-face-attribute 'lsp-face-semhl-property nil
;;                     :foreground "#ff7f86")

;;lsp-face-semhl-property

;; (use-package modus-themes
;;   :config
;;   (load-theme 'modus-vivendi t)
;;   (setq treesit-font-lock-level 4)
;;   (set-face-attribute 'font-lock-variable-name-face nil
;;                       :foreground "#ffffff"))


(setq nov-unzip-program (executable-find "tar")
      nov-unzip-args '("-xC" directory "-xf" filename))
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))

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

(use-package-home rust-mode
                  :ensure t
                  :init
                  (setq rust-mode-treesitter-derive t)
                  :mode "\\.rs\\'"
                  :hook (rust-mode . lsp)
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
(use-package-home cargo
                  :ensure t
                  :hook (rust-ts-mode . cargo-minor-mode))

;; Add LSP support
(use-package lsp-mode
  :ensure t
                                        ;:hook ((rust-mode . lsp))
  :commands lsp
  :config
  (setq lsp-prefer-flymake nil)  ;; Use flycheck instead of flymake
  (setq gc-cons-threshold 100000000)
  (setq read-process-output-max (* 3 1024 1024))
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-enable-indentation nil))

(use-package lsp-ivy
  :ensure t
  :bind ("C-t" . lsp-ivy-workspace-symbol))

(use-package drag-stuff
  :ensure t
  :bind (("M-p" . drag-stuff-up)
         ("M-n" . drag-stuff-down))
  :config
  (drag-stuff-global-mode 1)
  (drag-stuff-define-keys))

(use-package flycheck
  :ensure t)

(add-to-list 'load-path "~/.emacs.d/prykra-c/")

(use-package-home prykra-c
                  :ensure nil)

(use-package-home cc-mode
                  :mode ("\\.c\\'" . c-mode)
                  :hook ((c-mode . my/c-style-setup)
                         (c++-mode . my/c-style-setup)
                         (c++-mode . my/cpp-syntax-tweaks))
                  :init
                  (defun my/c-style-setup ()
                    (c-set-style "stroustrup")
                    (setq c-basic-offset 4)
                    (c-set-offset 'substatement-open 0)
                    (modify-syntax-entry ?_ "w")
                    (lsp)
                    (when (bound-and-true-p lsp-mode)
                      (setq lsp-semantic-tokens-enable t)
                      (set-face-attribute 'lsp-face-semhl-property nil
                                          :foreground "#ff7f86"))
                    (local-set-key (kbd "C-c f") 'prykra-c))
                  
                  (defun my/cpp-syntax-tweaks ()
                    (modify-syntax-entry ?_ "w"))

                  :custom
                  (c-default-style '((c-mode . "stroustrup")
                                     (c++-mode . "stroustrup"))))


(use-package-work counsel-projectile
                  :ensure t)

(use-package-work projectile
                  :ensure t
                  :hook ((counsel-projectile-mode))
                  :config
                  (projectile-mode +1)
                  ;; Recommended keymap prefix on Windows/Linux
                  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
                  (setq projectile-indexing-method 'alien))


(use-package-home python
                  :mode ("\\.py\\'" . python-ts-mode)
                  :hook
                  ;;(python-mode . lsp)
                  
                  (python-ts-mode . (lambda ()
                                      ;; (lsp)
                                      ;;(eglot-ensure)
                                      ;; (flycheck-mode -1)
                                      (modify-syntax-entry ?_ "w")
                                      (global-set-key (kbd "<f5>") 'compile)))
                  :config
                  (setq lsp-pylsp-server-command "pylsp")
                  (setq
                   ;; Disable style and linting plugins
                   lsp-pylsp-plugins-pylint-enabled nil
                   lsp-pylsp-plugins-pycodestyle-enabled nil
                   lsp-pylsp-plugins-pydocstyle-enabled nil
                   lsp-pylsp-plugins-flake8-enabled nil
                   lsp-pylsp-plugins-mccabe-enabled nil
                   lsp-pylsp-plugins-ruff-enabled nil
                   lsp-pylsp-plugins-mypy-enabled nil

                   ;; Optional: Disable type inference and formatting
                   lsp-pylsp-plugins-jedi-enabled nil
                   lsp-pylsp-plugins-autopep8-enabled nil
                   lsp-pylsp-plugins-black-enabled nil
                   lsp-pylsp-plugins-yapf-enabled nil
                   ))


(use-package swiper
  :ensure t
  :bind ("C-s" . swiper))

(use-package-work deadgrep
                  :ensure t
                  :bind ("<f4>" . deadgrep))

(when (eq init-config 'WORK)
  (with-eval-after-load 'deadgrep
	(setq deadgrep-display-buffer-function
		  (lambda (buffer &rest _)
			(display-buffer-same-window buffer nil)))))

(use-package-home magit
                  :defer t
                  :ensure t)

(use-package snap-indent
  :hook (prog-mode . snap-indent-mode))

(use-package-home cmake-mode
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
         ("C-c C-<"     . mc/mark-all-like-this)))

(global-unset-key (kbd "M-<down-mouse-1>"))
(global-set-key   (kbd "M-<mouse-1>") 'mc/add-cursor-on-click)

(use-package-work p4
                  :ensure t)

(use-package-home sly
                  :ensure t
                  :config
                  (setq inferior-lisp-program "sbcl.exe --dynamic-space-size 4096"))

(when (eq init-config 'WORK)
  (add-to-list 'auto-mode-alist '("\\.nxshader\\'" . c-mode))
  (add-to-list 'auto-mode-alist '("\\.inc\\'" . c-mode))
  (add-to-list 'auto-mode-alist '("\\.shadernode\\'" . c-mode))
  (add-to-list 'auto-mode-alist '("\\.genHLSL\\'" . c-mode)))


(when (eq init-config 'WORK)
  (defun my/c-ts-indent-style ()
	"Custom indentation style for c++-ts-mode based on Microsoft style."
	`(;; No indentation for namespace children
      ;; ((n-p-gp nil nil "namespace_definition") grand-parent 0)
      ;; Align function parameters to the first parameter
      ((match nil "parameter_list" nil 1 1) parent-bol c-ts-mode-indent-offset)
      ((match nil "parameter_list" nil 2 nil) (nth-sibling 1) 0)
      ((match nil "argument_list" nil 1 1) parent-bol c-ts-mode-indent-offset)
      ((match nil "argument_list" nil 2 nil) (nth-sibling 1) 0)
      ;; No extra indent for case statements
      ((parent-is "case_statement") standalone-parent c-ts-mode-indent-offset)
      ;; No indent for preprocessor directives
      ((node-is "preproc") column-0 0)
      ;; Braces on same line (handled by default, but ensure no extra indent)
      ((node-is "}") parent-bol 0)
      ((node-is ")") parent-bol 0)
      ;; Append BSD style as a base
      ,@(alist-get 'bsd (c-ts-mode--indent-styles 'cpp))))

  (use-package c-ts-mode
	:ensure nil ;; Built-in to Emacs 29+
	:hook ((c++-ts-mode . lsp))
	:custom
	(c-ts-mode-indent-offset 4) ;; 4 spaces for indentation
	(indent-tabs-mode t) ;; Use tabs
	(c-ts-mode-indent-style #'my/c-ts-indent-style)
	:init
	;; Remap C++ mode to use Tree-sitter
	(add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode))))

;; Keybinding

(defun paste-without-indent ()
  (interactive)
  (if (region-active-p)
      (let ((electric-indent-mode nil))
	    (clipboard-yank))
    (clipboard-yank)
    )) ;; Paste

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
      (clipboard-kill-ring-save (region-beginning) (region-end))
    (let ((start (line-beginning-position))
          (end (line-end-position)))
      (clipboard-kill-ring-save start end))))

(defun delete-current-line ()
  "Delete the current line without copying it to the kill ring."
  (interactive)
  (delete-region (line-beginning-position) (line-end-position))
  (delete-char 1)) ;; Removes the newline character

(global-set-key (kbd "C-v") 'clipboard-yank)
;;(global-set-key (kbd "C-v") 'isearch-yank-kill)

(global-set-key (kbd "C-y") 'my-line-save)
(global-set-key (kbd "C-z") 'undo)
(global-set-key (kbd "C-r") 'counsel-rg)

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

(setq lsp-keymap-prefix "C-c")

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


;; (global-set-key (kbd "C-w") 'jump-to-next-word)
;; (global-set-key (kbd "C-q") 'jump-to-previous-word)

(global-set-key (kbd "C-r") 'backward-char)
(global-set-key (kbd "C-q") 'backward-same-syntax)
(global-set-key (kbd "C-w") 'forward-same-syntax)

(global-set-key (kbd "C-<right>") 'jump-to-next-word)
(global-set-key (kbd "C-<left>") 'jump-to-previous-word)

(defun select-line ()
  "Select line under cursor"
  (interactive)
  (move-beginning-of-line nil)
  (set-mark-command nil)
  (move-end-of-line nil))

(global-set-key (kbd "C-c l") 'select-line)
(global-set-key (kbd "C-c w") 'select-word-under-cursor)
(global-set-key (kbd "C-c d") 'delete-current-line)

(global-set-key (kbd "C-x c") 'compile)
(global-set-key (kbd "M-s M-s") 'isearch-forward)
;; (global-set-key (kbd "C-c u") 'uncomment-region
(global-unset-key (kbd "C-x C-c"))

(global-set-key (kbd "C-M-0") 'sp-forward-slurp-sexp)
(global-set-key (kbd "C-M-9") 'sp-backward-slurp-sexp)
(global-set-key (kbd "C-}") 'sp-forward-barf-sexp)
(global-set-key (kbd "C-{") 'sp-backward-barf-sexp)

(global-set-key (kbd "M-f") 'sp-forward-sexp)
(global-set-key (kbd "M-b") 'sp-backward-sexp)

(when (eq init-config 'HOME)
  (global-set-key (kbd "C-x p a") 'ff-find-other-file))

(defun select-word-under-cursor ()
  "Select the word under the cursor."
  (interactive)
  (skip-chars-backward "[:word:]")
  (set-mark-command nil)
  (skip-chars-forward "[:word:]"))
(put 'upcase-region 'disabled nil)
