o2.printPage = function() {
  if (window.print) {
    window.print();
    return true;
  }
  // alert("Sorry, your browser doesn't support this feature.");
  return false;
}


o2.getWindowWidth = function(windowRef) {
  var width = 0;
  if (!windowRef) {
    windowRef = window;
  }
  if (typeof(windowRef.innerWidth) == 'number') {
    width = windowRef.innerWidth;
  }
  else if (windowRef.document.body && typeof(windowRef.document.body.clientWidth) == 'number') {
    width = windowRef.document.body.clientWidth;  
  }
  return width;
}

o2.getWindowHeight = function(windowRef) {
  var height = 0;
  if (!windowRef) {
    windowRef = window;
  }
  if (typeof(windowRef.innerWidth) == 'number') {
    height = windowRef.innerHeight;
  }
  else if (windowRef.document.body && typeof(windowRef.document.body.clientWidth) == 'number') {
    height = windowRef.document.body.clientHeight;    
  }
  return height;
}

o2.isInArray = function(item, array, ignoreCase) {
  if (ignoreCase) {
    item = item.toLowerCase();
  }
  for (var i = 0; i < array.length; i++) {
    var tmpItem = ignoreCase ? array[i].toLowerCase() : array[i];
    if (item === tmpItem) {
      return true;
    }
  }
  return false;
}
