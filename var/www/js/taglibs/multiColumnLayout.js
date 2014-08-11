o2.require("/js/windowUtil.js");
o2.require("/js/DOMUtil.js");

o2.multiColumnLayout = {};

o2.multiColumnLayout.adjustAllColumnWidths = function(e, isLastTime) {
  var colSets = o2.getElementsByClassName("multiColumnLayout");
  for (var i = 0; i < colSets.length; i++) {
    o2.multiColumnLayout.adjustColumnWidths( colSets[i].id );
  }

  // Calling this method twice in case the width of the body wasn't exactly right the first time, due to vertical scrollbar appearing or disappearing.
  if (!isLastTime) {
    o2.multiColumnLayout.adjustAllColumnWidths(e, true);
  }
}

o2.multiColumnLayout.adjustColumnWidths = function(id) {
  var colSet     = document.getElementById(id);
  var totalWidth = colSet.getAttribute("width");
  var widths     = colSet.getAttribute("widths").split(",");
  var columns    = o2.getElementsByClassName("multiColumn", colSet, "div");

  // To be able to set the widths and heights correctly, they must be displayed:
  var displayNoneElements = new Array();
  var elm = colSet;
  while (elm) {
    if (elm.style && elm.style.display === "none") {
      elm.style.display = "";
      displayNoneElements.push(elm);
    }
    elm = elm.parentNode;
  }
  
  // Find the width in pixels that the relative width columns should occupy. Available width is width of window minus width of borders, padding, margin and widths of columns with width in pixels...
  var parent = colSet.parentNode === document.body ? document.body : colSet.parentNode;
  var availableWidth = parseInt( parent === document.body ? parent.clientWidth : o2.getComputedStyle(parent, "width") );
  if (totalWidth) {
    availableWidth
      = totalWidth.match(/^\d+(\s*px)?$/) ? parseInt(totalWidth)
      : totalWidth.match(/^\d+%$/)        ? availableWidth * parseInt(totalWidth) / 100
      :                                     availableWidth
      ;
  }
  else {
    availableWidth = availableWidth  -  o2.multiColumnLayout.getSize( colSet, "borderLeftWidth" )  -  o2.multiColumnLayout.getSize( colSet, "borderRightWidth" );
    availableWidth = availableWidth  -  o2.multiColumnLayout.getSize( colSet, "paddingLeft"     )  -  o2.multiColumnLayout.getSize( colSet, "paddingRight"     );
    availableWidth = availableWidth  -  o2.multiColumnLayout.getSize( colSet, "marginLeft"      )  -  o2.multiColumnLayout.getSize( colSet, "marginRight"      );
  }
  availableWidth = availableWidth  -  o2.multiColumnLayout.getSize( parent, "borderLeftWidth" )  - o2.multiColumnLayout.getSize( parent, "borderRightWidth" );
  availableWidth = availableWidth  -  o2.multiColumnLayout.getSize( parent, "paddingLeft"     )  - o2.multiColumnLayout.getSize( parent, "paddingRight"     );
  availableWidth = availableWidth  -  o2.multiColumnLayout.getSize( parent, "marginLeft"      )  - o2.multiColumnLayout.getSize( parent, "marginRight"      );
  for (var i = 0; i < columns.length; i++) {
    var column = columns[i];
    availableWidth  =  availableWidth  -  o2.multiColumnLayout.getSize( column, "borderLeftWidth" )  -  o2.multiColumnLayout.getSize( column, "borderRightWidth" );
    availableWidth  =  availableWidth  -  o2.multiColumnLayout.getSize( column, "paddingLeft"     )  -  o2.multiColumnLayout.getSize( column, "paddingRight"     );
    availableWidth  =  availableWidth  -  o2.multiColumnLayout.getSize( column, "marginLeft"      )  -  o2.multiColumnLayout.getSize( column, "marginRight"      );
  }
  var numColumnsInPercent = 0;
  for (var i = 0; i < widths.length; i++) {
    var width = widths[i];
    if (width.match(/px$/i)) {
      availableWidth -= parseInt(width);
    }
  }

  // Translate relative widths into pixels. Make sure we use exactly 100% of the available width (if some columns have width=auto).
  var usedAvailableWidth = 0;
  for (var i = 0; i < widths.length; i++) {
    if (widths[i].match(/%$/)) {
      var width = widths[i].replace(/^(.+)%$/, "$1");
      widths[i] = Math.floor(availableWidth * width / 100)  +  "px";
      usedAvailableWidth += parseInt( widths[i] );
    }
  }

  // Apply widths to the columns, and find height of highest column
  var maxColumnHeight = 0;
  for (var i = 0; i < columns.length; i++) {
    var column = columns[i];
    column.style.width  = widths[i];
    column.style.height = "auto"; // If we don't do this, the calculated height will be what we set it to be last time
    var height =  parseInt( o2.getComputedStyle(column, "height") );
    if (height > maxColumnHeight) {
      maxColumnHeight = height;
    }
  }

  // Reset to display=none those elements that originally had display=none
  for (var i = 0; i < displayNoneElements.length; i++) {
    displayNoneElements[i].style.display = "none";
  }

  // Set height of columns to height of highest column
  for (var i = 0; i < columns.length; i++) {
    columns[i].style.height = (maxColumnHeight - o2.multiColumnLayout.getSize(column, "paddingTop") - o2.multiColumnLayout.getSize(column, "paddingBottom")) + "px";
  }
}

o2.multiColumnLayout.getSize = function(elm, styleAttribute) {
  var size = o2.getComputedStyle(elm, styleAttribute);
  return size.match(/^\d/) ? parseInt(size) : 0;
}

o2.addEvent(window, "resize", o2.multiColumnLayout.adjustAllColumnWidths);
