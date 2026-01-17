;; -*- lexical-binding: t -*-


(defvar-local my-cmake-lighter " Debug"
  "Buffer-local lighter for `my-mode'.")

(defvar-local my-cmake-config-var "Debug"
  "Buffer-local lighter for `my-mode'.")

(defun my-cmake-switch-config (config)
  "Toggle the mode line lighter in the current buffer."
  (interactive
   (list (completing-read "Choose config: " '("Debug" "Release"))))
  (setq my-cmake-lighter (format " %s" config))
  (setq my-cmake-config-var config)
  (force-mode-line-update))

(define-minor-mode my-cmake
  "A custom minor mode with buffer-local lighter."
  :lighter my-cmake-lighter)

(defun insert-define-guard()
  "Insert a C-style header guard at the beginning and end of the buffer."
  (interactive)
  (let ((define-name (upcase (replace-regexp-in-string "\\." "_" (buffer-name)))))
    (message "Define name %s" define-name)
    (save-excursion
      (goto-char (point-min))
      (insert (format "#ifndef %s\n#define %s\n" define-name define-name))
      (goto-char (point-max))
      (insert (format "\n#endif //%s" define-name)))))

(defun copy-buffer-name-to-clipboard ()
  "Copy the current buffer name to the clipboard."
  (interactive)
  (kill-new (buffer-name))
  (message "Buffer name '%s' copied to clipboard" (buffer-name)))

(defun copy-file-path-to-clipboard ()
  "Copy the full path of the current file to the clipboard."
  (interactive)
  (if buffer-file-name
      (progn
        (kill-new buffer-file-name)
        (message "Copied file path: %s" buffer-file-name))
    (message "This buffer is not visiting a file.")))



;; TODO try to fix these wierd errors
;; error in process sentinel: let: Symbol’s value as variable is void: project-root
;; error in process sentinel: Symbol’s value as variable is void: project-root

(defun my-cmake-config ()
  "Run cmake in the project's build directory."
  (interactive)
  ;; Find the project root by locating CMakeLists.txt
  (let* ((my-project-root (project-root (project-current)))
         (cmake-lists (locate-dominating-file my-project-root "CMakeLists.txt")))
    (unless my-project-root
      (error "Setup project first"))
    
    (unless cmake-lists
      (error "CMakeLists.txt in root"))

    (global-set-key (kbd "<f5>") 'my-cmake-build)
    ;; Run the build using Emacs' compile command
    (let ((default-directory my-project-root))
      (compile "cmake -S . -B build/Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cmake -S . -B build/Debug -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
      (add-hook 'compilation-finish-functions
                (lambda (_buf _msg)
                  (let ((src (expand-file-name "build/Debug/compile_commands.json" my-project-root))
                        (dst (expand-file-name "compile_commands.json" my-project-root)))
                    (when (file-exists-p src)
                      (copy-file src dst t)
                      (message "Copied %s -> %s" src dst))))))))

(defun my-cmake-build ()
  "Run cmake in the project's build directory."
  (interactive)
  ;; Find the project root by locating CMakeLists.txt
  (let* ((project-root (project-root (project-current)))
         (build-dir (locate-dominating-file project-root "CMakeLists.txt")))
    (unless project-root
      (error "Setup project first"))
    
    ;; Run the build using Emacs' compile command
    (let ((default-directory project-root))
      (compile (format "cmake --build build/%s --config %s" my-cmake-config-var my-cmake-config-var)))))

(defun my-cmake-debug()
  "Run cmake in the project's build directory."
  (interactive)
  ;; Find the project root by locating CMakeLists.txt
  (let* ((project-root (project-root (project-current)))
         (build-dir (expand-file-name "build" project-root)))
    (unless project-root
      (error "Setup project first"))
    ;; Run the build using Emacs' compile command
    (let ((default-directory project-root))
      (gdb "build/Debug/src/HelloFriend"))))
