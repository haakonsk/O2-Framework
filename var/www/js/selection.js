o2.require("/js/range.js");

o2.selection = {};

o2.selection.getSelection = function(win, doc) {
  win = win || window;
  if (win.getSelection) {
    return win.getSelection();
  }
  doc = doc || document;
  return document.selection;
}

o2.selection.removeAllSelections = function() {
  o2.selection.removeAllRanges( o2.selection.getSelection() );
}

o2.selection.selectRange = function(range, selection) {
  o2.selection.removeAllRanges(selection);
  o2.selection.addRange(selection, range);
}

o2.selection.removeAllRanges = function(selection) {
  if (selection.removeAllRanges) {
    return selection.removeAllRanges();
  }
  if (selection.empty) {
    return selection.empty();
  }
  alert("Couldn't remove selection");
}

o2.selection.addRange = function(selection, range) {
  if (selection.addRange) {
    return selection.addRange(range);
  }
  if (range.select) {
    return range.select();
  }
}

o2.selection.selectText = function(node, text) {
  var nodeContent = node.innerHTML;
  text = text.replace("<", "&lt;");
  text = text.replace(">", "&gt;");
  if (nodeContent.indexOf(text) !== -1) {
    var position = nodeContent.indexOf(text);
    var range = o2.range.createRange(node, position, position + text.length);
    o2.selection.selectRange( range, o2.selection.getSelection() );
  }
}
