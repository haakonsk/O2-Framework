// Description: Cross browser event object for O2

function O2Event(obj, evt) {
  if (evt && evt.evt) { // evt is an O2Event already
    return evt;
  }
  
  if (!evt) {
    if (!obj) {
      alert("O2Event: no obj given");
      return;
    }
    evt = obj.event || window.event;
  }
  
  this.evt = evt;
  
  return this;
}

// returns the clicked button id on the mouse
O2Event.prototype.getButton = function() {
  var buttonId;
  if (this.evt.which) {
    buttonId = this.evt.which - 1;
    // See "Mouse button ID values in various browser" table at http://unixpapa.com/js/mouse.html
  }
  else if (this.evt.button) {
    switch (this.evt.button) {
      case 1:  buttonId = 0; break; // Left   mouse button
      case 2:  buttonId = 2; break; // Right  mouse button
      case 4:  buttonId = 1; break; // Middle mouse button
      default: buttonId = null;
    }
  }
  return buttonId;
}

O2Event.prototype.getKeyCode = function() {
  return this.evt.which || this.evt.keyCode;
}

O2Event.prototype.getType = function() { 
  return this.evt.type;
}

O2Event.prototype.getTarget = function() {
  var t = this.evt.target || this.evt.srcElement || "";
  
  if (t.nodeType == 3) { // defeat Safari bug, ref: http://www.quirksmode.org/js/events_properties.html
    t = t.parentNode;
  }
  return t;
}

// Returns the x position where the event occurred relative to the left visible edge of the current frame/window
O2Event.prototype.getX = function() {
  return this.evt.clientX;
}

// Returns the y position where the event occurred relative to the visible top of the current frame/window
O2Event.prototype.getY = function() {
  return this.evt.clientY;
}

O2Event.prototype.preventDefault = function() {
  if (this.evt.preventDefault) {
    this.evt.preventDefault();
  }
  else {
    this.evt.returnValue = false;
  }
}

O2Event.prototype.stopPropagation = function() {
  if (this.evt.stopPropagation) {
    this.evt.stopPropagation();
  }
  else {
    this.evt.cancelBubble = true;
  }
}

// Returns the x position where the event occurred relative to the "physical" edge of the current window (getX + scrollWidth)
O2Event.prototype.getLayerX = function() {
  return this.evt.layerX || this.evt.offsetX;
}

// Returns the y position where the event occurred relative to the "physical" top of the current window (getY + scrollHeight)
O2Event.prototype.getLayerY = function() {
  return this.evt.layerY || this.evt.offsetY;
}

O2Event.prototype.getRelatedTarget = function() {
  return this.evt.relatedTarget || this.evt.toElement || this.evt.fromElement;
}

/* Returns the window where the event occurred */
O2Event.prototype.getWindow = function() {
  var doc = this.getDocument();
  var win = doc.defaultView || doc.parentWindow;
  if (!win) {
    return alert("Browser doesn't support defaultView or parentWindow");
  }
  return win;
}

/* Returns the document where the event occurred */
O2Event.prototype.getDocument = function() {
  var target = this.getTarget();
  return target.ownerDocument || target;
}
