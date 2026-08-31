;;; gdb-layout.el --- custom two-monitor gdb-many-windows layout -*- lexical-binding: t; -*-
;;
;; Drop this in your init (or `(load "/path/to/gdb-layout.el")` from it).
;; It replaces the stock 6-pane `gdb-many-windows' layout with:
;;
;; Monitor 1 (the frame GDB was started from):
;;
;;     +-----------+----------------+
;;     | gdb menu  | variable watch |
;;     +-----------+----------------+
;;     |           | callstack      |
;;     | source    +----------------+
;;     |           | program output |
;;     +-----------+----------------+
;;
;; Monitor 2 (a second frame, auto-placed on whichever monitor Emacs
;; is NOT currently on): registers / threads / breakpoints / memory,
;; one per quadrant.
;;
;; The "source" pane always shows the buffer that was current when you
;; ran M-x gdb, not whatever file GDB happens to stop in first.

(require 'seq)

(with-eval-after-load 'gdb-mi

  (defvar my-gdb-source-buffer nil
    "Buffer that was current when `gdb' was invoked.
Used as the source-code window when the custom `gdb-many-windows'
layout is built, instead of whatever file GDB happens to stop in.")

  (defvar my-gdb-secondary-frame nil
    "Frame parked on the \"other\" monitor that holds the auxiliary
GDB buffers (registers, threads, breakpoints, memory).")

  ;; Remember which buffer we were in when `gdb' was invoked, before
  ;; `gud-query-cmdline' pops up the minibuffer to ask for the command line.
  (advice-add 'gdb :before
              (lambda (&rest _)
                (setq my-gdb-source-buffer (current-buffer))))

  (defun my-gdb--other-monitor-workarea (frame)
    "Return (X Y WIDTH HEIGHT) of the usable area of a monitor other
than the one FRAME is on.  Falls back to FRAME's own monitor if
only one monitor is available."
    (let* ((monitors (display-monitor-attributes-list))
           (here-geo (alist-get 'geometry (frame-monitor-attributes frame)))
           (other (or (seq-find
                       (lambda (m) (not (equal (alist-get 'geometry m) here-geo)))
                       monitors)
                      (frame-monitor-attributes frame))))
      (alist-get 'workarea other)))

  (defun my-gdb--secondary-frame ()
    "Return a live frame parked on the secondary monitor, creating and
positioning it if necessary."
    (unless (frame-live-p my-gdb-secondary-frame)
      (setq my-gdb-secondary-frame (make-frame '((name . "*GDB data*")))))
    (let ((wa (my-gdb--other-monitor-workarea (selected-frame))))
      (when wa
        (pcase-let ((`(,x ,y ,w ,h) wa))
          (set-frame-position my-gdb-secondary-frame x y)
          (set-frame-size my-gdb-secondary-frame w h t))))
    my-gdb-secondary-frame)

  (defun my-gdb-setup-windows ()
    "Custom replacement for `gdb-setup-windows'.  See file header for
the layout this produces."
    ;; Make sure the data-providing buffers exist before we display them
    ;; (mirrors what stock `gdb-setup-windows' does).
    (gdb-get-buffer-create 'gdb-locals-values-buffer)
    (gdb-get-buffer-create 'gdb-locals-buffer)
    (gdb-get-buffer-create 'gdb-stack-buffer)
    (gdb-get-buffer-create 'gdb-breakpoints-buffer)
    (gdb-get-buffer-create 'gdb-threads-buffer)
    (gdb-get-buffer-create 'gdb-registers-buffer)
    (gdb-get-buffer-create 'gdb-memory-buffer)

    ;; ---------- monitor 1: menu / source / watch / callstack / output ----------
    (set-window-dedicated-p (selected-window) nil)
    (switch-to-buffer gud-comint-buffer)
    (delete-other-windows)
    (let* ((menu   (selected-window))
           (right  (split-window menu nil 'right))
           ;; menu keeps 8 lines at the top; `source' gets the rest (the
           ;; majority of the column) below it.
           (source (split-window menu 8 'below))
           (watch  right)
           (stack  (split-window watch (/ (window-total-height watch) 3) 'below))
           (output (split-window stack (/ (window-total-height stack) 2) 'below)))
      (set-window-buffer source (or (and (buffer-live-p my-gdb-source-buffer)
                                          my-gdb-source-buffer)
                                     (gdb-get-source-buffer)
                                     (list-buffers-noselect)))
      (setq gdb-source-window-list (list source))
      (gdb-set-window-buffer (gdb-locals-buffer-name) t watch)
      (gdb-set-window-buffer (gdb-stack-buffer-name) t stack)
      (gdb-set-window-buffer (gdb-get-buffer-create 'gdb-inferior-io) t output)
      (select-window menu))

    ;; ---------- monitor 2: registers / threads / breakpoints / memory ----------
    (let ((aux (my-gdb--secondary-frame)))
      (with-selected-frame aux
        (set-window-dedicated-p (selected-window) nil)
        (switch-to-buffer (gdb-get-buffer-create 'gdb-breakpoints-buffer))
        (delete-other-windows)
        (let* ((bp  (selected-window))
               (th  (split-window bp nil 'right))
               (reg (split-window bp nil 'below))
               (mem (split-window th nil 'below)))
          (gdb-set-window-buffer (gdb-breakpoints-buffer-name) t bp)
          (gdb-set-window-buffer (gdb-threads-buffer-name) t th)
          (gdb-set-window-buffer (gdb-registers-buffer-name) t reg)
          (gdb-set-window-buffer (gdb-memory-buffer-name) t mem)))
      (make-frame-visible aux)
      (raise-frame aux)))

  (advice-add 'gdb-setup-windows :override #'my-gdb-setup-windows)

  (setq gdb-many-windows t))

(provide 'gdb-layout)
;;; gdb-layout.el ends here
