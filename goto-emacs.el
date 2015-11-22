(defun goto-highlight-overlay-face ()
      '(:weight bold
	:background "yellow"
	:foreground "red"
	))

; http://stackoverflow.com/a/14454756/341106#how-to-highlight-a-particular-line-in-emacs
(defun goto-find-overlays-specifying (prop pos)
  (let ((overlays (overlays-at pos))
        found)
    (while overlays
      (let ((overlay (car overlays)))
        (if (overlay-get overlay prop)
            (setq found (cons overlay found))))
      (setq overlays (cdr overlays)))
    found)
)

(defun goto-remove-all-highlight ()
  (interactive)
  (remove-overlays (point-min) (point-max))
  )

(defun goto-highlight-or-dehighlight-line (&optional force_highlight)
  (interactive)
  (if (and (eq force_highlight nil)
	   (find-overlays-specifying
	    'goto-highlight-overlay-marker
	    (line-beginning-position)))
      ; remove overlay
      (remove-overlays (line-beginning-position) (+ 1 (line-end-position)))
    
    (let ; set overlay
	((overlay-highlight (make-overlay
			     (line-beginning-position)
			     (+ 1 (line-end-position)))))
         (overlay-put overlay-highlight 'face (goto-highlight-overlay-face))
         (overlay-put overlay-highlight 'goto-highlight-overlay-marker t)
	)
    )
  )

(defun goto-and-highlight (__path from) ; format filename[:lineno]
  " Originally xah-open-file-at-cursor from ErgoEmacs 
URL `http://ergoemacs.org/emacs/emacs_open_file_path_fast.html'"
  (if (string-match "^\\`\\(.+?\\):\\([0-9]+\\)\\'" __path)
      (progn ; with goto line
	(let ; split path into __fpath and __line-num
	    ((__fpath (match-string 1 __path))
	     (__line-num (string-to-number (match-string 2 __path))))
	  (if (file-exists-p __fpath)
	      (progn
		(find-file __fpath)
		(goto-line __line-num)
		(remove-all-highlight)
		(goto-highlight-or-dehighlight-line 1)
		(message (format "Jumped to %s:%s from %s." __fpath __line-num from))
		)
	    (message (format "File '%s' doesn't exist." __fpath))
	  )
	)
      )				
    (progn ; without goto line
      (if (file-exists-p __path)
	  (find-file __path)
	(message (format "File '%s' doesn't exist.." __path))
      )
    )
  )
)

(setq goto-stack nil)
(defun goto-stacked ()
  (interactive)
  (if (eq goto-stack nil)
      (message "Nothing stacked.")
    (progn
      (goto-and-highlight goto-stack "stack")
      (setq goto-stack nil)
      )
    )
  )

(setq goto-auto-go 0)
(defun goto-auto-go-and-highlight (__path from) ; format filename[:lineno]
  (if (eq goto-auto-go 1)
      (goto-and-highlight __path from)
      (progn ; don't auto go
	(setq goto-stack __path)
	(message (format "Received jump request to %s from %s. Run 'goto-stacked to go." __path from))
	)
      )
  )

(defun toggle-goto-auto-go-and-highlight ()
  (interactive)
  (if (eq goto-auto-go 1)
      (progn
	(setq goto-auto-go 0)
	(message "Disabling auto go and highlight."))
    (progn
	(setq goto-auto-go 1))
	(message "Enabling auto go and highlight.")
    )
)

; example
(goto-highlight-or-dehighlight-line) ; highlight current line
(goto-remove-all-highlight) ; cleanup
(setq goto-auto-go 1)
(goto-auto-and-highlight "/tmp/test:5" "tester")
(toggle-goto-auto-go-and-highlight)
(goto-auto-and-highlight "/tmp/test:15" "tester")
(goto-stacked)

; to bind
(goto-stacked) ; go to saved target
(toggle-goto-auto-go-and-highlight) ; auto go or not
(goto-remove-all-highlight) ; reset overlay

(server-start "client")
