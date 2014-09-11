o2.multiInput = {};

o2.require("/js/DOMUtil.js");

// Form.pm also makes available a variable called multiInputValues, which is a hash
// where the key is the name of the input field and the value is the default values
// of the input fields in that multiInput group. So we must make sure to create at least
// as many lines in the multiInput group as the number of values here.

o2.multiInput.setupAll = function() {
  var multiInputs = o2.getElementsByClassName("multiInput", document);
  for (var i = 0; i < multiInputs.length; i++) {
    o2.multiInput.setup( multiInputs[i] );
  }
}

o2.multiInput.setup = function(multiInput) {
  var rows        = o2.getElementsByClassName("multiInputRow", multiInput);
  var minNumLines = multiInput.getAttribute("minNumLines");
  var inputElements = o2.multiInput.getInputElementsIn( rows[0] );
  for (var j = 0; j < inputElements.length; j++) {
    var name = inputElements[j].name;
    if (window.multiInputValues && multiInputValues[name] && multiInputValues[name].length > minNumLines) {
      minNumLines = multiInputValues[name].length;
    }
  }
  for (var j = 0; j < minNumLines; j++) {
    var row;
    if (j >= rows.length) {
      row = o2.multiInput.addRow(multiInput);
    }
    else {
      row = rows[j];
    }
    var rowInputElements = o2.multiInput.getInputElementsIn(row);
    for (k = 0; k < rowInputElements.length; k++) {
      var elm = rowInputElements[k];
      if (window.multiInputValues) {
        var values = multiInputValues[ elm.name ];
        if (values && typeof( values[j] ) !== "undefined") {
          elm.value = values[j];
        }
      }
    }
  }
  if (multiInput.getAttribute("resizable") === "0") {
    var addBtn = o2.getElementsByClassName("addBtn", multiInput)[0];
    o2.addClassName(addBtn, "btnAddHidden");
  }
  o2.multiInput.fixControls(multiInput);
}

o2.multiInput.deleteRow = function(row) {
  var multiInput = o2.getClosestAncestorByClassName(row, "multiInput");
  row.parentNode.removeChild(row);
  o2.multiInput.fixControls(multiInput);
  if (multiInput.getAttribute("onDeleteRow")) {
    eval( multiInput.getAttribute("onDeleteRow") );
  }
}

o2.multiInput.addRow = function(multiInput) {
  var row = o2.getElementsByClassName("multiInputRow", multiInput)[0];
  var newRow = row.cloneNode(true);
  var inputElements = o2.multiInput.getInputElementsIn(newRow);
  for (var i = 0; i < inputElements.length; i++) {
    var inputElement = inputElements[i]
    inputElement.value = ""; // Clear input field
    if (inputElement.id) {
      inputElement.removeAttribute("id"); // Remove id attribute if present
    }
  }
  row.parentNode.appendChild(newRow);
  o2.multiInput.fixControls(multiInput);
  if (multiInput.getAttribute("newRowHandler")) {
    eval( multiInput.getAttribute("newRowHandler") + ".call(this, newRow, multiInput)" );
  }
  return newRow;
}

// elm1 originally comes before elm2. Then elm2 is moved before elm1.
o2.multiInput.switchElements = function(elm1, elm2) {
  if (!elm1 || !elm2) {
    return;
  }
  var parent  = elm1.parentNode;
  var removed = parent.removeChild(elm1);
  parent.insertBefore(elm1, elm2);
}

o2.multiInput.moveUp = function(row) {
  o2.multiInput.switchElements( row, o2.multiInput.getPreviousSibling(row) );
  o2.multiInput.fixControls( o2.getClosestAncestorByClassName(row, "multiInput") );
}

o2.multiInput.moveDown = function(row) {
  o2.multiInput.switchElements( o2.multiInput.getNextSibling(row), row );
  o2.multiInput.fixControls( o2.getClosestAncestorByClassName(row, "multiInput") );
}

o2.multiInput.getSibling = function(elm, which) { // which can be "next" or "previous"
  while (elm) {
    var sibling = which === "next" ? elm.nextSibling : elm.previousSibling;
    if (!sibling) {
      return null;
    }
    if (sibling.nodeName == "TR" || sibling.nodeName == "DIV") {
      return sibling;
    }
    else if (sibling.nodeType == 3) {
      elm = sibling;
    }
    else {
      return null;
    }
  }
  alert("Didn't find " + which + " sibling");
}

o2.multiInput.getNextSibling = function(elm) {
  return o2.multiInput.getSibling(elm, "next");
}

o2.multiInput.getPreviousSibling = function(elm) {
  return o2.multiInput.getSibling(elm, "previous");
}

o2.multiInput.fixControls = function(multiInput) {
  var controls = o2.getElementsByClassName("controls", multiInput);
  var numRows = controls.length;
  for (var i = 0; i < numRows; i++) {
    if (i > 0 && multiInput.getAttribute("rearrangeable") === "1") {
      o2.multiInput.showUpBtn( controls[i] );
    }
    else {
      o2.multiInput.hideUpBtn( controls[i] );
    }
    if (numRows <= multiInput.getAttribute("minNumLines") || multiInput.getAttribute("resizable") === "0") {
      o2.multiInput.hideDeleteBtn( controls[i] );
    }
    else {
      o2.multiInput.showDeleteBtn( controls[i] );
    }
    if (i == numRows-1 || multiInput.getAttribute("rearrangeable") === "0") {
      o2.multiInput.hideDownBtn( controls[i] );
    }
    else {
      o2.multiInput.showDownBtn( controls[i] );
    }
  }
}

o2.multiInput.hideUpBtn = function(controls) {
  var upBtn = o2.getElementsByClassName("upBtn", controls)[0];
  o2.addClassName(upBtn, "btnUpHidden");
}

o2.multiInput.hideDownBtn = function(controls) {
  var downBtn = o2.getElementsByClassName("downBtn", controls)[0];
  o2.addClassName(downBtn, "btnDownHidden");
}

o2.multiInput.hideDeleteBtn = function(controls) {
  var deleteBtn = o2.getElementsByClassName("deleteBtn", controls)[0];
  o2.addClassName(deleteBtn, "btnDeleteHidden");
}

o2.multiInput.showUpBtn = function(controls) {
  var upBtn = o2.getElementsByClassName("upBtn", controls)[0];
  o2.removeClassName(upBtn, "btnUpHidden");
}

o2.multiInput.showDownBtn = function(controls) {
  var downBtn = o2.getElementsByClassName("downBtn", controls)[0];
  o2.removeClassName(downBtn, "btnDownHidden");
}

o2.multiInput.showDeleteBtn = function(controls) {
  var deleteBtn = o2.getElementsByClassName("deleteBtn", controls)[0];
  o2.removeClassName(deleteBtn, "btnDeleteHidden");
}

o2.multiInput.getInputElementsIn = function(elm) {
  var inputElements = new Array();
  for (var i = 0; i < elm.childNodes.length; i++) {
    var subElm = elm.childNodes[i];
    var tagName = subElm.nodeName.toLowerCase();
    if (tagName === "input" || tagName === "select" || tagName === "textarea") {
      inputElements.push(subElm);
    }
    else if (subElm.childNodes.length > 0) {
      var subSubElms = o2.multiInput.getInputElementsIn(subElm);
      for (var j = 0; j < subSubElms.length; j++) {
        inputElements.push( subSubElms[j] );
      }
    }
  }
  return inputElements;
}

o2.addLoadEvent(o2.multiInput.setupAll);
