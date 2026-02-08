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
