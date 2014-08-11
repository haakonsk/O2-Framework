o2.require("/js/util/string.js"); // Need to have the "split" function available
o2.require("/js/O2Event.js");
o2.require("/js/O2Exception.js");

o2.addLoadEvent = function(functionRef) {
  o2.addEvent(window, 'load', functionRef);
}

/* Appends a className to the class-attribute of an element */
o2.addClassName = function(elm, className) {
  if (elm == null || o2.hasClassName(elm, className)) {
    return;
  }
  if (!elm.className) {
    elm.className = className;
  }
  else {
    var newClassName = elm.className;
    newClassName    += " ";
    newClassName    += className;
    elm.className = newClassName;
  }
}

/* Removes a className from the class-attribute of an element */
o2.removeClassName = function(elm, className) {
  if (!elm) {
    return alert("hasClassName: No element specified");
  }
  if (!elm.className) {
    return false;
  }
  var newClassName = "";
  var classNames = o2.split(/ /, elm.className);
  for (var i = 0; i < classNames.length; i++) {
    if (classNames[i] != className) {
      newClassName += classNames[i] + " ";
    }
  }
  if (className) {
    newClassName = newClassName.substring( 0, newClassName.length-1 );
  }
  elm.className = newClassName;
}

/* Checks if an element has the given class */
o2.hasClassName = function(elm, className) {
  if (!elm) {
    return alert("hasClassName: No element specified");
  }
  if (!elm.className) {
    return false;
  }
  var classNames = o2.split(/ /, elm.className);
  for (var i = 0; i < classNames.length; i++) {
    if (classNames[i] == className) {
      return true;
    }
  }
  return false;
}

/* Goes through an object and returns the elements with the specified
   class name and, if present, tag name.

   Caveats: if you want to use another tag than '*', you
   have to specify the element (0 or document works).

   Based on, but simplyfied: 
   
   http://muffinresearch.co.uk/archives/2006/04/29/getelementsbyclassname-deluxe-edition/
*/
o2.getElementsByClassName = function(className, elm, tag) {
  if (!className) {
    o2Debug.warn("getElementsByClassName called without className parameter");
    return new Array();
  }
  elm = elm || document;
  tag = tag || "*";

  var tagList = elm.getElementsByTagName(tag);
  var elements = new Array();

  // Speed.
  var tLl = tagList.length;
  for (var i = 0; i < tLl; i++) {
    var classNames = o2.split(/ /, tagList[i].className);
    for (var j = 0; j < classNames.length; j++) {
      if (classNames[j] == className) {
        elements.push(tagList[i]);
      }
    }
  }
  return elements;
}

// Checks if a given variable is of the given type
// Based on the function "is" from http://bonsaiden.github.com/JavaScript-Garden/#types
// Possible types: Arguments, Array, Boolean, Date, Error, Function, JSON, Math, Number, Object, RegExp, String
o2.isOfType = function(object, type) {
  var className = Object.prototype.toString.call(object).slice(8, -1);
  return object !== undefined && object !== null && className === type;
}

/* Event handler stuff. Experimental */
function O2EventHandler() {
  this.listeners            = new Array();
  this.registeredEventTypes = new Array();
}

O2EventHandler.prototype.addEventListenerById = function(eventType, id, functionObject) {
  var elm = document.getElementById(id);
  if (!elm) {
    return alert("addEventListenerById: No element with id '" + id + "'");
  }
  o2.addEvent(elm, eventType, functionObject);
}

O2EventHandler.prototype.addEventListenerByClass = function(eventType, className, functionObject) {
  var elements = o2.getElementsByClassName(className);
  for (var i = 0; i < elements.length; i++) {
    o2.addEvent(elements[i], eventType, functionObject);
  }
}

O2EventHandler.prototype.addEventListener = function(params) {
  if (!params["eventType"] || !params["functionObject"]) {
    alert("addEventListener: Missing eventType or functionObject attribute");
    return;
  }
  if (params.id) {
    o2.addEvent( document.getElementById(params.id), params.eventType, params.functionObject );
  }
  else if (params.className) {
    var elements = o2.getElementsByClassName( params.className, params.element, params.tagName );
    for (var i = 0; i < elements.length; i++) {
      o2.addEvent( elements[i], params.eventType, params.functionObject );
    }
  }
  else {
    alert("addEventListener: Either id or className must be supplied");
  }
}

var o2EventHandler = new O2EventHandler();


/* Using the traditional event model. The event object sent to the function is a cross-browser event (see O2Event.js) */
o2.addEvent = function(obj, type, fn, currentThis) {
  if (!o2._addEvent(obj, type, fn, currentThis)) {
    return false;
  }
  
  if (!obj.registeredEvents) {
    obj.registeredEvents = new Array();
  }
  if (!obj.registeredEvents[type]) {
    obj.registeredEvents[type] = new Array();
  }
  obj.registeredEvents[type].push({
    "code"           : fn.toString(),
    "functionObject" : fn,
    "currentThis"    : currentThis
  });
  return true;
}

/* Only adds the event if it's not added already */
o2.replaceEvent = function(obj, type, fn, currentThis) {
  if (!obj.registeredEvents || !obj.registeredEvents[type]) {
    return o2.addEvent(obj, type, fn, currentThis);
  }
  for (var i = 0; i < obj.registeredEvents[type].length; i++) {
    var func = obj.registeredEvents[type][i];
    if (func.code === fn.toString()) {
      return;
    }
  }
  o2.addEvent(obj, type, fn, currentThis);
}

o2.removeEvent = function(obj, type, fn) {
  if (!obj || !obj.registeredEvents || !obj.registeredEvents[type]) {
    return false;
  }
  var functions = new Array();
  for (var i = 0; i < obj.registeredEvents[type].length; i++) {
    var func = obj.registeredEvents[type][i];
    if (func.code !== fn.toString()) {
      functions.push(func);
    }
  }
  obj.registeredEvents[type] = null;
  obj["on"+type] = null;
  for (var i = 0; i < functions.length; i++) {
    o2.addEvent(obj, type, functions[i].functionObject, functions[i].currentThis);
  }
}

o2._addEvent = function(obj, type, fn, currentThis) {
  currentThis = currentThis || this;
  var doc = null;
  
  try { 
    doc = obj.ownerDocument || obj.document || obj;
  }
  catch (error) {
    if (window.console) {
      console.warn( o2.getExceptionMessage(error) );
    }
    return false;
  }
  var win = doc.defaultView || doc.parentWindow;
  var oldFn = obj["on"+type];
  obj["on"+type] = function(e) {
    e = e || win.event;
    e = new O2Event(null, e);
    if (oldFn) {
      oldFn.call(this, e, obj);
    }
    return fn.call(currentThis, e, obj);
  }
  return true;
}
