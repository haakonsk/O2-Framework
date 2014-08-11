o2.range = {};

o2.range.getRangeBySelection = function(selectionObject) {
  if (selectionObject.getRangeAt) {
    try {
      return selectionObject.getRangeAt(0);
    }
    catch (e) {
      return null;
    }
  }
  if (typeof selectionObject.typeDetail !== "undefined") { // IE
    return selectionObject.createRange();
  }
  // Safari
  var range = document.createRange();
  range.setStart( selectionObject.anchorNode, selectionObject.anchorOffset );
  range.setEnd(   selectionObject.focusNode,  selectionObject.focusOffset  );
  return range;
}

o2.range.createRange = function(node, startPosition, endPosition) {
  var range;
  if (document.createRange) {
    range = document.createRange();
  }
  else if (document.selection && document.selection.createRange) {
    range = document.selection.createRange();
  }
  else {
    return alert("Coulnd't create range");
  }
  if (node.setSelectionRange) { // Input fields, Firefox ++
    node.setSelectionRange(startPosition, endPosition);
  }
  else if (node.createTextRange) { // Input fields, IE
    range = node.createTextRange();
    range.collapse(true);
    range.moveStart( "character", startPosition               );
    range.moveEnd(   "character", endPosition - startPosition );
    node.focus();
  }
  else if (node.nodeType !== 4  &&  node.nodeType !== 8) { // Not text, cdata or comment
    // Create a new node inside <node>, the new node's content is the text to be selected
    var id = "tmp" + parseInt( 1000000 * Math.random() );
    node.innerHTML = node.innerHTML.substring(0, startPosition) + "<span id='" + id + "'>" + node.innerHTML.substring(startPosition, endPosition) + "</span>" + node.innerHTML.substring(endPosition);

    // Select the node
    var newNode = document.getElementById(id);
    if (range.selectNode) {
      range.selectNode(newNode);
    }
    else {
      range.moveToElementText(newNode);
    }
  }
  else {
    return alert("node is text, cdata or comment.. Not implemented..");
  }
  return range;
}
