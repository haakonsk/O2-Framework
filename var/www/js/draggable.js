/* A little object oriented, so we don't need to use global variables */
o2.draggable = {

  initialStyleLeft : null,
  initialStyleTop  : null,
  initialMouseX    : null,
  initialMouseY    : null,

  instances       : new Array(), // Got to support multiple draggable elements at the same time (although it's just possible to drag one at a time).
  currentInstance : null,

  setupDragDrop : function(params) {
    var initDragElement = params.initDragElement || params.draggedElement;
    if (!initDragElement.id) {
      initDragElement.id = "initDragElm_" + parseInt( 1000000*Math.random() );
    }
    o2EventHandler.addEventListenerById( "mousedown", initDragElement.id, o2.draggable.startDrag );
    o2EventHandler.addEventListenerById( "mouseup",   initDragElement.id, o2.draggable.endDrag   );
    o2.draggable.instances[ initDragElement.id ] = {
      "initDragElement"       : initDragElement,
      "draggedElement"        : params.draggedElement || initDragElement,
      "disableVerticalDrag"   : params.disableVerticalDrag,
      "disableHorizontalDrag" : params.disableHorizontalDrag,
      "dragEndCallback"       : params.dragEndCallback
    };
  },

  startDrag : function(e) {
    // Create a div that covers the entire screen
    // handleDrag when the user moves the mouse in this div
    var div = document.getElementById("draggableDiv");
    if (div) {
      div.style.display = "";
    }
    else {
      div = document.createElement("div");
      div.id = "draggableDiv";
      div.style.position = "absolute";
      div.style.left     = 0;
      div.style.width    =  window.innerWidth;
      div.style.top      = 0;
      div.style.height   =  window.innerHeight;
      div.style.opacity  = 0.5;
      div.style.zIndex   = 100;

      document.body.appendChild(div);
    }
    o2.addEvent( div, "mousemove", o2.draggable.handleDrag );
    o2.addEvent( div, "mouseup",   o2.draggable.endDrag    );
    o2.draggable.initialMouseX = parseInt( e.getX() );
    o2.draggable.initialMouseY = parseInt( e.getY() );
    var instance = o2.draggable.currentInstance = o2.draggable.getInstance(e);
    o2.draggable.initialStyleLeft = parseInt( instance.draggedElement.offsetLeft );
    o2.draggable.initialStyleTop  = parseInt( instance.draggedElement.offsetTop  );
    return false;
  },

  handleDrag : function(e) {
    var instance = o2.draggable.currentInstance;
    if (!instance) {
      return;
    }
    var deltaX = parseInt( e.getX() )  -  o2.draggable.initialMouseX;
    var deltaY = parseInt( e.getY() )  -  o2.draggable.initialMouseY;
    if (!instance.disableHorizontalDrag) {
      instance.draggedElement.style.left = (o2.draggable.initialStyleLeft + deltaX) + "px";
    }
    if (!instance.disableVerticalDrag) {
      instance.draggedElement.style.top  = (o2.draggable.initialStyleTop  + deltaY) + "px";
    }
    e.preventDefault();
    return false; // Don't select any text
  },

  endDrag : function(e) {
    var instance = o2.draggable.currentInstance;
    if (!instance) {
      return;
    }
    var div = document.getElementById("draggableDiv");
    
    o2.removeEvent( div, "mousemove", o2.draggable.handleDrag );
    o2.removeEvent( div, "mouseup",   o2.draggable.endDrag    );
    div.style.display = "none";
    
    if (instance.dragEndCallback) {
      try {
        instance.dragEndCallback.call(this,e,instance);
      }
      catch (error) {
        if (window.console) {
          console.error( "Error performing callback on:", instance, " js error:" + o2.getExceptionMessage(error) );
        }
      }
    }
  },
  
  getInstance : function(e) {
    var elm = e.getTarget();
    while (elm) {
      var instance = o2.draggable.instances[ elm.id ];
      if (instance) {
        return instance;
      }
      elm = elm.parentNode;
    }
  }

};
