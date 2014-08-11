o2.require("/js/DOMUtil.js");

o2.autoResize = {};

var RESIZE_TEXTAREA_MINIMUM_HEIGHTS = new Array();
var RESIZE_TEXTAREA_KEY_PRESSED     = new Array();

o2.autoResize.resizeTextarea = function(id) {
  if (RESIZE_TEXTAREA_MINIMUM_HEIGHTS[id] && !RESIZE_TEXTAREA_KEY_PRESSED[id]) { // Not first time and no key pressed
    setTimeout("o2.autoResize.resizeTextarea('" + id + "')", 1000);
    return;
  }
  var textarea = document.getElementById(id);
  if (!RESIZE_TEXTAREA_MINIMUM_HEIGHTS[id]) {
    o2.addEvent(textarea, "keydown", o2.autoResize.resizeTextareaKeyPressed);
    var height = parseInt( textarea.style.height );
    if (!height) {
      var numRows    = textarea.rows || 5;
      var lineHeight = parseInt( o2.getComputedStyle(textarea, "lineHeight") )  ||  10;
      height = numRows * lineHeight;
    }
    RESIZE_TEXTAREA_MINIMUM_HEIGHTS[id] = height;
  }
  textarea.style.height = 0;
  var newHeight = textarea.scrollHeight < RESIZE_TEXTAREA_MINIMUM_HEIGHTS[id]  ?  RESIZE_TEXTAREA_MINIMUM_HEIGHTS[id]  :  textarea.scrollHeight;
  textarea.style.height = newHeight + "px";
  setTimeout("o2.autoResize.resizeTextarea('" + id + "')", 1000);
  RESIZE_TEXTAREA_KEY_PRESSED[id] = false;
}

o2.autoResize.resizeTextareaKeyPressed = function(e) {
  RESIZE_TEXTAREA_KEY_PRESSED[ e.getTarget().id ] = true;
}
