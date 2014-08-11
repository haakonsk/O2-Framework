(setq o2ml-css-attributes-and-values
      [
       ; Background:
       ["background"            "scroll" "fixed" "" "none" "" "top left" "top center" "top right" "center left" "center center" "center right" "bottom left" "bottom center" "bottom right" "" "repeat" "repeat-x" "repeat-y" "no-repeat" "" "transparent" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow"]
       ["background-attachment" "scroll" "fixed"]
       ["background-color"      "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow" "" "(color-rgb):no-value" "(color-hex):no-value"]
       ["background-image"      "none" "(url):no-value"]
       ["background-position"   "top left" "top center" "top right" "center left" "center center" "center right" "bottom left" "bottom center" "bottom right" "(x% y%):no-value" "(xpos ypos):no-value"]
       ["background-repeat"     "repeat" "repeat-x" "repeat-y" "no-repeat"]
       ; Border:
       ["border"                "thin" "medium" "thick" "" "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset" "" "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow"]
       ["border-bottom"         "thin" "medium" "thick" "" "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["border-bottom-color"   "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow" "" "(color-rgb):no-value" "(color-hex):no-value"]
       ["border-bottom-style"   "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["border-bottom-width"   "thin" "medium" "thick"]
       ["border-color"          "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow" "" "(color-rgb):no-value" "(color-hex):no-value"]
       ["border-left"           "thin" "medium" "thick" "" "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["border-left-color"     "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow" "" "(color-rgb):no-value" "(color-hex):no-value"]
       ["border-left-style"     "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["border-left-width"     "thin" "medium" "thick"]
       ["border-right"          "thin" "medium" "thick" "" "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["border-right-color"    "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow" "" "(color-rgb):no-value" "(color-hex):no-value"]
       ["border-right-style"    "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["border-right-width"    "thin" "medium" "thick"]
       ["border-style"          "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["border-top"            "thin" "medium" "thick" "" "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["border-top-color"      "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow" "" "(color-rgb):no-value" "(color-hex):no-value"]
       ["border-top-style"      "none" "hidden" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["border-top-width"      "thin" "medium" "thick"]
       ["border-width"          "thin" "medium" "thick"]
       ; Classification
       ["clear"                  "left" "right" "both" "none"]
       ["cursor"                 "inherit" "" "auto" "crosshair" "default" "pointer" "move" "e-resize" "ne-resize" "nw-resize" "n-resize" "se-resize" "sw-resize" "s-resize" "w-resize" "text" "wait" "help" "" "(url):no-value"]
       ["display"                "none" "inline" "block" "list-item" "run-in" "compact" "marker" "table" "inline-table" "table-row-group" "table-header-group" "table-footer-group" "table-row" "table-column-group" "table-column" "table-cell" "table-caption"]
       ["float"                  "left" "right" "none"]
       ["position"               "static" "relative" "absolute" "fixed"]
       ["visibility"             "visible" "hidden" "collapse"]
       ; Dimension
       ["height"                 "auto" "" "(length):no-value" "(%):no-value"]
       ["line-height"            "inherit" "" "normal" "" "(number):no-value" "(length):no-value" "(%):no-value"]
       ["max-height"             "none" "" "(length):no-value" "(%):no-value"]
       ["max-width"              "none" "" "(length):no-value" "(%):no-value"]
       ["min-height"             "(length):no-value" "(%):no-value"]
       ["min-width"              "(length):no-value" "(%):no-value"]
       ["width"                  "auto" "" "(length):no-value" "(%):no-value"]
       ; Font
       ["font"                   "inherit" "" "caption" "icon" "menu" "message-box" "small-caption" "status-bar" "" "xx-small" "x-small" "small" "medium" "large" "x-large" "xx-large" "smaller" "larger" "" "normal" "wider" "narrower" "ultra-condensed" "extra-condensed" "condensed" "semi-condensed" "semi-expanded" "expanded" "extra-expanded" "ultra-expanded" "" "normal" "italic" "oblique" "" "normal" "small-caps" "" "normal" "bold" "bolder" "lighter" "100" "200" "300" "400" "500" "600" "700" "800" "900" "" "serif" "sans-serif" "cursive" "fantasy" "monospace" "" "Arial" "Arial Black:quote-value" "Trebuchet MS:quote-value" "Verdana" "Courier New:quote-value" "Andale Mono:quote-value" "Comic Sans MS:quote-value" "Impact" "Webdings" "" "Times New Roman:quote-value" "Georgia" "Book Antiqua:quote-value" "Bookman Old Style:quote-value" "Garamond" "Arial Narrow:quote-value" "Century Gothic:quote-value" "Lucida Sans Unicode:quote-value" "Tahoma" "Courier" "Lucida Console:quote-value" "" "Bitstream Vera Serif:quote-value" "New Century Schoolbook:quote-value" "Times" "Utopia" "Bitstream Vera Sans:quote-value" "Helvetica" "Lucida" "Bitstream Vera Mono:quote-value" "Courier" "" "New York:quote-value" "Palatino" "Times" "Charcoal" "Chicago" "Geneva" "Helvetica" "Lucida Grande:quote-value" "Courier" "Monaco"]
       ["font-family"            "inherit" "" "serif" "sans-serif" "cursive" "fantasy" "monospace" "" "Arial" "Arial Black:quote-value" "Trebuchet MS:quote-value" "Verdana" "Courier New:quote-value" "Andale Mono:quote-value" "Comic Sans MS:quote-value" "Impact" "Webdings" "" "[Windows]:no-value" "Times New Roman:quote-value" "Georgia" "Book Antiqua:quote-value" "Bookman Old Style:quote-value" "Garamond" "Arial Narrow:quote-value" "Century Gothic:quote-value" "Lucida Sans Unicode:quote-value" "Tahoma" "Courier" "Lucida Console:quote-value" "" "[Linux/Unix]:no-value" "Bitstream Vera Serif:quote-value" "New Century Schoolbook:quote-value" "Times" "Utopia" "Bitstream Vera Sans:quote-value" "Helvetica" "Lucida" "Bitstream Vera Mono:quote-value" "Courier" "" "[Mac]:no-value" "New York:quote-value" "Palatino" "Times" "Charcoal" "Chicago" "Geneva" "Helvetica" "Lucida Grande:quote-value" "Courier" "Monaco" "" "(..and more):no-value"]
       ["font-size"              "inherit" "" "xx-small" "x-small" "small" "medium" "large" "x-large" "xx-large" "smaller" "larger" "" "(length):no-value" "(%):no-value"]
       ["font-size-adjust"       "inherit" "" "none" "" "(number):no-value"]
       ["font-stretch"           "inherit" "" "normal" "wider" "narrower" "ultra-condensed" "extra-condensed" "condensed" "semi-condensed" "semi-expanded" "expanded" "extra-expanded" "ultra-expanded"]
       ["font-style"             "inherit" "" "normal" "italic" "oblique"]
       ["font-variant"           "inherit" "" "normal" "small-caps"]
       ["font-weight"            "inherit" "" "normal" "bold" "bolder" "lighter" "100" "200" "300" "400" "500" "600" "700" "800" "900"]
       ; Generated content
       ["content"                "open-quote" "close-quote" "no-open-quote" "no-close-quote" "" "(string):no-value" "(url):no-value" "(counter(name)):no-value" "(counter(name, list-style-type)):no-value" "(counters(name, string, list-style-type)):no-value" "(attr(X)):no-value"]
       ["counter-increment"      "none" "" "(identifier number):no-value"]
       ["counter-reset"          "none" "" "(identifier number):no-value"]
       ["quotes"                 "inherit" "" "none" "" "(string string):no-value"]
       ; List and marker
       ["list-style"             "inherit" "" "none" "" "inside" "outside" "" "none" "disc" "circle" "square" "decimal" "decimal-leading-zero" "lower-roman" "upper-roman" "lower-alpha" "upper-alpha" "lower-greek" "lower-latin" "upper-latin" "hebrew" "armenian" "georgian" "cjk-ideographic" "hiragana" "katakana" "hiragana-iroha" "katakana-iroha"]
       ["list-style-image"       "inherit" "" "none" "" "(url):no-value"]
       ["list-style-position"    "inherit" "" "inside" "outside"]
       ["list-style-type"        "inherit" "" "none" "disc" "circle" "square" "decimal" "decimal-leading-zero" "lower-roman" "upper-roman" "lower-alpha" "upper-alpha" "lower-greek" "lower-latin" "upper-latin" "hebrew" "armenian" "georgian" "cjk-ideographic" "hiragana" "katakana" "hiragana-iroha" "katakana-iroha"]
       ["marker-offset"          "auto" "" "(length):no-value"]
       ; Margin
       ["margin"                 "auto" "" "(length):no-value" "(%):no-value"]
       ["margin-bottom"          "auto" "" "(length):no-value" "(%):no-value"]
       ["margin-left"            "auto" "" "(length):no-value" "(%):no-value"]
       ["margin-right"           "auto" "" "(length):no-value" "(%):no-value"]
       ["margin-top"             "auto" "" "(length):no-value" "(%):no-value"]
       ; Outlines
       ["outline"                "invert" "" "none" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset" "" "thin" "medium" "thick" "" "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow"]
       ["outline-color"          "invert" "" "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow" "" "(color-rgb):no-value" "(color-hex):no-value"]
       ["outline-style"          "none" "dotted" "dashed" "solid" "double" "groove" "ridge" "inset" "outset"]
       ["outline-width"          "thin" "medium" "thick" "" "(length):no-value"]
       ; Padding
       ["padding"                "(length):no-value" "(%):no-value"]
       ["padding-bottom"         "(length):no-value" "(%):no-value"]
       ["padding-right"          "(length):no-value" "(%):no-value"]
       ["padding-left"           "(length):no-value" "(%):no-value"]
       ["padding-top"            "(length):no-value" "(%):no-value"]
       ; Positioning
       ["bottom"                 "auto" "" "(%):no-value" "(length):no-value"]
       ["clip"                   "auto" "" "(shape):no-value"]
       ["left"                   "auto" "" "(%):no-value" "(length):no-value"]
       ["overflow"               "visible" "hidden" "scroll" "auto"]
;      ["position"               "static" "relative" "absolute" "fixed"]
       ["right"                  "auto" "" "(%):no-value" "(length):no-value"]
       ["top"                    "auto" "" "(%):no-value" "(length):no-value"]
       ["vertical-align"         "baseline" "sub" "super" "top" "text-top" "middle" "bottom" "text-bottom" "" "(%):no-value" "(length):no-value"]
       ["z-index"                "auto" "(number):no-value"]
       ; Table
       ["border-collapse"        "inherit" "" "collapse" "separate"]
       ["border-spacing"         "inherit" "" "(length length):no-value"]
       ["caption-side"           "inherit" "" "top" "bottom" "left" "right"]
       ["empty-cells"            "inherit" "" "show" "hide"]
       ["table-layout"           "auto" "fixed"]
       ; Text
       ["color"                  "inherit" "" "transparent" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow" "" "(color-rgb):no-value" "(color-hex):no-value"]
       ["direction"              "inherit" "" "ltr" "rtl"]
       ["letter-spacing"         "inherit" "" "normal" "(length):no-value"]
       ["text-align"             "inherit" "" "left" "right" "center" "justify"]
       ["text-decoration"        "none" "underline" "overline" "line-through" "blink"]
       ["text-indent"            "inherit" "" "(length):no-value" "(%):no-value"]
       ["text-shadow"            "none" "" "aqua" "black" "blue" "fuchsia" "gray" "green" "lime" "maroon" "navy" "olive" "purple" "red" "silver" "teal" "white" "yellow" "" "(color-rgb):no-value" "(color-hex):no-value" "" "(length):no-value"]
       ["text-transform"         "inherit" "" "none" "capitalize" "uppercase" "lowercase"]
       ["unicode-bidi"           "normal" "embed" "bidi-override"]
       ["white-space"            "inherit" "" "normal" "pre" "nowrap"]
       ["word-spacing"           "inherit" "" "normal" "" "(length):no-value"]
      ]
)

(setq o2ml-css-units (reverse (list "px" "em" "ex" "%" "in" "cm" "mm" "pt" "pc")))

(setq o2ml-css-pseudo-classes-and-elements
      ["active" "focus" "hover" "link" "visited" "first-child" "lang" "first-letter" "first-line" "before" "after"]
)

(defun o2-css-align-colons ()
  (let ((colon-positions ())
        (curr-line (o2-read-line   ))
        (curr-line-colon-position 0)
        (aligned-colon-position   0)
        (num-lines-before  0)
        (num-lines-after  -1)
        (i 0)
        (j 0))

    ; Search forward
    (setq curr-line (o2-read-line i))
    (while (string-match "\\([^:]+\\):[^{]*$" curr-line)
      (setq curr-line-colon-position (length (match-string 1 curr-line)))
      (if (> curr-line-colon-position aligned-colon-position)
          (setq aligned-colon-position curr-line-colon-position)
      )
      (setq i (1+ i))
      (setq curr-line (o2-read-line i))
      (setq num-lines-after (1+ num-lines-after))
    )
    ; Search backward
    (setq i -1)
    (setq curr-line (o2-read-line j))
    (while (string-match "\\([^:]+\\):[^{]*$" curr-line)
      (setq curr-line-colon-position (length (match-string 1 curr-line)))
      (if (> curr-line-colon-position aligned-colon-position)
          (setq aligned-colon-position curr-line-colon-position)
      )
      (setq j (1- j))
      (setq curr-line (o2-read-line j))
      (setq num-lines-before (1+ num-lines-before))
    )

    ; Forward
    (setq i 0)
    (while (< i num-lines-after)
      (setq i (1+ i))
      (setq curr-line (o2-read-line i))
      (string-match "\\([^:]+\\):[^{]*$" curr-line)
      (setq curr-line-colon-position (length (match-string 1 curr-line)))
      (save-excursion
        (forward-line i)
        (o2-css-align-colons-insert-spaces curr-line-colon-position aligned-colon-position)
      )      
    )

    ; Backward
    (setq i 0)
    (while (< i num-lines-before)
      (setq j (- 0 i))
      (setq i (1+ i))
      (setq curr-line (o2-read-line j))
      (string-match "\\([^:]+\\):[^{]*$" curr-line)
      (setq curr-line-colon-position (length (match-string 1 curr-line)))
      (save-excursion
        (forward-line j)
        (o2-css-align-colons-insert-spaces curr-line-colon-position aligned-colon-position)
      )      
    )
  )
)

(defun o2-css-align-colons-insert-spaces (curr-colon-position aligned-colon-position)
  (let ((i (- aligned-colon-position curr-colon-position)))
    (goto-char (+ (point) curr-colon-position))
    (while (> i 0)
      (insert " ")
      (setq i (1- i))
    )
  )
)

(provide 'o2-css-stuff)
