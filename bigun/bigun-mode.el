;; -*- lexical-binding: t -*-
(require 'cl-lib)

(cl-defstruct project-state
  config
  source-dir
  cmd-args
  cmake-args
  exe-name)

(defun project-state-exe-name-get-full-path(project-state)
  (expand-file-name
   (project-state-exe-name project-state)
   (expand-file-name (project-state-config project-state)
                     (expand-file-name "build" (project-state-source-dir project-state)))))

(define-minor-mode bigun-mode
  "A custom minor mode with buffer-local lighter."
  :lighter (:eval (bigun-mode-line)))

(define-globalized-minor-mode bigun-global-mode
  bigun-mode
  (lambda () (bigun-mode 1)))

(defvar bigun-generators '("Ninja Multi-Config" "Unix Makefiles"))

(defvar bigun-session-configs nil)

(defun bigun-tokenize-string (cmake-content)
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

(defun bigun-file-to-string (pathname)
  "Return the entire contents of PATHNAME as a string."
  (with-temp-buffer
    (insert-file-contents pathname)
    (buffer-string)))

(defun bigun-process-exe-name (exe-name)
  "Return EXE-NAME with .exe suffix if running on Windows."
  (if (eq system-type 'windows-nt)
      (concat exe-name ".exe")
    exe-name))

(defun bigun-get-exe-from-file (cmake-lists-path)
  "Extract the first target name from add_executable-like lines in CMakeLists.txt.
Supports both add_executable and qt_add_executable."
  (let* ((tokens (bigun-tokenize-string
                  (bigun-file-to-string cmake-lists-path)))
         (keywords '("add_executable" "qt_add_executable"))
         (pos 0)
         result)
    (while (and (not result) (< pos (length tokens)))
      (when (member (nth pos tokens) keywords)
        ;; ensure there is a target name after keyword
        (when (>= (length tokens) (+ pos 2))
          (setq result (bigun-process-exe-name (nth (+ pos 2) tokens)))))
      (setq pos (1+ pos)))
    result))


(defun find-cmakelists-down (dir)
  "Search downward from DIR for the nearest CMakeLists.txt.
Return the full path if found, or nil if not."
  (when dir
    (let ((result nil))
      (dolist (file (directory-files-recursively dir "^CMakeLists\\.txt$" t))
        (unless result
          (setq result file)))
      result)))

(defun make-project-default-state()
  (let* ((project-root (bigun-get-project-root))
         (cmake-file  (find-cmakelists-down project-root))
         (cmake-dir   (file-name-directory cmake-file))
         (exe-name    (bigun-get-exe-from-file cmake-file)))
    (make-project-state
     :config "Debug"
     :source-dir cmake-dir
     :exe-name (if exe-name exe-name "")
     :cmd-args ""
     :cmake-args "")))

(defun bigun-get-project-state (project-name)
  (let ((entry (assoc project-name bigun-session-configs)))
    (unless entry
      (setq entry (cons project-name (make-project-default-state)))
      (push entry bigun-session-configs))
    (cdr entry)))

(defun bigun-get-project-root()
  (when (project-current)
    (project-root (project-current))))

(defun bigun-is-cmake-project ()
  (let* ((my-project-root (bigun-get-project-root))
         (cmake-lists (when my-project-root (find-cmakelists-down my-project-root))))
    (and my-project-root cmake-lists)))

(defun bigun-mode-line ()
  "Return the current CMake config for mode line."
  
  (when (bigun-is-cmake-project)
    ;; (format " Config:%s" (bigun-get-project-config (project-root (project-current))))))
    (format " Config:%s" (project-state-config (bigun-get-project-state (project-root (project-current)))))))


(defun bigun-switch-config (config)
  "Switch the CMake config for the current project."
  (interactive
   (list (completing-read "Choose config: " '("Debug" "Release"))))
  (let ((state (bigun-get-project-state (project-root (project-current)))))
    
    (setf (project-state-config state) config))
  ;; Update all mode lines
  (force-mode-line-update t))


(defun bigun-set-project-exe-name (exe-name)
  (interactive "sExecutable name: ")
  (when (bigun-is-cmake-project)
    (let ((state (bigun-get-project-state (bigun-get-project-root))))
      (setf (project-state-exe-name state) exe-name))))


(defun bigun-get-project-exe-name()
  (interactive)
  (when (bigun-is-cmake-project)
    (let ((state (bigun-get-project-state (bigun-get-project-root))))
      (message (project-state-exe-name state)))))

(defun bigun-save-project-state()
  (interactive)
  (with-temp-file "~/.emacs.d/bigun-project-states.el"
    (prin1 bigun-session-configs (current-buffer))))

(defun bigun-restore-project-state ()
  "Restore `bigun-session-configs` from ~/.emacs.d/bigun-project-states.el."
  (interactive)
  (let ((file "~/.emacs.d/bigun-project-states.el"))
    (when (file-exists-p file)
        (with-temp-buffer
          (insert-file-contents file)
          (setq bigun-session-configs (read (current-buffer)))))))

(defun my-run-compile-with-callback (command callback)
  "Run compile with COMMAND, then CALLBACK once when finished."
  (let (fn)
    (setq fn
          (lambda (buf msg)
            (when (and callback (string-match "finished" msg))
              (funcall callback))
            (remove-hook 'compilation-finish-functions fn)))
    (add-hook 'compilation-finish-functions fn)
    (compile command)))


(defun bigun-init (generator)
  "Run cmake in the project's build directory."
  (interactive
   (list (completing-read "Generator: " bigun-generators)))
  
  (unless (bigun-is-cmake-project)
    (error "No cmake or project is configured"))
  
  (let ((default-directory (bigun-get-project-root))
        (project-source-dir (project-state-source-dir (bigun-get-project-state (bigun-get-project-root)))))
    (delete-directory (expand-file-name "build" project-source-dir) t)
    (my-run-compile-with-callback (format "cmake -S %s -B %s -DCMAKE_EXPORT_COMPILE_COMMANDS=ON %s -G \"%s\""
                                          project-source-dir
                                          (expand-file-name "build" project-source-dir)
                                          (project-state-cmake-args (bigun-get-project-state (bigun-get-project-root)))
                                          generator)
                                  (lambda ()
                                    (let ((src (expand-file-name "build/compile_commands.json" project-source-dir))
                                          (dst (expand-file-name "compile_commands.json" (bigun-get-project-root))))
                                      (when (file-exists-p src)
                                        (copy-file src dst t)
                                        (message "Copied %s -> %s" src dst)))))))




(defun bigun-build-with-callback (post-build-callback)
  (unless (bigun-is-cmake-project)
    (error "No cmake or project is configured"))
  
  (let ((default-directory (bigun-get-project-root))
        (project-state (bigun-get-project-state (bigun-get-project-root))))
    (my-run-compile-with-callback (format "cmake --build %s --config %s"
                                          (expand-file-name "build" (project-state-source-dir project-state))
                                          (project-state-config project-state))
                                  post-build-callback)))

(defun bigun-build ()
  "Run cmake in the project's build directory."
  (interactive)
  (bigun-build-with-callback nil))

(defun bigun-build-and-run ()
  (interactive)
  (bigun-build-with-callback (lambda ()
                                  (let ((project-state (bigun-get-project-state (bigun-get-project-root))))
                                    (compile (format "%s %s"
                                                     (project-state-exe-name-get-full-path project-state)
                                                     (project-state-cmd-args project-state)))))))

(defun bigun-run-gdb()
  (interactive)
  ;; TODO test this check on buffer without cmake
  (unless (bigun-is-cmake-project)
    (error "No cmake or project is configured"))
  (let ((default-directory (bigun-get-project-root))
        (project-state (bigun-get-project-state (bigun-get-project-root))))
    (bigun-build-with-callback (lambda ()
                                 (let ((default-directory (bigun-get-project-root)))
                                   (gdb (format "gdb -i=mi --args %s %s" (project-state-exe-name-get-full-path project-state) (project-state-cmd-args project-state))))))))

(defvar bigun-command-line-args ""
  "Stores the last command line arguments entered by `bigun-set-command-line-args`.")

(defun bigun-set-command-line-args (cmd-args)
  "Prompt for command line arguments, pre-filling with the last ones used.
The result is stored in `bigun-command-line-args`."
  (interactive
   (list (read-string
          "Enter command line args: "
          (when (bigun-is-cmake-project)
              (project-state-cmd-args (bigun-get-project-state (bigun-get-project-root)))))))
  (when (bigun-is-cmake-project)
    (let ((state (bigun-get-project-state (bigun-get-project-root))))
      (setf (project-state-cmd-args state) cmd-args)
      (bigun-save-project-state))))


(defun bigun-set-cmake-args (cmake-args)
  (interactive
   (list (read-string
          "Enter cmake args: "
          (when (bigun-is-cmake-project)
            (project-state-cmake-args (bigun-get-project-state (bigun-get-project-root)))))))
  (when (bigun-is-cmake-project)
    (let ((state (bigun-get-project-state (bigun-get-project-root))))
      (setf (project-state-cmake-args state) cmake-args)
      (bigun-save-project-state))))

(provide 'bigun-mode)

