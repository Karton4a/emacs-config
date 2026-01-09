(defun insert-define-guard()
  (interactive)
  (let ((define-name (upcase (replace-regexp-in-string "\\." "_" (buffer-name)))))
    (message "Define name %s" define-name)
    (save-excursion
      (goto-char (point-min))
      (insert (format "#ifndef %s\n#define %s\n" define-name define-name))
      (goto-char (point-max))
      (insert (format "#endif //%s" define-name)))))
