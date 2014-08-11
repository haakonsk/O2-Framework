/*
  Utility functions for the general element handling and the Document Object Model
*/

o2.require("/js/util.js");

o2.getComputedStyle = function(elm, attr) {
  if (attr === "width") {
    if (typeof(elm.offsetWidth) !== "undefined") {
      return elm.offsetWidth;
    }
  }
  else if (attr === "height") {
    if (typeof(elm.offsetHeight) !== "undefined") {
      return elm.offsetHeight;
    }
  }
  else if (attr === "left" || attr === "top") {
    if (elm.offsetParent) {
      var x = 0, y = 0;
      var tmpElm = elm;
      while (tmpElm.offsetParent) {
        x += tmpElm.offsetLeft;
        y += tmpElm.offsetTop;
        tmpElm = tmpElm.offsetParent;
      }
      return attr === "left" ? x : y;
    }
  }
  else if (attr === "bottom") {
    return o2.getComputedStyle(elm, "top") + o2.getComputedStyle(elm, "height");
  }
  else if (attr === "right") {
    return o2.getComputedStyle(elm, "left") + o2.getComputedStyle(elm, "width");
  }
  if (window.getComputedStyle) {
    return window.getComputedStyle(elm, null)[attr];
  }
  if (elm.currentStyle) {
    return elm.currentStyle[attr];
  }
  alert("Couldn't get computed style for " + attr);
}

/* Equivalent to the DOM method insertBefore */
o2.insertAfter = function(newElement, targetElement) {
  if (!targetElement) {
    return alert("insertAfter: No target element given");
  }
  var parent = targetElement.parentNode;
  if (parent.lastChild == targetElement) {
    parent.appendChild(newElement);
  }
  else {
    parent.insertBefore(newElement, targetElement.nextSibling);
  }
}

/* Searches siblings to the right for the first node of type element (nodeType == 1) - and returns it */
o2.getNextElement = function(node, textNodeIsOkToo) {
  if (!node.nextSibling) {
    return false;
  }
  node = node.nextSibling;
  if (node.nodeType == 1  ||  (textNodeIsOkToo && node.nodeType == 3)) {
    return node;
  }
  return o2.getNextElement(node);
}

/* Searches siblings to the left for the first node of type element (nodeType == 1) - and returns it */
o2.getPreviousElement = function(node, textNodeIsOkToo) {
  if (!node.previousSibling) {
    return false;
  }
  node = node.previousSibling;
  if (node.nodeType == 1  ||  (textNodeIsOkToo && node.nodeType == 3)) {
    return node;
  }
  return o2.getPreviousElement(node);
}

/* canBeSelf == doesn't have to be ancestor
   tagNames can also be just one tagName as a string */
o2.getClosestAncestorByTagName = function(elm, tagNames, canBeSelf) {
  if (typeof(tagNames)  === "string") {
    tagNames = [ tagNames ];
  }
  if (typeof(canBeSelf) === "undefined") {
    canBeSelf = true; // Default is true
  }
  if (canBeSelf  &&  o2.isInArray(elm.tagName, tagNames, true)) {
    return elm;
  }
  while (elm.parentNode) {
    elm = elm.parentNode;
    if (!elm || !elm.tagName) {
      return null;
    }
    if (o2.isInArray(elm.tagName, tagNames, true)) {
      return elm;
    }
  }
  return null;
}

// Similar to getClosestAncestorByTagName
o2.getClosestAncestorByClassName = function(elm, className, canBeSelf) {
  if (typeof(canBeSelf) === "undefined") {
    canBeSelf = true; // Default is true
  }
  if (canBeSelf  &&  o2.hasClassName(elm, className)) {
    return elm;
  }
  while (elm.parentNode) {
    elm = elm.parentNode;
    if (o2.hasClassName(elm, className)) {
      return elm;
    }
  }
  return null;
}

o2.swapElements = function(elm1, elm2) {
  if (!elm1 || !elm2) {
    return;
  }

  var parent  = elm1.parentNode;

  // Make sure the elements are in the expected order..
  for (var i = 0; i < parent.childNodes.length; i++) {
    var elm = parent.childNodes[i];
    if (elm === elm1) {
      elm1 = elm2;
      elm2 = elm;
      break;
    }
    if (elm === elm2) {
      break;
    }
  }

  var removed = parent.removeChild(elm1);
  parent.insertBefore(elm1, elm2);
}

o2.swapContentElements = function(elm1, elm2) {
  var numChildrenInElm1 = elm1.childNodes.length;
  var numChildrenInElm2 = elm2.childNodes.length;
  
  // Move all elements inside elm1 to elm2
  for (var i = 0; i < numChildrenInElm1; i++) {
    elm2.appendChild( elm1.childNodes[0] );
  }
  
  // Move all original elements inside elm2 to elm1
  for (var i = 0; i < numChildrenInElm2; i++) {
    elm1.appendChild( elm2.childNodes[0] );
  }
}
