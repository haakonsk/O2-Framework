(defun o2-javascript-or-css-indent-line ()
  (let ((previous-indent 0)
        (new-indent      0)
        (num-blank-lines 0)
        (previous-line   (o2-read-line -1))
       )
    (save-excursion
      ; Remove tabs if they're present:
      (if (string-match "\t" previous-line)
          (progn
            (o2-fix-tabs)
            (setq previous-line (o2-read-line -1))
            (message "prev-line: %s" previous-line)
          )
      )

      (beginning-of-line)
      ; Check if current line starts with a closing parenthesis or previous line ends in one
      (if (or (looking-at " *}")
              (looking-at " *[*]/")
              (string-match "[*]/ *$" previous-line)
              (string-match "} *$"    previous-line))
          (setq new-indent -2) ; Adjust indentation
      )
      (forward-line -1)
      (while (looking-at "^ *$") ; Blank line
        (forward-line -1)
        (setq num-blank-lines (1+ num-blank-lines))
      )
      (setq previous-indent (skip-chars-forward " "))
      (setq new-indent      (+ previous-indent new-indent))
      (if (or (and (looking-at "\\(.*\\){\\(.*\\)")
                   (not (string-match "//" (match-string 1)))
                   (not (string-match "}"  (match-string 2)))
                   )
              (looking-at ".*/[*]"))
          (setq new-indent (+ new-indent 2))
      )
      (forward-line (1+ num-blank-lines))
      (indent-line-to new-indent)
    )
    (skip-chars-forward " ")
  )
)

(defun o2-insert-end-bracket ()
  (insert "\n")
  (o2ml-indent-line)
  (insert "\n}")
  (o2ml-indent-line)
  (beginning-of-line)
  (goto-char (- (point) 1))
)

(defun o2-fix-tabs ()
  (if indent-tabs-mode
      (progn
        (setq indent-tabs-mode nil)
        (o2ml-remove-tabs)
        (message "%s\n%s\n%s" "I found tab characters in your template file, so I removed them for you."
                 "I suggest adding the following line to your .emacs file:"
                 "  (setq-default indent-tabs-mode nil)")
      )
    (o2ml-remove-tabs)
    (message "%s" "I found tab characters in your template file, so I removed them for you.")
  )
)

;--------------------------------------------------------
;--- Convenience functions
;--------------------------------------------------------

(defun o2-list-contains-p (list elm)
  (let ((found))
    (while (and list
                (not found))
      (if (equal (car list) elm)
          (setq found t)
      )
      (setq list (cdr list))
    )
    found
  )
)

; Only checks current line
(defun o2-backward-looking-at (regexp)
;  (interactive "sRegexp: ")
  (setq regexp (concat regexp "$"))
  (let ((counter 0)
        (found)
        (string "")
        (column-number-of-point (o2-column-number))
        (line (o2-read-line)))
    (while (and (not found)
                (> column-number-of-point counter))
      (setq counter (1+ counter))
      (setq string (substring line (- column-number-of-point counter) column-number-of-point))
      (if (string-match regexp string)
          (setq found t)
      )
    )
    (if found
        string
      nil
    )
  )
)

(defun o2-column-number ()
  (save-excursion
    (let ((end (point))
          (start))
      (beginning-of-line)
      (setq start (point))
      (- end start)
    )
  )
)

(defun o2-read-line (&optional delta-lines)
  (save-excursion
    (beginning-of-line)
    (if delta-lines
        (forward-line delta-lines)
    )
    (looking-at "[^\n]*")
    (match-string 0)
  )
)

(defun o2-previous-char (&optional num-chars)
  (if (not num-chars)
      (setq num-chars 1)
  )
  (let ((start-pos (- (point) num-chars)))
    (buffer-substring start-pos (+ start-pos 1))
  )
)

(provide 'o2-util)
