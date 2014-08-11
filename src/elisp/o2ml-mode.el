(load "o2-util.el")
(require 'o2-util)

(load "o2-css-stuff")
(require 'o2-css-stuff) ; Sets the variables: o2ml-css-attributes-and-values, o2ml-css-units and o2ml-css-pseudo-classes-and-elements

; Make our own faces
(defgroup o2ml-mode-fonts nil
  "Font-lock support for o2ml."
  :group 'programming)

(defface o2ml-font-lock-error-face
  `((((class color) (background light)) (:foreground, "#ff0000"))
    (((class color) (background dark))  (:foreground, "#ff0000")))
  "Font used on css class names"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-comment-face
  `((((class color) (background light)) (:foreground, "Firebrick"))
    (((class color) (background dark))  (:foreground, "Firebrick")))
  "Font used on html/o2ml comments"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-js-or-css-comment-face
  `((((class color) (background light)) (:foreground, "Goldenrod"))
    (((class color) (background dark))  (:foreground, "Goldenrod")))
  "Font used on javascript or css comments"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-tag-face
  `((((class color) (background light)) (:foreground, "#0000bb"))
    (((class color) (background dark))  (:foreground, "#acacfc")))
  "Font used on tags"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-attribute-key-face
  `((((class color) (background light)) (:foreground, "#00ad00"))
    (((class color) (background dark))  (:foreground, "#00ad00")))
  "Font used on attribute keys"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-attribute-value-face
  `((((class color) (background light)) (:foreground, "#00bb00"))
    (((class color) (background dark))  (:foreground, "#70f170")))
  "Font used on attribute values"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-string-face
  `((((class color) (background light)) (:foreground, "#dd6644"))
    (((class color) (background dark))  (:foreground, "#dd6644")))
  "Font used on strings"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-variable-face
  `((((class color) (background light)) (:foreground, "#333333" :bold   t))
    (((class color) (background dark))  (:foreground, "#dddd55" :italic t)))
  "Font used on template variables"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-variable-suppressed-error-face
  `((((class color) (background light)) (:foreground, "#660000" :bold t))
    (((class color) (background dark))  (:foreground, "#dd9955" :bold t)))
  "Font used on template variables where errors are ignored"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-attribute-equals-sign-face
  `((((class color) (background light)) (:foreground, "#33bb33"))
    (((class color) (background dark))  (:foreground, "#33bb33")))
  "Font used on the equals sign in attributes"
  :group 'o2ml-mode-fonts
)
; Javascript faces
(defface o2ml-font-lock-js-special-word-face
  `((((class color) (background light)) (:foreground, "#bb33bb"))
    (((class color) (background dark))  (:foreground, "#99ccff")))
  "Font used on javascript special words"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-js-function-name-face
  `((((class color) (background light)) (:foreground, "#0000ff"))
    (((class color) (background dark))  (:foreground, "#7777ff")))
  "Font used on javascript function names (in the function definition)"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-js-class-name-face
  `((((class color) (background light)) (:foreground, "#0000ff"))
    (((class color) (background dark))  (:foreground, "#cc77cc")))
  "Font used on javascript class names (when they are instantiated)"
  :group 'o2ml-mode-fonts
)
; CSS faces
(defface o2ml-font-lock-css-id-face
  `((((class color) (background light)) (:foreground, "#bb33bb"))
    (((class color) (background dark))  (:foreground, "#99ccff")))
  "Font used on css ids"
  :group 'o2ml-mode-fonts
)
(defface o2ml-font-lock-css-class-face
  `((((class color) (background light)) (:foreground, "#5500ff"))
    (((class color) (background dark))  (:foreground, "#dddd55")))
  "Font used on css class names"
  :group 'o2ml-mode-fonts
)

(defvar o2ml-mode-syntax-table nil
  "Syntax table for o2ml mode.")

(if o2ml-mode-syntax-table
    ()
  (setq o2ml-mode-syntax-table (make-syntax-table text-mode-syntax-table))
)

(defconst o2ml-font-lock-keywords-1
  (list
   '("\\(^\\|[^\\]\\)\\(\"\\(\\\\[^\n]\\|[^\"\n]\\)*?\"\\)" 2 'o2ml-font-lock-string-face)
   '("\\(^\\|[^\\]\\)\\('\\(\\\\[^\n]\\|[^'\n]\\)*?'\\)"    2 'o2ml-font-lock-string-face)

   ; Javascript:
   '("^ +\\(if\\|else if\\|for\\|catch\\|while\\|switch\\) ("                       1 'o2ml-font-lock-js-special-word-face)
   '(" +} \\(while\\) ("                                                            1 'o2ml-font-lock-js-special-word-face)
   '("^ +\\(else\\|try\\|do\\) {"                                                   1 'o2ml-font-lock-js-special-word-face)
   '("\\(^ +\\|= +\\)\\(function\\>\\)"                                             2 'o2ml-font-lock-js-special-word-face)
   '("^ +\\(var\\|throw\\)\\>"                                                      . 'o2ml-font-lock-js-special-word-face)
   '("\\(^ +\\|) +\\)\\(return\\>\\)"                                               2 'o2ml-font-lock-js-special-word-face)
   '("^ +\\(continue\\|break\\)\\>"                                                 . 'o2ml-font-lock-js-special-word-face)
   '("\\<\\(true\\|false\\|null\\)\\>"                                              . 'o2ml-font-lock-js-special-word-face)
   '("^ +function \\(_?\\<.+?\\>\\)("                                               1 'o2ml-font-lock-js-function-name-face)
   '(" ( *\\(var\\) "                                                               1 'o2ml-font-lock-js-special-word-face)
   '(" ( *var \\<.+?\\> +\\(in\\) +\\<.+?\\> *)"                                    1 'o2ml-font-lock-js-special-word-face)
   '("^ +\\(case\\) [^\n]*?[:]"                                                     1 'o2ml-font-lock-js-special-word-face)
   '("^ +\\(default\\) *[:]"                                                        1 'o2ml-font-lock-js-special-word-face)
   '("[ (]\\(instanceof\\|typeof\\|with\\|void\\)("                                 1 'o2ml-font-lock-js-special-word-face)
   '(" +\\(new\\) \\<.*?\\>("                                                       1 'o2ml-font-lock-js-special-word-face)
   '(" +new \\(\\<.*?\\>\\)("                                                       1 'o2ml-font-lock-js-class-name-face)
   '("\\<\\(this\\)[.,)]"                                                           1 'o2ml-font-lock-js-special-word-face)
   '("^ *\\([a-zA-Z][a-zA-Z0-9]*[.]prototype[.][a-zA-Z][a-zA-Z0-9]*\\) += +"        1 'o2ml-font-lock-js-function-name-face)
   '("^ *[a-zA-Z][a-zA-Z0-9]*[.]prototype[.][a-zA-Z][a-zA-Z0-9]* += \\(function\\)" 1 'o2ml-font-lock-js-special-word-face)

   ; CSS:
   '(" [.][a-zA-Z]+\\>"         . 'o2ml-font-lock-css-class-face)
   '(" \\(#[a-zA-Z]+\\>\\)[^;]" 1 'o2ml-font-lock-css-id-face) ; Avoid highlighting colors (like #90ff00)

   ; Tags, strings and variables
   '(" \\([a-zA-Z][a-zA-Z0-9_\\:-]*?\\)=[\"']"                                1 'o2ml-font-lock-attribute-key-face)
   '(" [a-zA-Z][a-zA-Z0-9_\\:-]*?\\(=\\)[\"']"                                1 'o2ml-font-lock-attribute-equals-sign-face)

;  '(" [a-zA-Z][a-zA-Z0-9_\\:-]*?=\\(\"\\(\\\\[^\n]\\|[^\"\n\\\\]+\\)*\"\\)"  1 'o2ml-font-lock-attribute-value-face t) ; This causes emacs to hang if the value is long, but apart from that it works correctly..
   '(" [a-zA-Z][a-zA-Z0-9_\\:-]*?=\\(\".*?\"\\)"                              1 'o2ml-font-lock-attribute-value-face t) ; This only works in normal circumstances, but emacs doesn't hang

;  '(" [a-zA-Z][a-zA-Z0-9_\\:-]*?=\\('\\(\\\\[^\n]\\|[^'\n\\\\]+\\)*'\\)"     1 'o2ml-font-lock-attribute-value-face t) ; This causes emacs to hang if the value is long, but apart from that it works correctly..
   '(" [a-zA-Z][a-zA-Z0-9_\\:-]*?=\\('.*?'\\)"                                1 'o2ml-font-lock-attribute-value-face t) ; This only works in normal circumstances, but emacs doesn't hang

   '("<o2 use \\([a-zA-Z][a-zA-Z0-9_:-]+\\).*?/>"                             1 'o2ml-font-lock-attribute-value-face t)
;  '("[<]o2 +[a-zA-Z][a-zA-Z0-9_-]* +\\(\"\\(\\[^\n]\\|[^\"\n\\\\]+\\)*\"\\)" 1 'o2ml-font-lock-attribute-value-face t) ; This causes emacs to hang if the value is long, but apart from that it works correctly..
   '("[<]o2 +[a-zA-Z][a-zA-Z0-9_-]* +\\(\".*?\"\\)"                           1 'o2ml-font-lock-attribute-value-face t) ; This only works in normal circumstances, but emacs doesn't hang
;  '("[<]o2 +[a-zA-Z][a-zA-Z0-9_-]* +\\('\\(\\[^\n]\\|[^'\n\\\\]+\\)*'\\)"    1 'o2ml-font-lock-attribute-value-face t) ; This causes emacs to hang if the value is long, but apart from that it works correctly..
   '("[<]o2 +[a-zA-Z][a-zA-Z0-9_-]* +\\('.*?'\\)"                             1 'o2ml-font-lock-attribute-value-face t) ; This only works in normal circumstances, but emacs doesn't hang
   '("[<]o2 .+?\\>"                                                           . 'o2ml-font-lock-tag-face)
   '("[<]/o2:.+?\\>"                                                          . 'o2ml-font-lock-tag-face)
   '("[<][a-zA-Z/].*?\\>"                                                     . 'o2ml-font-lock-tag-face)
   '("/[>]"                                                                   . 'o2ml-font-lock-tag-face)
   '("[a-zA-Z0-9\"']\\([>]\\)"                                                1 'o2ml-font-lock-tag-face)
   '("[$][_a-zA-Z][_a-zA-Z0-9]*"                                              0 'o2ml-font-lock-variable-face t)
   '("[\\^]\\([$][_a-zA-Z][_a-zA-Z0-9]*\\)"                                   1 'o2ml-font-lock-variable-suppressed-error-face t)
   '(" +\\(//[^\n]*\\)"                                                       1 'o2ml-font-lock-js-or-css-comment-face t)
   '("/[*]\\(\n\\|.\\)*?[*]/"                                                 0 'o2ml-font-lock-js-or-css-comment-face t)
   '("[<]o2 comment[>]\\(\n\\|.\\)*?[<]/o2:comment[>]"                        0 'o2ml-font-lock-comment-face t)
   '("[<]!--\\(.\\|\n\\)*?--[>]"                                              0 'o2ml-font-lock-comment-face t)

   '("[<]/?\\(applet\\|basefont\\|center\\|dir\\|font\\|isindex\\|menu\\|s\\|strike\\|u\\|xmp\\)[ >]" 1 'o2ml-font-lock-error-face t) ; Deprecated tags
   '("\\<\\(align\\|alink\\|background\\|bgcolor\\|clear\\|color\\|compact\\|hspace\\)="              1 'o2ml-font-lock-error-face t) ; Deprecated attributes
   '("\\<\\(language\\|link\\|noshade\\|nowrap\\|start\\|text\\|vlink\\|vspace\\)="                   1 'o2ml-font-lock-error-face t) ; More deprecated attributes
   )
)

(defvar o2ml-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [C-return] 'o2ml-complete-tag-dispatch)
    (define-key map "\C-c\C-f" 'o2ml-complete-tag-dispatch)    ; Non-windows systems may have problems with ctrl-return
;    (define-key map " "        'o2ml-complete-tag-with-space) ; Uncomment this line if you want to complete tags with space
    (define-key map "/"        'o2ml-indent-line-if-end-tag)
    (define-key map "}"        'o2ml-indent-line-if-js-or-css)
    (define-key map "\C-c\C-i" 'o2ml-insert-entity)
    map)
  "Keymap for o2ml-mode."
)

(setq o2ml-modules-and-tags
      [
       ["BackgroundProcess"               "backgroundProcess" "progressBar" "startButton"]
       ["Cache"                           "cache"]
       ["Core"                            "appendVar" "calc" "call" "comment" "doubleParse" "else" "elsif" "for" "foreach" "last" "function" "if" "include" "join" "macro" "noExec" "out" "postMacro" "preMacro" "push" "set" "setVar" "use" "warnLevel"]
       ["DataDumper"                      "dump"]
       ["DateFormat"                      "dateFormat" "timeFormat"]
       ["Html"                            "addCss" "addCssFile" "addJs" "addJsFile" "addMetaHeader" "backlink" "contentGroup" "div" "encodeEntities" "footer" "header" "incJavascript" "incMetaHeader" "incStylesheet" "label" "link" "makeFlipper" "pageBreaks" "pldsDump" "objectDump" "popupWindow" "postJavascript" "printOnly" "table" "urlMod" "webOnly" "img" "pagination" "paginationNavigation" "previousLink" "numericPageLinks" "nextLink" "openingTag" "closingTag"]
       ["Html::Ajax"                      "ajaxCall" "ajaxForm" "ajaxLink" "ajaxScheduleCalls" "button" "input"]
       ["Html::BoxMenu"                   "BoxMenu" "addMenuItem"]
       ["Html::Flexigrid"                 "flexigrid" "flexiTh" "flexiTd"]
       ["Html::Form"                      "button" "checkbox" "checkboxGroup" "comboBox" "dateSelect" "form" "formTable" "input" "inputCounter" "multilingualController" "multiInput" "option" "radio" "radioGroup" "select" "setCurrentMultilingualObject" "textarea" "tr"]
       ["Html::Form::Input::AutoComplete" "autoCompleteInput"]
       ["Html::List"                      "list" "listItem" "objectItem"]
       ["Html::Locale"                    "localeSwitch"]
       ["Html::MediaPlayer"               "MediaPlayer"]
       ["Html::MultiColumnLayout"         "multiColumnLayout" "column"]
       ["Html::PopupDialog"               "popupDialog"]
       ["Html::RandomColor"               "uniqueColor"]
       ["Html::Slides"                    "slides"]
       ["Html::ToolBarMenu"               "addCell" "addItem" "addSeparator" "ToolBarMenu"]
       ["I18N"                            "getString" "setLocale" "setResourcePath"]
       ["Js::Lang"                        "addJsLangFile"]
       ["NumberFormat"                    "byteFormat" "moneyFormat" "numberFormat" "percentFormat" "sprintf"]
       ["O2::ApplicationFrame"            "ApplicationFrameFooter" "ApplicationFrameHeader" "addCell" "addCellSeparator" "addHeaderButton"]
       ["O2::Objects"                     "iconUrl" "objectComponent" "objectHash"]
       ["O2::Page"                        "slot" "slotChildren" "slotImage" "slotString"]
       ["O2::Publisher"                   "ifBackend" "ifFrontend" "objectUrl"]
       ["O2CMS::Html::PopupMenu"          "addMenuItem" "addSeparator" "PopupMenu"]
       ["O2Doc::Tutorial"                 "docCode" "docCodeResult" "docExample" "docHint" "docLink" "docList" "docListItem" "docNote" "docSection"]
       ["StringFormat"                    "trim" "uc" "lc" "ucfirst" "titlecase" "substitute"]
      ]
)

(setq o2ml-o2-tags-and-attributes
      [
       ; BackgroundProcess
       ["backgroundProcess"     "exclusive" "command" "url" "outputDocument" "" "id"]
       ["progressBar"           "max" "width" "checkIntervalSeconds" "estimateProgressBetweenChecks" "checkTimeoutSeconds"]
       ["startButton"           "text" "onStart" "onEnd"]
       ; Cache
       ["cache"                 "timeout" "key:required"]
       ; Core
       ["appendVar"             "delimiter"]
       ["foreach"               "sortBy" "sortDirection" "sortType" "limit" "label"]
       ["last"                  "if" "unless"]
       ["include"               "file" "cacheKey" "cacheTtl"]
       ["if"                    "then" "else"]
       ; DateFormat
       ["dateFormat"            "locale" "format"]
       ["timeFormat"            "locale" "format"]
       ["dataSet"               "description" "bulletColor" "bulletSize" "dataset" "style" "lineDescription" "color" "type" "xOffset" "separator"]
       ; Html
       ["addCss"                "class" "param"]
       ["addCssFile"            "file:required"]
       ["addJs"                 "where" "priority"]
       ["addJsFile"             "where" "file:required"]
       ["addMetaHeader"         "name:required" "value"]
       ["backlink"              "text"]
       ["closingTag"]
       ["contentGroup"          "title" "bgColor" "width" "disabled"]
       ["div"                   "src" "" "align" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["encodeEntities"        "encodeDollars" ]
       ["header"                "title" "bgColor" "onLoad" "quirksMode" "omitBody:param" "omitBgColor:param" "disableScrollbars:param" "" "alink" "background" "bgColor" "link" "text" "vlink" "" "id" "class" "style" "dir" "lang" "xml:lang" "" "onload" "onunload" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["img"                   "id:required" "width" "height" "onTooBig" "onTooSmall" "keepAspectRatio"]
       ["label"                 "bgColor" "align"]
       ["link"                  "type" "src" "href" "onClick" "url" "border" "alt" "confirmMsg" "" "editObject" "newObjectClass" "startMenuItem" "" "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL"]
       ["makeFlipper"           "var:required" "values:required"]
       ["nextLink"              "class" "" "charset" "coords" "href" "hreflang" "name" "rel" "rev" "shape" "target" "type" ""
        "id" "title" "style" "dir" "lang" "xml:lang" "tabIndex" "accessKey" ""
        "onFocus" "onBlur" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["numericPageLinks"      "numBefore" "numAfter" "linkSeparator" "class" "" "charset" "coords" "href" "hreflang" "name" "rel" "rev" "shape" "target" "type" ""
        "id" "title" "style" "dir" "lang" "xml:lang" "tabIndex" "accessKey" ""
        "onFocus" "onBlur" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["openingTag"]
       ["pagination"            "numPerPage" "totalNumResults" "elements"]
       ["paginationNavigation"  "linkSeparator"]
       ["popupWindow"           "type" "src" "href" "onClick" "border" "alt" "" "windowTitle" "toolbar" "location" "directories" "status" "menubar" "scrollbars" "resizeable" "width" "height" "ignoreSingleClickOnDblClick" "" "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL"]
       ["previousLink"          "class" "" "charset" "coords" "href" "hreflang" "name" "rel" "rev" "shape" "target" "type" ""
        "id" "title" "style" "dir" "lang" "xml:lang" "tabIndex" "accessKey" ""
        "onFocus" "onBlur" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["table"                 "sortable" "rearrangeableRows" "" "align" "bgColor" "border" "cellPadding" "cellSpacing" "frame" "rules" "summary" "width" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["urlMod"                "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL"]
       ; Html::Ajax
       ["ajaxCall"              "formParams" "target" "where" "onSuccess" "onError" "handler" "confirmMsg" "debug" "serverScript" "method" "" "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL"]
       ["ajaxForm"              "formParams" "target" "where" "onSuccess" "onError" "handler" "confirmMsg" "debug" "serverScript" "method" "" "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL"]
       ["ajaxLink"              "formParams" "target" "where" "onSuccess" "onError" "handler" "confirmMsg" "debug" "serverScript" "method" "" "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL" "" "type" "src" "href" "onClick" "url" "border" "alt"]
       ["ajaxScheduleCalls"     "interval:required" "formParams" "target" "where" "onSuccess" "onError" "handler" "confirmMsg" "debug" "serverScript" "method" "" "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL"]
       ["button"                "image" "imageWidth" "imageHeight" "onClick" "href" "title" "class" "" "ajaxEvent" "formParams" "target" "where" "onSuccess" "onError" "handler" "confirmMsg" "debug" "serverScript" "method" "" "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL"]
       ["input"                 "rule" "ruleMsg" "counterId" "name" "label" "labelClass" "accesskey" "addColon" "focus" "containerStyle" "" "accept" "align" "alt" "checked" "disabled" "maxLength" "readOnly" "size" "src" "type" "value" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "tabIndex" "accessKey" "onFocus" "onBlur" "onSelect" "onChange" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp" "" "ajaxEvent" "formParams" "target" "where" "onSuccess" "onError" "handler" "confirmMsg" "debug" "serverScript" "method" "" "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL"]
       ; Html::BoxMenu
       ["BoxMenu"               "BoxMenuId" "cssFile" "icon" "expandIcon" "animate" "height" "width"]
;       ["addMenuItem"           "title:required" "icon" "expandIcon" "selected" "url" "elementId" "body"]
       ; Html::Form
       ["checkbox"              "value:required" "label:required" "labelClass" "accesskey" "checked" "lineBreakAfter" "id" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["checkboxGroup"         "name:required" "values" "label" "labelClass" "addColon" "focus" "display" "rule" "ruleMsg"]
       ["comboBox"              "name:required" "width" "addColon" "accesskey" "containerStyle" "id" "focus"]
       ["dateSelect"            "name:required" "label" "labelClass" "epoch" "value" "accesskey" "addColon" "format" "onUpdate" "canType" "size" "language" "type" "iconUrl" "style" "theme" "id" "hideDate" "inputStyle" "buttonStyle" "buttonClass"]
       ["form"                  "ruleTitle" "class" "onChange" "disabled" "" "setDispatcherPath" "setClass" "setMethod" "setParams" "setParam" "removeParams" "removeParam" "appendParam" "toggleParam" "absoluteURL" "" "action" "accept" "accept-charset" "enctype" "method" "name" "target" "" "id" "title" "style" "dir" "lang" "xml:lang" "" "onsubmit" "onreset" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["formTable"             "align" "bgColor" "border" "cellPadding" "cellSpacing" "frame" "rules" "summary" "width" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["input"                 "rule" "ruleMsg" "label" "labelClass" "multilingual" "addColon" "focus" "containerStyle" "counterId" "" "accept" "align" "alt" "checked" "disabled" "maxLength" "name" "readOnly" "size" "src" "type" "value" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "tabIndex" "accessKey" "onFocus" "onBlur" "onSelect" "onChange" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["inputCounter"          "id:required" "type" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["multiInput"            "value" "rearrangeable" "resizable" "minNumLines" "columnTitles" "rule" "ruleMsg" "counterId" "name" "label" "labelClass" "accesskey" "addColon" "focus" "containerStyle" "" "accept" "align" "alt" "checked" "disabled" "maxLength" "name" "readOnly" "size" "src" "type" "value" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "tabIndex" "accessKey" "onFocus" "onBlur" "onSelect" "onChange" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["multilingualController" "object" "type" "onSwitchPre" "onSwitchPost" "reloadPage" "reloadConfirmMsg"]
       ["option"                "value" "" "disabled" "label" "selected" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["radio"                 "value:required" "label:required" "labelClass" "accesskey" "checked" "lineBreakAfter" "rule" "ruleMsg" "" "accept" "align" "alt" "checked" "disabled" "maxLength" "name" "readOnly" "size" "src" "type" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "tabIndex" "accessKey" "onFocus" "onBlur" "onSelect" "onChange" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["radioGroup"            "name:required" "value" "label" "labelClass" "addColon" "focus" "display"]
       ["select"                "name:required" "value" "values" "label" "labelClass" "accesskey" "addColon" "focus" "class" "rule" "ruleMsg" "" "disabled" "multiple" "name" "size" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "accessKey" "tabIndex" "onFocus" "onBlur" "onChange"]
       ["setCurrentMultilingualObject" "object" "scope"]
       ["textarea"              "counterId" "rule" "ruleMsg" "label" "labelClass" "accesskey" "addColon" "focus" "multilingual" "autoResize" "" "cols" "rows" "disabled" "name" "readOnly" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "tabIndex" "accessKey" "" "onFocus" "onBlur" "onSelect" "onChange" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["tr"                    "align" "bgColor" "char" "charOff" "vAlign" "" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ; Html::Form::Input::AutoComplete
       ["autoCompleteInput"     "name" "guiModule" "method" "onChange" "" "autoFill" "cacheLength" "delay" "extraParams" "formatItem" "formatMatch" "formatResult" "highlight" "matchCase" "matchContains" "matchSubset" "max" "minChars" "multiple" "multipleSeparator" "mustMatch" "scroll" "scrollHeight" "selectFirst" "width"]
       ; Html::List
       ["list"                  "type" "id" "extraItemFields" "class" "headers" "items" "selectedValues" "submitType"]
       ["listItem"              "name" "value"]
       ; Html::Locale
       ["localeSwitch"          "object" "type" "class" "orientation" "onClick" "onSuccess" "" "align" "" "id" "title" "style" "dir" "lang" "xml:lang" "" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ; Html::MultiColumnLayout
       ["multiColumnLayout"     "width"]
       ["column"                "width"]
       ; Html::PopupDialog
       ["popupDialog"           "id" "contentId" "submitText" "src" "linkText" "onClose" "" "disabled" "autoOpen" "buttons" "closeOnEscape" "closeText" "dialogClass" "draggable" "height" "hide" "maxHeight" "maxWidth" "minHeight" "minWidth" "modal" "position" "resizable" "show" "stack" "title" "width" "zIndex"]
       ; Html::RandomColor
       ["uniqueColor"           "illuminance" "webSafeColors" "colorType"]
       ; Html::Slides
       ["Slides"                "header" "footer" "align"]
       ["addTab"                "name:required" "contentId:required" "selected" "notCloseAble" "preAction"]
       ; Html::ToolBarMenu
       ["toolBarMenu"           "cssFile"]
;       ["addItem"               "width" "icon" "id" "action" "name"]
;       ["addCell"               "width"]
;       ["addSeparator"          "width"]
       ; Js::Lang
       ["addJsLangFile"         "file"]
       ; NumberFormat
       ["byteFormat"            "locale"]
       ["moneyFormat"           "locale"]
       ["numberFormat"          "aggregateTo"]
       ["percentFormat"         "locale"]
       ["sprintf"               "format"]
       ; O2::ApplicationFrame
       ["ApplicationFrameFooter" "statusBar"]
       ["ApplicationFrameHeader" "useCloseAction" "url" "disableScrollBar" "showSettingsButton" "showCloseButton" "objectId" "extraPath" "path"]
       ["addHeaderButton"        "width" "action" "id" "icon"]
;       ["addCell"                "width" "action" "id" "icon"]
       ["addCellSeparator"       "width"]
       ; O2::GenericEditObject
       ; O2::Objects
       ["objectComponent"       "object:required"]
       ["iconUrl"               "size"]
       ["objectHash"            "extraItemFields"]
       ; O2::Page
       ["slot"                  "id:required" "inheritIfEmpty" "accepts" "templateMatch" "directPublishPriority"]
       ["slotChildren"          "maxItems" "alwaysMaxItems" "virtual"]
       ["slotImage"             "field:required" "width" "height"]
       ["slotString"            "field:required" "editable" "virtual"]
       ; O2::Publisher
       ["objectUrl"             "objectId" "absolute" "path"]
       ; O2CMS::Html::PopupMenu
       ["PopupMenu"             "menuId" "element" "cssFile"]
;       ["addMenuItem"           "name:required" "action:required" "hoverAction" "icon"]
       ; O2Doc::Tutorial
       ["docCode"               "lang:required"]
       ["docCodeResult"         "useModule" "seeGeneratedHtml" "seeGeneratedHtmlAsDisplayed"]
       ["docLink"               "type:required" "id" "href" "title"]
       ["docList"               "class" "" "compact" "type" "id" "title" "style" "dir" "lang" "xml:lang" "" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["docListItem"           "class" "" "type" "value" "id" "title" "style" "dir" "lang" "xml:lang" "" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["docSection"            "title"]
       ; StringFormat
       ["substitute"            "from:required" "to" "literalMatch"]
       ["substring"             "from" "length" "replacement"]
       ["trim"                  "maxLength" "trail" "toolTip"]

       ; "Common" tags
       ["addItem"               "height" "width" "slidePaneItemId" "" "width" "icon" "id" "action" "name"]
       ["addCell"               "value" "align" "" "width" "action" "id" "icon"]
       ["addMenuItem"           "title:required" "icon" "expandIcon" "selected" "url" "elementId" "body" "" "name:required" "action:required" "hoverAction" "icon"]
      ]
)

(setq o2ml-html-tags-and-attributes
      [
       ["a"                     "charset" "coords" "href" "hreflang" "name" "rel" "rev" "shape" "target" "type" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" "tabIndex" "accessKey" ""
        "onFocus" "onBlur" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["abbr"                  "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblclick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["acronym"               "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["address"               "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["applet"                "height:required" "width:required" "align" "alt" "archive" "code" "codeBase" "hSpace" "name" "object" "title" "vSpace" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "accesskey" "tabindex" "onclick" "ondblclick" "onmousedown" "onmouseup" "onmouseover" "onmousemove" "onmouseout" "onkeypress" "onkeydown" "onkeyup"]
       ["area"                  "alt:required" "coords" "href" "nohref" "shape" "target" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" "tabIndex" "accessKey" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp" "onFocus" "onBlur"]
       ["base"                  "href:required" "target"]
       ["bdo"                   "dir:required" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang"]
       ["blockquote"            "cite" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["body"                  "alink" "background" "bgColor" "link" "text" "vlink" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onload" "onunload" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["br"                    "id" "class" "title" "style"]
       ["button"                "disabled" "name" "type" "value" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" "tabIndex" "accessKey" ""
        "onFocus" "onBlur" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["caption"               "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["cite"                  "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["code"                  "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["col"                   "align" "char" "charoff" "span" "valign" "width" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["colgroup"              "align" "char" "charoff" "span" "valign" "width" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["dd"                    "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["del"                   "cite" "datetime" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["div"                   "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["dfn"                   "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["dl"                    "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["dt"                    "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["em"                    "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["fieldset"              "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "accessKey" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["form",                 "action:required" "accept" "accept-charset" "enctype" "method" "name" "target" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onsubmit" "onreset" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["frame"                 "frameBorder" "longDesc" "marginHeight" "marginWidth" "name" "noResize" "scrolling" "src" ""
        "id" "class" "title" "style"]
       ["frameset"              "cols" "rows" ""
        "id" "class" "title" "style"]
       ["head"                  "profile" ""
        "dir" "lang" "xml:lang"]
       ["h1"                    "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["h2"                    "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["h3"                    "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["h4"                    "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["h5"                    "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["h6"                    "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["hr"                    "align" "noShade" "size" "width" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["html"                  "xmlns:required" ""
        "dir" "lang" "xml:lang"]
       ["iframe"                "align" "frameBorder" "height" "longDesc" "marginHeight" "marginWidth" "name" "scrolling" "src" "width" ""
        "id" "class" "title" "style"]
       ["img"                   "alt:required" "src:required" "align" "border" "height" "hSpace" "isMap" "longDesc" "useMap" "vSpace" "width" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["input"                 "accept" "align" "alt" "checked" "disabled" "maxLength" "name" "readOnly" "size" "src" "type" "value" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "tabIndex" "accessKey" "onFocus" "onBlur" "onSelect" "onChange" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["ins"                   "cite" "datetime" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["kbd"                   "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["label"                 "for" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "accessKey" "onFocus" "onBlur" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["legend"                "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "accessKey" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["li"                    "type" "value" "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["link"                  "charset" "href" "hrefLang" "media" "rel" "rev" "target" "type" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["map"                   "id:required" "name" ""
        "class" "title" "style" "dir" "lang" "xml:lang" ""
        "tabIndex" "accessKey" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp" "onFocus" "onBlur"]
       ["menu"                  "compact" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onFocus" "onBlur" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["meta"                  "content:required" "http-equiv" "name" "scheme" "dir" "lang" "xml:lang"]
       ["noframes"              "id" "class" "title" "style" "dir" "lang" "xml:lang"]
       ["noscript"              "id" "class" "title" "style" "dir" "lang" "xml:lang"]
       ["object"                "align" "archive" "border" "classId" "codeBase" "codeType" "data" "declare" "height" "hSpace" "name" "standBy" "type" "useMap" "vSpace" "width" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "accessKey" "tabIndex" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["ol"                    "compact" "start" "type" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["optgroup"              "label:required" "disabled" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "tabIndex" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["option"                "disabled" "label" "selected" "value" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["p"                     "align" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["param"                 "name:required" "type" "value" "valueType" ""
        "id"]
       ["pre"                   "width" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" "xml:space" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["q"                     "cite" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["s"                     "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["samp"                  "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["script"                "type:required" "charSet" "defer" "language" "src" "xml:space"]
       ["select"                "disabled" "multiple" "name" "size" "id" "class" "title" "style" "dir" "lang" "xml:lang" "" "accessKey" "tabIndex" "onFocus" "onBlur" "onChange"]
       ["span"                  "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["strike"                "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["strong"                "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["style"                 "type:required" "media" "title" "dir" "lang" "xml:space"]
       ["table"                 "align" "bgColor" "border" "cellPadding" "cellSpacing" "frame" "rules" "summary" "width" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["tbody"                 "align" "char" "charOff" "vAlign" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["td"                    "abbr" "align" "axis" "bgColor" "char" "charOff" "colSpan" "headers" "height" "noWrap" "rowSpan" "scope" "vAlign" "width" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["textarea"              "cols:required" "rows:required" "disabled" "name" "readOnly" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" "tabIndex" "accessKey" ""
        "onFocus" "onBlur" "onSelect" "onChange" "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["tfoot"                 "align" "char" "charOff" "vAlign" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["th"                    "abbr" "align" "axis" "bgColor" "char" "charOff" "colSpan" "headers" "height" "noWrap" "rowSpan" "scope" "vAlign" "width" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["thead"                 "align" "char" "charOff" "vAlign" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["title"                 "id" "class" "title" "style" "dir" "lang" "xml:lang"]
       ["tr"                    "align" "bgColor" "char" "charOff" "vAlign" ""
        "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["ul"                    "compact" "type" "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
       ["var"                   "id" "class" "title" "style" "dir" "lang" "xml:lang" ""
        "onClick" "onDblClick" "onMouseDown" "onMouseUp" "onMouseOver" "onMouseMove" "onMouseOut" "onKeyPress" "onKeyDown" "onKeyUp"]
      ]
)

(defun o2ml-mode ()
  "Major mode for o2ml templates.

There are mainly three things to remember:
 1. Use tab to indent
 2. Use Ctrl-return for completion
 3. Use C-c C-i to insert html entities

Features
========
 - Indentation of lines (tags, javascript and css)
 - Auto-completion of end-tags
 - Auto-completion/suggestion of modules
 - Auto-completion/suggestion of o2 start-tags
 - Auto-completion/suggestion of html start tags and attributes
 - Auto-completion/suggestion of css properties and values
 - Insertion and indentation of closing curly bracket
 - Customizable syntax highlighting
 - Insertion of html entities

Indentation
===========
You indent a line by pressing the tab key. The line is indented with respect to the previous line. Both javascript,
css and tags are indented. The way o2ml-mode decides if it should indent the line as a javascript/css line or as a
tag line is pretty much a qualified guess. If the previous line ends with an opening curly bracket, \"{\" (potentially
followed by a comment), or the current line starts with a closing curly bracket \"}\", it assumes javascript/css,
otherwise tags determine the indentation.

'indent-region' can be used to indent more than one line at a time. But you should check to see that the lines were
indented correctly. If you think o2ml-mode should have indented differently, please let me know (haakonsk@redpill-linpro.com).

When you press the slash key ('/') and the previous character is '<', the current line is automatically indented.
Javascript-/css-lines are also automatically indented when a closing curly bracket \"}\" is inserted as the first
non-space character on a line.

It is optional to close the following tags:
  link, br, hr, img, meta, input, area, param
Indentation should be correct both if you do or don't close them. It is recommended not to close them due to a bug slash
feature in O2's template parsing.

Other tags than those mentioned above must be closed.

One thing you should be aware of is greater than and less than signs in javascript (and css). Put spaces around them
(if possible) in order for o2ml-mode to understand that they are not part of a tag.
An example:
 Right:
  for (i = 0; i >= 2; i++) { ... }
 Wrong:
  for (i=0; i>=2; i++) { ... }

Auto-completion of end-tags
===========================
When the cursor is positioned after the string '</', optionally followed by some of the first letters in the end tag, you can
press Ctrl-return or (C-c C-f if Ctrl-return doesn't work) in order to insert the rest of the end tag. If you have started to
close a different tag than o2ml-mode thinks it's appropriate to close, you get a message in the mini-buffer telling you which
tag o2ml-mode wants to close.

If the string '</' is the first non-space characters on the current line, o2ml-mode searches for the end-tag by searhing upwards
for a line with the same indentation as the current line. If that line starts with a tag, the name of that tag is inserted along
with a greater than sign ('>').
If the string '</' is not the first non-space characters on the current line, then o2ml-mode searches backward in the buffer,
counting opening and closing tags until it finds the correct opening tag, and inserts its name and a greater than sign ('>').

In completing o2 tags, the space in the start tag is replaced by a colon, so if the start tag is <o2 if>, the end tag will be
</o2:if>

o2ml-mode does not try to close the following tags:
  link, br, hr, img, meta, input, area, param

Auto-completion/suggestion of modules
=====================================
If the cursor is placed after the string \"<o2 use \", you may hit Ctrl-return to get a popup-menu with all available modules.
If the cursor is placed after the string \"<o2 use Ht\" and you hit Ctrl-return, you will get a popup-menu with all modules
starting with the string \"Ht\". When one of the modules is chosen, the rest of the module name is inserted, along with the
string \" />\". If there's only one module matching the string when Ctrl-return is presesd, the rest of the module name is
inserted right away (no popup-menu).

Some (new) modules may be missing from the lists.

Auto-completion/suggestion of o2 start-tags and attributes
==========================================================
This is similar to auto-completion of modules. When the cursor is placed after the string \"<o2 \" and Ctrl-return is pressed, you will
get a popup-menu with all available tags. Only tags inside the used modules are available. The Core module tags are always available,
and the Html module tags are available if at least one module starting with \"Html\" is used. If the cursor is placed after a string
such as \"<o2 se\" and Ctrl-return is hit, you will get a popup-menu with all available o2 tags starting with \"se\". The tag name is
inserted when one of the items in the popup-menu is chosen. If only one available tag matches the given string, it is inserted without
displaying the popup-menu.

In auto-completion/suggestion of attributes, again you use Ctrl-return to see the list of attributes to choose from. If there's
only one matching attribute, that attribute is inserted along with the string =\".

Some (new) tags/attributes may be missing from the lists.

Auto-completion/suggestion of html start tags and attributes
============================================================
Auto-completion/suggestion of html start tags and attributes is \"the same\" as auto-completion/suggestion of o2 start tags.

Auto-completion/suggestion of css properties and values
=======================================================
Simlilar to other kinds of auto-completion/suggestion in o2ml-mode. Only standard css version 2.1 properties and values are included.

Insertion and indentation of closing curly bracket
==================================================
Hit Ctrl-return after an opening curly bracket, and the closing bracket is inserted with a blank line between the opening and closing
bracket. The blank line and the line with the closing bracket are indented. The cursor is moved to the blank line.

Customizable syntax highlighting
================================
Tags, javascript and a little bit of css is highlighted.

Syntax highlighting of javascript is very strict. The reason is that special words should not be highlighted in the wrong context.
Therefore, in order to be highlighted, 'if' must be the first word on a line, there must be at least one space in front of it, and
it must be followed by a space and an opening parenthesis.

The following items are highlighted:
- common for both html/o2ml, javascript and css
  - strings (but there's a problem with single quoted string around double quoted ones - only the inner string is highlighted)
  - perl variables
- html/o2ml
  - start-tags and end-tags
  - tag attributes (attribute name, attribute value (must be quoted) and the equals sign)
  - html comments
  - <o2 comment> tags (the end tag must be \"</o2:comment>\", not just \"</o2>\")
- javascript
  - comments
  - special words like if, else, for, true, false, continue, break, try, catch, var, return, function
  - function names (in the function definition)
  - the names of classes when the classes are instantiated
- css
  - comments
  - classes and ids

The colors and other font features of these items can be customized. Enter
  M-x customize-group RET o2ml-mode-fonts RET
in emacs to start customizing.

Insertion of html entities
==========================
Hitting C-c C-i asks you to enter a character, and the entity for that character is inserted.
For example, the entity for \"<\" is &lt;

Known bugs
==========
- Single quoted strings containing double quoted strings aren't displayed as strings
- Problem with odd number of quotes inside comments.
- Comments spanning a big number of lines usually don't get the 'comment color'
- Tags inside strings show as tags
- Problem with attribute completion when there's a greater than sign in an attribute value (f ex $lang->getString(..))

Todo
====
- Fix bugs
- Better way to decide what to highlight
- Javascript: Indent relative to other parenthesis than curly brackets
- Attribute completion not just on the first line
- Auto-complete as much as possible before popping up the menu
- Css media type completion
- Align first attribute on second line with first element on first line
" ; "
  (interactive)
  (kill-all-local-variables)
  (set (make-local-variable 'font-lock-defaults) (list o2ml-font-lock-keywords-1))
  (set (make-local-variable 'font-lock-multiline) t) ; I think this helps make multiline comments keep their correct color better (but still not perfect)
  (set (make-local-variable 'indent-line-function) 'o2ml-indent-line)
  (use-local-map o2ml-mode-map)
  (set-syntax-table o2ml-mode-syntax-table)
  (make-local-variable 'font-lock-defaults)

  (setq major-mode 'o2ml-mode)
  (setq mode-name "o2ml")
)

(defun o2ml-get-used-modules ()
  "Search for lines with <o2 use ... /> above point, and return all the modules found in this way"
  ; Core is always available, Html is available if Html::* is used.
  (save-excursion
    (let ((line)
          (modules '("Core"))
          (module-name)
          (quit nil))
;      (beginning-of-buffer)
;      (while (not (eobp))
      (while (not quit)
        (setq line (o2-read-line))
        (if (string-match " *<o2 use \\(\"\\|'\\)?\\([a-zA-Z0-9:]+\\)\\(\"\\|'\\)? */>" line)
            (progn
              (setq module-name (match-string 2 line))
              (if (not (o2-list-contains-p modules module-name))
                  (setq modules (cons module-name modules))
              )
              (if (and (string-match "^Html::" module-name)
                       (not (o2-list-contains-p modules "Html")))
                  (setq modules (cons "Html" modules))
              )
            )
        )
        (if (bobp)
            (setq quit t)
          (forward-line -1)
        )
      )
      modules
    )
  )
)

(defun o2ml-get-available-tags ()
  (let ((i 0)
        (j 0)
        (module-with-tags)
        (modules (o2ml-get-used-modules))
        (tags nil))
    (while (< i (length o2ml-modules-and-tags))
      (setq module-with-tags (aref o2ml-modules-and-tags i))
      (if (o2-list-contains-p modules (aref module-with-tags 0))
          (progn
            (setq j 1)
            (while (< j (length module-with-tags))
              (setq tags (cons (aref module-with-tags j) tags))
              (setq j (1+ j))
            )
          )
      )
      (setq i (1+ i))
    )
    tags
  )
)

(defun o2ml-indent-line-if-end-tag ()
  (interactive)
  (insert "/")
  (if (equal (o2-previous-char 2) "<")
      (o2ml-indent-line)
  )
)

(defun o2ml-indent-line-if-js-or-css ()
  (interactive)
  (insert "}")
  (if (o2-backward-looking-at "^ *}")
      (o2ml-indent-line)
  )
  (blink-matching-open)
)

(defun o2ml-show-tags-menu (tag-starts-with)
  (let ((tags)
        (chosen-module)
        (all-tags (o2ml-get-available-tags)))
    (setq tags (o2ml-get-elements-starting-with all-tags tag-starts-with))
    ; Sort in alphabetical order
    (if (= (length tag-starts-with) 0) ; Hack. Problem with some items not being shown when we sort
        (sort tags 'string-lessp)
    )
    (setq tags (reverse tags))
    ; We've found the matching modules, display them in a menu:
    (setq chosen-tag
          (o2ml-show-menu-and-return-chosen-item "Choose tag" tags t "No matching tags found"))
    (if (> (length chosen-tag) 0)
        (o2ml-insert-tag chosen-tag)
    )
  )
)

(defun o2ml-insert-tag (tag)
  (let ((string (o2-backward-looking-at "<\\(o2 \\)?\\([a-zA-Z0-9]*\\)")))
    (setq string (match-string 2 string))
    (insert (substring tag (length string)))
    (insert " ")
  )
)

(defun o2ml-show-modules-menu (module-starts-with)
  "Find matching modules and display them in a menu"
  (let ((modules nil)
        (chosen-module)
        (all-modules (o2ml-get-all-modules)))
    (setq modules (o2ml-get-elements-starting-with all-modules module-starts-with))
    ; Sort in alphabetical order
    (if (= (length module-starts-with) 0) ; Hack. Problem with some items not being shown when we sort
        (sort modules 'string-lessp)
    )
    (setq modules (reverse modules))
    ; We've found the matching modules, display them in a menu:
    (setq chosen-module
          (o2ml-show-menu-and-return-chosen-item "Choose module" modules t "No matching modules found"))
    (if (> (length chosen-module) 0)
        (o2ml-insert-module chosen-module)
    )
  )
)

(defun o2ml-show-css-properties-menu (property-starts-with)
  (let ((properties nil)
        (chosen-property)
        (all-properties (o2ml-get-all-css-properties)))
    (setq properties (o2ml-get-elements-starting-with all-properties property-starts-with))
    ; Sort in alphabetical order
    (if (= (length property-starts-with) 0) ; Hack. Problem with some items not being shown when we sort
        (sort properties 'string-lessp)
    )
    (setq properties (reverse properties))
    ; We've found the matching properties, display them in a menu:
    (setq chosen-property
          (o2ml-show-menu-and-return-chosen-item "Choose css property" properties t "No matching css properties found"))
    (if (> (length chosen-property) 0)
        (o2ml-insert-css-property chosen-property)
    )
  )
)

(defun o2ml-show-css-property-values-menu (property property-value-starts-with)
  (let ((property-values nil)
        (chosen-property-value)
        (all-property-values (o2ml-get-all-css-property-values property)))
    (setq property-values (o2ml-get-elements-starting-with all-property-values property-value-starts-with))
    ; Sort in alphabetical order
;    (if (= (length property-value-starts-with) 0) ; Hack. Problem with some items not being shown when we sort
;        (sort property-values 'string-lessp)
;    )
;    (setq property-values (reverse property-values))
    ; We've found the matching property-values, display them in a menu:
    (setq chosen-property-value
          (o2ml-show-menu-and-return-chosen-item "Choose property" property-values t "No matching property-values found"))
    (if (> (length chosen-property-value) 0)
        (o2ml-insert-css-property-value chosen-property-value)
    )
  )
)

(defun o2ml-show-menu-and-return-chosen-item (title items &optional insert-if-one-match no-match-string)
  (let ((current-item)
        (current-item-visible-value)
        (menu-items)
        (chosen-item))
    (if (and insert-if-one-match
             (equal (length items) 1)
             (not (string-match ":no-value" (car items))))
        (car items) ; Returning
      (if (and no-match-string
               (not items))
          (progn
            (message "%s" no-match-string)
            "" ; Returning
          )
        (while items
          (setq current-item (car items))
          (setq current-item-visible-value current-item)
          (if (string-match "\\(.+\\):required" current-item) ; Required attributes
              (setq current-item-visible-value (concat (match-string 1 current-item) " (required)"))
          )
          (if (string-match "\\(.+\\):param" current-item)
              (setq current-item-visible-value (match-string 1 current-item))
          )
          (if (string-match "\\(.+\\):quote-value" current-item)
              (setq current-item-visible-value (match-string 1 current-item))
            )
          (if (string-match "\\(.+\\):no-value" current-item)
              (setq current-item-visible-value (match-string 1 current-item))
          )
          (setq current-item (o2ml-fix-menu-item current-item))
          (setq menu-items (cons (list current-item-visible-value current-item) menu-items))
          (setq items (cdr items))
        )
        (setq chosen-item (x-popup-menu t
                                        (list title
                                              (cons "Dummy" menu-items))))
        (setq chosen-item (car chosen-item))
        chosen-item
      )
    )
  )
)

(defun o2ml-fix-menu-item (item)
  (if (string-match "\\(.+\\):required" item) ; Required attributes
      (setq item (match-string 1 item))
  )
  (if (string-match "\\(.+\\):quote-value" item)
      (setq item (concat "\"" (match-string 1 item) "\""))
  )
  (if (string-match "\\(.+\\):no-value" item)
      (setq item "")
  )
  item
)

(defun o2ml-insert-module (module)
  (let ((quote)
        (string (o2-backward-looking-at "<o2 use \\([\"']?\\)\\([a-zA-Z0-9:]*\\)")))
    (setq quote  (match-string 1 string))
    (setq string (match-string 2 string))
    (insert (substring module (length string)))
    (insert (concat quote " />"))
  )
)

(defun o2ml-show-html-tags-menu (tag-starts-with)
  (let ((tags))
    (setq tags (o2ml-get-elements-starting-with (o2ml-get-all-html-tags) tag-starts-with))
    (setq tags (reverse tags))
    (o2ml-insert-tag (o2ml-show-menu-and-return-chosen-item "Choose tag" tags t "No matching html tags found"))
  )
)

(defun o2ml-show-html-attributes-menu (tagname attribute-starts-with)
  (let ((attributes)
        (attribute))
    (setq attributes
          (o2ml-get-elements-starting-with (o2ml-get-legal-html-attributes tagname) attribute-starts-with))
    (setq attribute (o2ml-show-menu-and-return-chosen-item "Choose attribute" attributes t "No matching attributes found"))
    (if (> (length attribute) 0)
        (o2ml-insert-attribute attribute)
    )
  )
)

(defun o2ml-show-o2-attributes-menu (o2-tagname attribute-starts-with)
  (let ((attributes)
        (attribute))
    (setq attributes
          (o2ml-get-elements-starting-with (o2ml-get-legal-o2-attributes o2-tagname) attribute-starts-with))
    (setq attribute (o2ml-show-menu-and-return-chosen-item "Choose attribute" attributes t "No matching attributes found"))
    (if (> (length attribute) 0)
        (o2ml-insert-attribute attribute)
    )
  )
)

(defun o2ml-insert-attribute (attribute)
  (let ((string (o2-backward-looking-at " +\\([a-zA-Z]*\\)")))
    (setq string (match-string 1 string))
    (setq attribute (o2ml-fix-menu-item attribute))
    (if (string-match "\\(.+\\):param" attribute)
        (insert (concat (substring (match-string 1 attribute) (length string)) " "))
      (insert (substring attribute (length string)))
      (insert "=\"")
;      (goto-char (- (point) 1))
    )
  )
)

(defun o2ml-insert-css-property (property)
  (let ((string (o2-backward-looking-at " +\\([a-zA-Z0-9-]*\\)")))
    (setq string (match-string 1 string))
    (setq property (o2ml-fix-menu-item property))
    (insert (substring property (length string)))
  )
)

(defun o2ml-insert-css-property-value (property-value)
  (o2ml-insert-css-property property-value)
)

(defun o2ml-get-elements-starting-with (all-elements must-start-with)
  (let ((elements)
        (current-element))
    (setq must-start-with (concat "^" must-start-with))
    (while all-elements
      (setq current-element (car all-elements))
      (setq all-elements (cdr all-elements))
      (if (string-match must-start-with current-element)
          (setq elements (cons current-element elements))
      )
    )
    elements
  )
)

(defun o2ml-get-legal-html-attributes (tagname)
  (o2ml-get-legal-attributes tagname o2ml-html-tags-and-attributes)
)

(defun o2ml-get-legal-o2-attributes (tagname)
  (o2ml-get-legal-attributes tagname o2ml-o2-tags-and-attributes)
)

; XXX Not just used with tags
(defun o2ml-get-legal-attributes (tagname tags-and-attributes)
  (let ((found nil)
;        (tags-and-attributes o2ml-html-tags-and-attributes)
        (tag-with-attributes)
        (count 0)
        (attributes nil)
        (i 1))
    (while (and (not found)
                (< count (length tags-and-attributes)))
      (setq tag-with-attributes (aref tags-and-attributes count))
      (if (equal (aref tag-with-attributes 0) tagname)
          (progn
            (setq found t)
            (while (< i (length tag-with-attributes))
              (setq attributes (cons (aref tag-with-attributes i) attributes))
              (setq i (1+ i))
            )
          )
      )
      (setq count (1+ count))
    )
    ; Sort in alphabetical order
;    (sort attributes 'string-lessp)
    (setq attributes (reverse attributes))

    attributes
  )
)

(defun o2ml-get-all-modules ()
  (let ((modules)
        (tmp-module-and-tags)
        (count 0)
        (modules-and-tags o2ml-modules-and-tags)
        (module-with-tags))
    (while (< count (length modules-and-tags))
      (setq module-with-tags (aref modules-and-tags count))
      (setq module           (aref module-with-tags 0))
      (setq count (1+ count))
      (setq modules (cons module modules))
    )
    modules
  )
)

(defun o2ml-get-all-html-tags ()
  (let ((tags)
        (tag)
        (tmp-tags-and-attribs)
        (count 0)
        (tags-and-attribs o2ml-html-tags-and-attributes)
        (tag-with-attribs))
    (while (< count (length tags-and-attribs))
      (setq tag-with-attribs (aref tags-and-attribs count))
      (setq tag              (aref tag-with-attribs 0))
      (setq count (1+ count))
      (setq tags (cons tag tags))
    )
    tags
  )
)

(defun o2ml-get-all-css-properties ()
  (let ((properties)
        (tmp-property-and-values)
        (count 0)
        (properties-and-values o2ml-css-attributes-and-values)
        (property-with-values))
    (while (< count (length properties-and-values))
      (setq property-with-values (aref properties-and-values count))
      (setq property             (aref property-with-values 0))
      (setq count (1+ count))
      (setq properties (cons property properties))
    )
    properties
  )
)

(defun o2ml-get-all-css-property-values (property)
  (o2ml-get-legal-attributes property o2ml-css-attributes-and-values)
)

; Dispatch to o2ml-tags-indent-line or o2-javascript-or-css-indent-line
(defun o2ml-indent-line ()
  (let ((previous-line)
        (current-line))
    (setq current-line (o2-read-line))
    (save-excursion
      (forward-line -1)
      (while (looking-at "^[ \t]*$") ; Blank line
        (forward-line -1)
      )
      (setq previous-line (o2-read-line))
    )
    (if (or
         (string-match " *{[ \t]*\\(//.*\\|/[*].*[*]/\\)?$" previous-line)
         (string-match " */[*][ \t]*$"                      previous-line)
         (string-match "^[ \t]*}"                           current-line)
         (string-match "^[ \t]*[*]/"                        current-line)
         (and (     string-match "/[*]" previous-line)
              (not (string-match "[*]/" previous-line)))
         )
        (o2-javascript-or-css-indent-line)
      (o2ml-tags-indent-line)
    )
  )
)

(defun o2ml-tags-indent-line ()
  (let ((previous-indent 0)
        (new-indent      0)
        (num-start-tags  0)
        (num-end-tags    0)
        (line           "")
        (string         "") ; Starts out as a copy of line
        (current-tag    "")
        (num-blank-lines 0)
        )
    (save-excursion
      (beginning-of-line)
      (if (bobp) ; If beginning of buffer, indent to 0
          (indent-line-to 0)
        ; else:
        (forward-line -1)
        (while (looking-at "^[ \t]*$") ; Blank line
          (if (looking-at "^ *\t")
              (o2-fix-tabs)
          )
          (setq num-blank-lines (1+ num-blank-lines))
          (forward-line -1)
        )
        (setq line (o2-read-line))
        ; Remove tabs if they're present:
        (if (string-match "\t" line)
            (progn
              (o2-fix-tabs)
              (setq line (o2-read-line))
            )
        )
        (setq string line)
        (setq previous-indent (skip-chars-forward " "))
        (while (string-match "\\(<[a-zA-Z][a-zA-Z0-9]*?\\>\\|<!--\\)" string) ; Count start tags
          (setq current-tag (substring string (1+ (match-beginning 0)) (match-end 0))) 
          (setq string      (substring string (1+ (match-beginning 0))))
          ; If the tag is one of {link, br, hr, img, meta, input, area, param}, then if it has not been closed, then don't increment count.
          (if (and
               (string-match "^\\(link\\|br\\|hr\\|img\\|meta\\|input\\|area\\|param\\)$" current-tag)
               (not (o2ml-tag-closed-p current-tag string)))
              (setq num-start-tags (1- num-start-tags)) ; A little hack...
          )
          (setq num-start-tags (1+ num-start-tags))
        )
        (setq string line)
        (setq new-indent previous-indent)
        (if (string-match "^ *</" string)
            (setq new-indent (+ 2 new-indent))
        )
        (while (string-match "\\(</\\|/>\\|-->\\)" string) ; Count end tags
          (setq string (substring string (1+ (match-beginning 0))))
          (setq num-end-tags (1+ num-end-tags))
        )
        (forward-line (+ num-blank-lines 1))
        (setq string (o2-read-line))
        (if (string-match "^ *</" string)
            (setq new-indent (- new-indent 2))
        )
        (setq new-indent (+ new-indent (* 2 num-start-tags)))
        (setq new-indent (- new-indent (* 2 num-end-tags)))
        (if (< new-indent 0)
            (message "Don't know how to indent this line")
          (indent-line-to new-indent)
        )
      )
    )
    (if (> new-indent 0)
        (skip-chars-forward " ")
    )
  )
)

;(defun o2ml-complete-tag-with-space ()
;  (interactive)
;  (if (not (o2ml-complete-end-tag))
;      (insert " ")
;  )
;)

; XXX Change name of this method
(defun o2ml-complete-tag-dispatch ()
  (interactive)
  (if (o2-backward-looking-at "\t")
      (o2-fix-tabs)
  )
  (let ((string))
    (setq string (o2-backward-looking-at "<o2 use \\([\"']?\\)\\([a-zA-Z0-9:]*\\)"))
    (if string
        (o2ml-show-modules-menu (match-string 2 string))
      (setq string (o2-backward-looking-at "<o2 \\([a-zA-Z0-9]*\\)"))
      (if string
          (o2ml-show-tags-menu (match-string 1 string))
        (setq string (o2-backward-looking-at "<\\([a-zA-Z]*\\)"))
        (if string
            (o2ml-show-html-tags-menu (match-string 1 string))
          (setq string (o2-backward-looking-at "<\\([a-zA-Z]+\\) +[^>]*?\\([a-zA-Z]*\\)"))
          (if string
              (o2ml-show-html-attributes-menu (match-string 1 string) (match-string 2 string))
            (setq string (o2-backward-looking-at "<o2 \\([a-zA-Z0-9]+\\) +[^>]*?\\([a-zA-Z]*\\)")) ; XXX Doesn't allow $lang->getString...
            (if string
                (o2ml-show-o2-attributes-menu (match-string 1 string) (match-string 2 string))
              (setq string (o2-backward-looking-at "^ +\\([a-zA-Z-]+\\) *:.*? +\\([a-zA-Z-]*\\)"))
              (if string
                  (o2ml-show-css-property-values-menu (match-string 1 string) (match-string 2 string))
                (setq string (o2-backward-looking-at "^ +\\([a-zA-Z-]*\\)"))
                (if string
                    (o2ml-show-css-properties-menu (match-string 1 string))
                  (setq string (o2-backward-looking-at "{"))
                  (if string
                      (o2-insert-end-bracket)
                    (setq string (o2-backward-looking-at "[^2]:"))
                    (if string
                        (o2-css-align-colons)
                      (setq string (o2-backward-looking-at " [0-9]+")) ; Maybe a little stricter?
                      (if string
                          (insert (o2ml-show-menu-and-return-chosen-item "Choose css length unit" o2ml-css-units t))
                        (o2ml-complete-end-tag)
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

; Alternative 1: Search backward for "</" or "<". If "</", increment count. If "<", descrement count. If count is 0, we have our tag.
; Alternative 2: Find tag with the correct indentation. <--
; Returns true if the tag was completed successfully
(defun o2ml-complete-end-tag ()
  (let ((stored-point (point))
        end-tag
        string)
    (setq string (o2-backward-looking-at "</[a-zA-Z][a-zA-Z0-9:]*"))
    (if (or (o2-backward-looking-at "</")
            string)
        (progn
          (beginning-of-line)
          (if (looking-at " *</\\([a-zA-Z][a-zA-Z0-9:]*\\)?$")
              (progn
                (end-of-line)
                (setq end-tag (o2ml-get-end-tag-by-indentation))
              )
            (goto-char stored-point)
            (setq end-tag (o2ml-get-end-tag-by-backward-search))
          )
          (if end-tag
              (if string
                  (if (equal (substring end-tag 0 (- (length string) 2)) (substring string 2))
                      (progn
                        (insert (substring end-tag (- (length string) 2)) ">")
                        t
                      )
                    (message "Looks like you're trying to close the wrong tag. I think %s is the tag to close here." end-tag)
                    nil
                  )
                (insert end-tag ">")
                t
              )
          )
        )
    )
  )
)

(defun o2ml-get-end-tag-by-backward-search ()
  (save-excursion
    (let ((end-tag (o2ml-get-current-open-tag t)))
      end-tag
    )
  )
)

(defun o2ml-get-current-open-tag (&optional close-tag-p)
  (save-excursion
    (let ((count 1)
          end-tag)
      (if close-tag-p
          (progn
            (skip-chars-backward "^</")
            (goto-char (- (point) 2)) ; Go backward past the "<" or "/>"
          )
      )
      (while (and (not (bobp))
                  (> count 0))
        (skip-chars-backward "^</")
        (if (and (equal (o2-previous-char) "/")
                 (equal (o2-previous-char 2) "<")) ; "</"
            (setq count (1+ count))
          (if (and (looking-at ">")
                   (equal (o2-previous-char) "/")) ; "/>"
              (setq count (1+ count))
            (if (and (looking-at "o2 \\([a-zA-Z]+\\)")
                     (equal (o2-previous-char) "<")) ; "<o2"
                (progn
                  (setq count (1- count))
                  (setq end-tag (concat "o2:" (match-string 1)))
                )
              (if (and (equal (o2-previous-char) "<")
                       (looking-at "[a-zA-Z][a-zA-Z0-9]*")) ; "<"
                  (progn
                      (setq end-tag (match-string 0))
                      (if (and
                           (string-match "^\\(link\\|br\\|hr\\|img\\|meta\\|input\\|area\\|param\\)$" end-tag)
                           (not (o2ml-tag-closed-p end-tag (o2-read-line))))
                          nil
                        (setq count (1- count))
                      )
                  )
              )
            )
          )
        )
        (goto-char (- (point) 2)) ; Go backward 2 characters
      )
      (if (and end-tag
               (equal count 0)) 
          end-tag
        ""
      )
    )
  )
)

(defun o2ml-get-end-tag-by-indentation ()
  (save-excursion
    (beginning-of-line)
    (let ((indent 0)
          (current-indent (skip-chars-forward " ")))
      (forward-line -1)
      (setq indent (skip-chars-forward " "))
      (while (and (not (bobp))
                  (or
                   (/= indent current-indent)
                   (not (looking-at " *<"))))
        (forward-line -1)
        (setq indent (skip-chars-forward " "))
      )
      (if (equal indent current-indent)
          (progn
            (if (looking-at "<o2 \\([a-zA-Z]+\\)")
                (concat "o2:" (match-string 1))
              (if (looking-at "<\\([a-zA-Z]+\\)")
                  (match-string 1)
              )
            )
          )
        nil
      )
    )
  )
)

; Is CURRENT-TAG closed on LINE?
(defun o2ml-tag-closed-p (current-tag line)
  (let (return-value)
    (if (or
         (string-match (concat "\\(^\\|<\\)" current-tag "[^<]*/>")                    line)
         (string-match (concat "\\(^\\|<\\)" current-tag "[^<]*> *</" current-tag ">") line))
        (setq return-value t)
      (setq return-value nil)
    )
    return-value
  )
)

(defun o2ml-remove-tabs ()
  "Replaces every tab character in the buffer with the specified number of spaces.
Indentation in o2ml-mode doesn't work very well with tab characters, so replacing them
with spaces is a good idea. In addition you should disable tabs in your .emacs file:

  ;; Insert spaces instead of tabs
  (setq-default indent-tabs-mode nil)
"
  (interactive)
  (save-excursion
    (beginning-of-buffer)
    (let (spaces
          (num-tabs-replaced 0)
          (count 0))
      (while (< count default-tab-width)
        (setq count (1+ count))
        (setq spaces (concat spaces " "))
      )
      (while (search-forward "\t" nil t)
        (replace-match spaces nil t)
        (setq num-tabs-replaced (1+ num-tabs-replaced))
      )
      (message "Replaced %d tabs with %d spaces per tab" num-tabs-replaced default-tab-width)
    )
  )
)

(defun o2ml-insert-entity (char)
  (interactive "cInsert entity for this character: ")
  (setq o2ml-inserted-entity "")
  ; Html special characters
  (if (equal char ?<)  (o2ml-do-insert-entity "&lt;")     )
  (if (equal char ?>)  (o2ml-do-insert-entity "&gt;")     )
  (if (equal char ?\") (o2ml-do-insert-entity "&quot;")   )
  (if (equal char ?')  (o2ml-do-insert-entity "&apos;")   )
  (if (equal char ?&)  (o2ml-do-insert-entity "&amp;")    )
  ; Symbols
  (if (equal char ?$)  (o2ml-do-insert-entity "&#36;")    )
  (if (equal char 161) (o2ml-do-insert-entity "&iexcl;")  )
  (if (equal char 162) (o2ml-do-insert-entity "&cent;")   )
  (if (equal char 163) (o2ml-do-insert-entity "&pound;")  )
  (if (equal char 164) (o2ml-do-insert-entity "&curren;") )
  (if (equal char 165) (o2ml-do-insert-entity "&yen;")    )
  (if (equal char 166) (o2ml-do-insert-entity "&brvbar;") )
  (if (equal char 167) (o2ml-do-insert-entity "&sect;")   )
  (if (equal char 168) (o2ml-do-insert-entity "&uml;")    )
  (if (equal char 169) (o2ml-do-insert-entity "&copy;")   )
  (if (equal char 170) (o2ml-do-insert-entity "&ordf;")   )
  (if (equal char 171) (o2ml-do-insert-entity "&laquo;")  )
  (if (equal char 172) (o2ml-do-insert-entity "&not;")    )
  (if (equal char 173) (o2ml-do-insert-entity "&shy;")    )
  (if (equal char 174) (o2ml-do-insert-entity "&reg;")    )
  (if (equal char 175) (o2ml-do-insert-entity "&macr;")   )
  (if (equal char 176) (o2ml-do-insert-entity "&deg;")    )
  (if (equal char 177) (o2ml-do-insert-entity "&plusmn;") )
  (if (equal char 178) (o2ml-do-insert-entity "&sup2;")   )
  (if (equal char 179) (o2ml-do-insert-entity "&sup3;")   )
  (if (equal char 180) (o2ml-do-insert-entity "&acute;")  )
  (if (equal char 181) (o2ml-do-insert-entity "&micro;")  )
  (if (equal char 182) (o2ml-do-insert-entity "&para;")   )
  (if (equal char 183) (o2ml-do-insert-entity "&middot;") )
  (if (equal char 184) (o2ml-do-insert-entity "&cedil;")  )
  (if (equal char 185) (o2ml-do-insert-entity "&sup1;")   )
  (if (equal char 186) (o2ml-do-insert-entity "&ordm;")   )
  (if (equal char 187) (o2ml-do-insert-entity "&raquo;")  )
  (if (equal char 188) (o2ml-do-insert-entity "&frac14;") )
  (if (equal char 189) (o2ml-do-insert-entity "&frac12;") )
  (if (equal char 190) (o2ml-do-insert-entity "&frac34;") )
  (if (equal char 191) (o2ml-do-insert-entity "&iquest;") )
  (if (equal char 215) (o2ml-do-insert-entity "&times;")  )
  (if (equal char 247) (o2ml-do-insert-entity "&divide;") )
  ; æ, ø, å
  (if (equal char 230) (o2ml-do-insert-entity "&aelig;")  )
  (if (equal char 198) (o2ml-do-insert-entity "&AElig;")  )
  (if (equal char 248) (o2ml-do-insert-entity "&oslash;") )
  (if (equal char 216) (o2ml-do-insert-entity "&Oslash;") )
  (if (equal char 229) (o2ml-do-insert-entity "&aring;")  )
  (if (equal char 197) (o2ml-do-insert-entity "&Aring;")  )
  ; More strange letters
  (if (equal char 192) (o2ml-do-insert-entity "&Agrave;") )
  (if (equal char 193) (o2ml-do-insert-entity "&Aacute;") )
  (if (equal char 194) (o2ml-do-insert-entity "&Acirc;")  )
  (if (equal char 195) (o2ml-do-insert-entity "&Atilde;") )
  (if (equal char 196) (o2ml-do-insert-entity "&Auml;")   )
  (if (equal char 199) (o2ml-do-insert-entity "&Ccedil;") )
  (if (equal char 200) (o2ml-do-insert-entity "&Egrave;") )
  (if (equal char 201) (o2ml-do-insert-entity "&Eacute;") )
  (if (equal char 202) (o2ml-do-insert-entity "&Ecirc;")  )
  (if (equal char 203) (o2ml-do-insert-entity "&Euml;")   )
  (if (equal char 204) (o2ml-do-insert-entity "&Igrave;") )
  (if (equal char 205) (o2ml-do-insert-entity "&Iacute;") )
  (if (equal char 206) (o2ml-do-insert-entity "&Icirc;")  )
  (if (equal char 207) (o2ml-do-insert-entity "&Iuml;")   )
  (if (equal char 208) (o2ml-do-insert-entity "&ETH;")    )
  (if (equal char 209) (o2ml-do-insert-entity "&Ntilde;") )
  (if (equal char 210) (o2ml-do-insert-entity "&Ograve;") )
  (if (equal char 211) (o2ml-do-insert-entity "&Oacute;") )
  (if (equal char 212) (o2ml-do-insert-entity "&Ocirc;")  )
  (if (equal char 213) (o2ml-do-insert-entity "&Otilde;") )
  (if (equal char 214) (o2ml-do-insert-entity "&Ouml;")   )
  (if (equal char 217) (o2ml-do-insert-entity "&Ugrave;") )
  (if (equal char 218) (o2ml-do-insert-entity "&Uacute;") )
  (if (equal char 219) (o2ml-do-insert-entity "&Ucirc;")  )
  (if (equal char 220) (o2ml-do-insert-entity "&Uuml;")   )
  (if (equal char 221) (o2ml-do-insert-entity "&Yacute;") )
  (if (equal char 222) (o2ml-do-insert-entity "&THORN;")  )
  (if (equal char 223) (o2ml-do-insert-entity "&szlig;")  )
  (if (equal char 224) (o2ml-do-insert-entity "&agrave;") )
  (if (equal char 225) (o2ml-do-insert-entity "&aacute;") )
  (if (equal char 226) (o2ml-do-insert-entity "&acirc;")  )
  (if (equal char 227) (o2ml-do-insert-entity "&atilde;") )
  (if (equal char 228) (o2ml-do-insert-entity "&auml;")   )
  (if (equal char 231) (o2ml-do-insert-entity "&ccedil;") )
  (if (equal char 232) (o2ml-do-insert-entity "&egrave;") )
  (if (equal char 233) (o2ml-do-insert-entity "&eacute;") )
  (if (equal char 234) (o2ml-do-insert-entity "&ecirc;")  )
  (if (equal char 235) (o2ml-do-insert-entity "&euml;")   )
  (if (equal char 236) (o2ml-do-insert-entity "&igrave;") )
  (if (equal char 237) (o2ml-do-insert-entity "&iacute;") )
  (if (equal char 238) (o2ml-do-insert-entity "&icirc;")  )
  (if (equal char 239) (o2ml-do-insert-entity "&iuml;")   )
  (if (equal char 240) (o2ml-do-insert-entity "&eth;")    )
  (if (equal char 241) (o2ml-do-insert-entity "&ntilde;") )
  (if (equal char 242) (o2ml-do-insert-entity "&ograve;") )
  (if (equal char 243) (o2ml-do-insert-entity "&oacute;") )
  (if (equal char 244) (o2ml-do-insert-entity "&ocirc;")  )
  (if (equal char 245) (o2ml-do-insert-entity "&otilde;") )
  (if (equal char 246) (o2ml-do-insert-entity "&ouml;")   )
  (if (equal char 249) (o2ml-do-insert-entity "&ugrave;") )
  (if (equal char 250) (o2ml-do-insert-entity "&uacute;") )
  (if (equal char 251) (o2ml-do-insert-entity "&ucirc;")  )
  (if (equal char 252) (o2ml-do-insert-entity "&uuml;")   )
  (if (equal char 253) (o2ml-do-insert-entity "&yacute;") )
  (if (equal char 254) (o2ml-do-insert-entity "&thorn;")  )
  (if (equal char 255) (o2ml-do-insert-entity "&yuml;")   )

  (if (equal (length o2ml-inserted-entity) 0)
      (message "Didn't find entity for %c" char)
    (message "Inserted entity for character %c" char)
  )
;  (message "%d" char)
)

(defun o2ml-do-insert-entity (entity)
  (setq o2ml-inserted-entity entity)
  (insert entity)
)

(provide 'o2ml-mode)
