;; -*- lexical-binding: t -*-


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

;; ---------------------------------------------------------------------------------------------

(require 'cl-lib)

(cl-defstruct project-state
  config
  exe-name)


(defvar my-cmake-generators '("Ninja Multi-Config" "Unix Makefiles"))

(defvar my-cmake-session-configs nil)

(defun my-cmake-tokenize-string (cmake-content)
  "Tokenize CMake content into identifiers and parentheses."
  (let ((index 0)
        (result-tokens '()))
    (while (< index (length cmake-content))
      (let ((current-char (aref cmake-content index)))
        (cond
         ((or (eq (char-syntax current-char) ?w)
              (eq current-char ?_)
              (eq current-char ?.))
          (let ((token ""))
            (while (and (< index (length cmake-content))
                        (let ((ch (aref cmake-content index)))
                          (or (eq (char-syntax ch) ?w)
                              (eq ch ?_)
                              (eq ch ?.))))
              (setq token (concat token (char-to-string (aref cmake-content index))))
              (setq index (1+ index)))
            (push token result-tokens)))
         ((memq current-char '(?\( ?\)))
          (push (char-to-string current-char) result-tokens)
          (setq index (1+ index)))
         (t (setq index (1+ index))))))
    (nreverse result-tokens)))

(defun my-cmake-file-to-string (pathname)
  "Return the entire contents of PATHNAME as a string."
  (with-temp-buffer
    (insert-file-contents pathname)
    (buffer-string)))

(defun my-cmake-process-exe-name (exe-name)
  "Return EXE-NAME with .exe suffix if running on Windows."
  (if (eq system-type 'windows-nt)
      (concat exe-name ".exe")
    exe-name))

(defun my-cmake-get-exe-from-file (cmake-lists-path)
  "Extract the target name from an add_executable line in CMakeLists.txt."
  (let* ((tokens (my-cmake-tokenize-string
                  (my-cmake-file-to-string cmake-lists-path)))
         (pos (cl-position "add_executable" tokens :test #'string=)))
    (when (and pos (>= (length tokens) (+ pos 2)))
      (my-cmake-process-exe-name (nth (+ pos 2) tokens)))))

(defun make-project-default-state()
  (let* ((project-root (my-cmake-get-project-root))
         (cmake-dir   (locate-dominating-file project-root "CMakeLists.txt"))
         (cmake-file  (expand-file-name "CMakeLists.txt" cmake-dir))
         (exe-name    (my-cmake-get-exe-from-file cmake-file)))
    (make-project-state :config "Debug" :exe-name (if exe-name exe-name ""))))

(defun my-cmake-get-project-state (project-name)
  (let ((entry (assoc project-name my-cmake-session-configs)))
    (unless entry
      (setq entry (cons project-name (make-project-default-state)))
      (push entry my-cmake-session-configs))
    (cdr entry)))

(defun my-cmake-get-project-root()
  (project-root (project-current)))

(defun my-cmake-is-cmake-project ()
  (let* ((my-project-root (my-cmake-get-project-root))
         (cmake-lists (locate-dominating-file my-project-root "CMakeLists.txt")))
    (and my-project-root cmake-lists)))

(defun my-cmake-mode-line ()
  "Return the current CMake config for mode line."
  
  (when (my-cmake-is-cmake-project)
    ;; (format " Config:%s" (my-cmake-get-project-config (project-root (project-current))))))
    (format " Config:%s" (project-state-config (my-cmake-get-project-state (project-root (project-current)))))))


(defun my-cmake-switch-config (config)
  "Switch the CMake config for the current project."
  (interactive
   (list (completing-read "Choose config: " '("Debug" "Release"))))
  (let ((state (my-cmake-get-project-state (project-root (project-current)))))
    
    (setf (project-state-config state) config))
  ;; Update all mode lines
  (force-mode-line-update t))

(define-minor-mode my-cmake-mode
  "A custom minor mode with buffer-local lighter."
  :lighter (:eval (my-cmake-mode-line)))

(define-globalized-minor-mode my-cmake-global-mode
  my-cmake-mode
  (lambda () (my-cmake-mode 1)))

(defun my-cmake-set-project-exe-name (exe-name)
  (interactive "sExecutable name: ")
  (when (my-cmake-is-cmake-project)
    (let ((state (my-cmake-get-project-state (my-cmake-get-project-root))))
      (setf (project-state-exe-name state) exe-name))))


(defun my-cmake-get-project-exe-name()
  (interactive)
  (when (my-cmake-is-cmake-project)
    (let ((state (my-cmake-get-project-state (my-cmake-get-project-root))))
      (message (project-state-exe-name state)))))

(defun my-cmake-save-project-state()
  (interactive)
  (with-temp-file "~/.emacs.d/cmake-project-states.el"
    (prin1 my-cmake-session-configs (current-buffer))))

;; TODO try to fix these wierd errors
;; error in process sentinel: let: Symbol’s value as variable is void: project-root
;; error in process sentinel: Symbol’s value as variable is void: project-root

(defun my-cmake-config (generator)
  "Run cmake in the project's build directory."
  (interactive
   (list (completing-read "Generator: " my-cmake-generators)))
  ;; Find the project root by locating CMakeLists.txt
  (let* ((my-project-root (project-root (project-current)))
         (cmake-lists (locate-dominating-file my-project-root "CMakeLists.txt")))
    (unless my-project-root
      (error "Setup project first"))
    
    (unless cmake-lists
      (error "CMakeLists.txt in root"))

    ;; (global-set-key (kbd "<f5>") 'my-cmake-build)
    ;; Run the build using Emacs' compile command
    (let ((default-directory my-project-root))
      (delete-directory "build" t)
      (compile (format "cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -G \"%s\"" generator))
      (add-hook 'compilation-finish-functions
                (lambda (_buf _msg)
                  (let ((src (expand-file-name "build/compile_commands.json" my-project-root))
                        (dst (expand-file-name "compile_commands.json" my-project-root)))
                    (when (file-exists-p src)
                      (copy-file src dst t)
                      (message "Copied %s -> %s" src dst))))))))

(defun my-cmake-build-with-callback (post-build-callback)
  (unless (my-cmake-is-cmake-project)
    (error "No cmake or project is configured"))
  
  (let ((default-directory project-root))
    ;; (compile (format "cmake --build build --config %s" (my-cmake-get-project-config (project-root (project-current))))))))
    (compile (format "cmake --build build --config %s" (project-state-config (my-cmake-get-project-state (my-cmake-get-project-root)))))
    (add-hook 'compilation-finish-functions
              (lambda (_buff _msg)
                (funcall post-build-callback)))))

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
      ;; (compile (format "cmake --build build --config %s" (my-cmake-get-project-config (project-root (project-current))))))))
      (compile (format "cmake --build build --config %s" (project-state-config (my-cmake-get-project-state (project-root (project-current)))))))))

;; (defun my-cmake-debug()
;;   "Run cmake in the project's build directory."
;;   (interactive)
;;   ;; Find the project root by locating CMakeLists.txt
;;   (let* ((project-root (project-root (project-current)))
;;          (build-dir (expand-file-name "build" project-root)))
;;     (unless project-root
;;       (error "Setup project first"))
;;     ;; Run the build using Emacs' compile command
;;     (let ((default-directory project-root))
;;       (gdb "build/Debug/src/HelloFriend"))))
