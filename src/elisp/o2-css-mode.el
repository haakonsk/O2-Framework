(load "o2-util.el")
(require 'o2-util)

(load "o2-css-stuff")
(require 'o2-css-stuff)

(defgroup o2-css-mode-fonts nil
  "Font-lock support for o2-css."
  :group 'programming)

(defface o2-css-font-lock-comment-face
  `((((class color) (background light)) (:foreground ,"Goldenrod"))
    (((class color) (background dark))  (:foreground ,"Goldenrod")))
  "Font used on javascript or css comments"
  :group 'o2-css-mode-fonts
)
(defface o2-css-font-lock-id-face
  `((((class color) (background light)) (:foreground ,"#bb33bb"))
    (((class color) (background dark))  (:foreground ,"#99ccff")))
  "Font used on css ids"
  :group 'o2-css-mode-fonts
)
(defface o2-css-font-lock-class-face
  `((((class color) (background light)) (:foreground ,"#5500ff"))
    (((class color) (background dark))  (:foreground ,"#dddd55")))
  "Font used on css class names"
  :group 'o2-css-mode-fonts
)
(defface o2-css-font-lock-string-face
  `((((class color) (background light)) (:foreground ,"#dd6644"))
    (((class color) (background dark))  (:foreground ,"#dd6644")))
  "Font used on strings"
  :group 'o2-css-mode-fonts
)
(defface o2-css-font-lock-important-face
  `((((class color) (background light)) (:foreground ,"#ff0000"))
    (((class color) (background dark))  (:foreground ,"#ff0000")))
  "Font used on strings"
  :group 'o2-css-mode-fonts
)
(defface o2-css-font-lock-keyword-face
  `((((class color) (background light)) (:foreground ,"#33bb33"))
    (((class color) (background dark))  (:foreground ,"#33bb33")))
  "Font used on strings"
  :group 'o2-css-mode-fonts
)
(defface o2-css-font-lock-pseudo-face
  `((((class color) (background light)) (:foreground ,"#33bb33"))
    (((class color) (background dark))  (:foreground ,"#77ff77")))
  "Font used on strings"
  :group 'o2-css-mode-fonts
)
(defface o2-css-font-lock-selector-face
  `((((class color) (background light)) (:foreground ,"#6666bb"))
    (((class color) (background dark))  (:foreground ,"#aaaaff")))
  "Font used on strings"
  :group 'o2-css-mode-fonts
)

(defvar o2-css-mode-syntax-table nil
  "Syntax table for o2-css mode.")

(if o2-css-mode-syntax-table
    ()
  (setq o2-css-mode-syntax-table (make-syntax-table text-mode-syntax-table))
)

(defconst o2-css-font-lock-keywords-1
  (list
   '(" ! *important"                         . 'o2-css-font-lock-important-face)
   '("@\\(import\\|media\\)"                 . 'o2-css-font-lock-keyword-face)
   '("\\<\\(aural\\|braille\\|emboss\\|handheld\\|print\\|projection\\|screen\\|tty\\|tv\\)\\>" 1 'o2-css-font-lock-keyword-face t)
   '(":\\(hover\\|focus\\|before\\|after\\)" . 'o2-css-font-lock-pseudo-face)
   ; XXX first-child etc
   '("\\(\"\"\\|\"\\(.\\|\n\\)*?[^\\]\"\\)"  . 'o2-css-font-lock-string-face) ; Allows backslash escape
   '("\\(''\\|'\\(.\\|\n\\)*?[^\\]'\\)"      . 'o2-css-font-lock-string-face) ; Allows backslash escape
   '("[.][a-zA-Z][a-zA-Z0-9]*\\>"            . 'o2-css-font-lock-class-face)
   '("\\(#[a-zA-Z]+\\>\\)[^;]"               1 'o2-css-font-lock-id-face) ; Avoid highlighting colors (like #90ff00)
   '("\\(//[^\n]*\\)"                        1 'o2-css-font-lock-comment-face t)
   '("/[*]\\(\n\\|.\\)*?[*]/"                0 'o2-css-font-lock-comment-face t)
   '(">\\|+"                                 . 'o2-css-font-lock-selector-face)
   '("\\[\\w+\\(\\(~\\||\\)?=\\)?"           . 'o2-css-font-lock-selector-face)
   '("\\]"                                   . 'o2-css-font-lock-selector-face)
   )
)

(defvar o2-css-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [C-return] 'o2-css-auto-complete-dispatch)
    (define-key map "\C-c\C-f" 'o2-css-auto-complete-dispatch)   ; Non-windows systems may have problems with ctrl-return
    (define-key map "}"        'o2-css-insert-closing-curly-bracket)
    map)
  "Keymap for o2-css-mode."
)

(defun o2-css-mode ()
  "Major mode for css files.

Things to remember
==================
1. Use tab to indent
2. Use Ctrl-return for auto-completion

Features
========
 - Indentation
 - Auto-completion/suggestion of css properties and values (Ctrl-return)
 - Customizable syntax highlighting
 - Insertion and indentation of closing curly bracket      (Ctrl-return after opening curly bracket)
 - Colons in a group can be aligned easily                 (Ctrl-return after a colon)

Indentation
===========
Lines are indented with respect to curly brackets and comments (/* and */) on the previous line. The tab key is used to indent.
When a closing curly bracket is inserted, the current line is automatically indented. indent-region can be used to indent
more than one line at the same time.

Auto-completion/suggestion of css properties and values
=======================================================
Hit Ctrl-return when the cursor is positioned after one or more spaces in the beginning of a line to see all css properties (only
standard properties in css version 2.1). Start typing and hit Ctrl-return again too see all properties starting with the string you
entered. Use arrow keys or the mouse to select an element. If only one property starts with the entered string, that property is
inserted without displaying a popup.

Hit Ctrl-return when the cursor is positioned after a css property, a colon and a space to see the valid values for that property.
The value may be auto-completed in the same way as the property.

Customizable syntax highlighting
================================
The following items are highlighted:
 - Comments
 - Classes
 - Ids
 - Selectors
 - Pseudo-classes and -elements
 - \"Important\" declaration
 - @media, @import and valid media-types
 - Strings

The colors and other font features of these items can be customized. Enter
  M-x customize-group RET o2-css-mode-fonts RET
in emacs to start customizing.

Insertion and indentation of closing curly bracket
==================================================
With the cursor positioned after an opening curly bracket, hitting Ctrl-return inserts a blank line and a line with a closing curly
bracket. Both lines are indented and the cursor is placed on the blank line.

Colons in a group can be aligned easily
=======================================
Hitting Ctrl-return with the cursor positioned after a colon aligns the colons in a group with the rightmost colon in the group.

Known bugs
==========
- Comments spanning a big number of lines usually don't get the 'comment color'
(Report bugs to haakonsk@redpill-linpro.com)
" ;" Emacs trouble...
  (interactive)
  (kill-all-local-variables)
  (set (make-local-variable 'font-lock-defaults) (list o2-css-font-lock-keywords-1))
  (set (make-local-variable 'font-lock-multiline) t) ; I think this helps make multiline comments keep their correct color better (but still not perfect)
  (set (make-local-variable 'indent-line-function) 'o2-css-indent-line)
  (use-local-map o2-css-mode-map)
  (set-syntax-table o2-css-mode-syntax-table)
  (make-local-variable 'font-lock-defaults)

  (setq major-mode 'o2-css-mode)
  (setq mode-name "o2-css")
)

(defun o2-css-insert-closing-curly-bracket ()
  (interactive)
  (insert "}")
  (if (o2-backward-looking-at "^ *}")
      (o2-css-indent-line)
  )
  (blink-matching-open)
)

(defun o2-css-indent-line ()
  (o2-javascript-or-css-indent-line)
)

(defun o2-css-auto-complete-dispatch ()
  (interactive)
  (if (o2-backward-looking-at "\t")
      (o2-fix-tabs)
  )
  (let ((string))
    (setq string (o2-backward-looking-at "^ +\\([a-zA-Z-]+\\) *:.*? +\\([a-zA-Z-]*\\)"))
    (if string
        (o2ml-show-css-property-values-menu (match-string 1 string) (match-string 2 string))
      (setq string (o2-backward-looking-at "^ +\\([a-zA-Z-]*\\)"))
      (if string
          (o2ml-show-css-properties-menu (match-string 1 string))
        (setq string (o2-backward-looking-at "{"))
        (if string
            (o2-insert-end-bracket)
          (setq string (o2-backward-looking-at ":"))
          (if string
              (o2-css-align-colons)
            (setq string (o2-backward-looking-at " [0-9]+"))
            (if string
                (insert (o2ml-show-menu-and-return-chosen-item "Choose css length unit" o2ml-css-units t))
            )
          )
        )
      )
    )
  )
)
