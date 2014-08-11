// Add support for the DISABLED option in select elements in IE7 and IE6                                              

var __docSelects = null;
var __InitSelectLoaded = false;

o2.selectDisabledFix = {};

o2.selectDisabledFix.initSelects = function(f) {
  if (__InitSelectLoaded) {
    return;
  }
  __InitSelectLoaded = true;
  
  if (document.getElementsByTagName) {
    var s = document.getElementsByTagName("select");
    for (var i = 0; i < s.length; i++) {
      o2.selectDisabledFix.initSelect( s[i] );
    }
  }
}

o2.selectDisabledFix.initSelect = function(select) {
  if (__docSelects == null) {
    __docSelects = new Array();
  }
  if (__docSelects[select.name] == null) {
    __docSelects[select.name]= new Array();
  }
  
  for (var i = 0; i < select.options.length; i++) {
    if (select.options[i].getAttribute("disabled") || select.options[i].disabled) {
      select.options[i].style.color = "#808080";
    }
    
    if (select.options[i].selected && !(select.options[i].getAttribute("disabled") || select.options[i].disabled)) {
      if (select.type == "select-multiple") {
        if (__docSelects[select.name]["options"] == null) {
          __docSelects[select.name]["options"] = new Array();
        }
        __docSelects[select.name]["options"].push(i);
      }
      else {
        __docSelects[select.name]["options"] = i;
      }
    }
  }
  
  if (select.onchange     != null) { __docSelects[select.name]["onChange"]    = o2.selectDisabledFix.getMethodContent(select.onchange);     }
  if (select.onfocus      != null) { __docSelects[select.name]["onFocus"]     = o2.selectDisabledFix.getMethodContent(select.onfocus);      }
  if (select.onmouseenter != null) { __docSelects[select.name]["onMouseover"] = o2.selectDisabledFix.getMethodContent(select.onmouseenter); }
  
  select.onchange     = function() { o2.selectDisabledFix.handleDisabled(this)               };
  select.onfocus      = function() { o2.selectDisabledFix.updateOptions(this,"onfocus")      };
  select.onmouseenter = function() { o2.selectDisabledFix.updateOptions(this,"onmouseenter") };
}

o2.selectDisabledFix.execEvent = function(select, event) {
  if (select.name == null || select.name == "") {
    return;
  }
  if (__docSelects[select.name][event] == null) {
    return;
  }
  
  try {
    var method = __docSelects[select.name][event];
    method     = method.replace(/this/g, 'select.form["' + select.name + '"]');
    eval(method);
  }
  catch (e) {
    alert("Could not execute event (" + event + "): \n" + method + "\nReason:" + o2.getExceptionMessage(e));
  }
}

o2.selectDisabledFix.getMethodContent = function(method) {
  var eventStr = "" + method;
  var startIdx = eventStr.indexOf("{");
  var endIdx   = eventStr.lastIndexOf("}");
  return ( eventStr.substring(startIdx+1, endIdx) );
}

o2.selectDisabledFix.updateOptions = function(select, event) {
  for (var i = 0; i < select.options.length; i++) {
    // We need to check whetever some elements have been disabled or not...
    if (select.options[i].getAttribute("disabled") || select.options[i].disabled) {
      select.options[i].style.color = "#808080";
      
      if (select.options[i].selected) {
        select.options[i].selected = false;
        o2.selectDisabledFix.createSnapshot(select);
      }
    }
    else {
      select.options[i].style.color = ""; // hm, should memorize old color name maybe?
    }
  }
  if (event != null) {
    o2.selectDisabledFix.execEvent(select, event);
  }
}

o2.selectDisabledFix.restoreSnapshot = function(select) {
  for (var i = 0; i < __docSelects[select.name]["options"].length; i++) {
    select.options[ __docSelects[select.name]["options"][i] ].selected = true;
  }
}

o2.selectDisabledFix.createSnapshot = function(select) {
  if (select.type == "select-multiple") {
    var snapshot = new Array();
    for (var i = 0; i < select.options.length; i++) {
      if (select.options[i].selected && !(select.options[i].getAttribute("disabled") || select.options[i].disabled)) {
        snapshot.push(i);
      }
    }
    __docSelects[select.name]["options"] = snapshot;
  }
  else{
    __docSelects[select.name]["options"] = select.options.selectedIndex;
  }
}

o2.selectDisabledFix.handleDisabled = function(select) {
  if (select.type == "select-multiple") {
    // has a disabled select selected? then restore to old snapshot
    var snapshot = new Array();
    var noDisabled = true;
    for (var i = 0; i < select.options.length; i++) {
      if (select.options[i].selected && (select.options[i].getAttribute("disabled") || select.options[i].disabled)) {
        //abort, restore last snapshot
        o2.selectDisabledFix.restoreSnapshot(select);
        select.options[i].selected = false;
        noDisabled = false;
        break;
      }
      else if (select.options[i].selected) {
        snapshot.push(i);
      }
    }
    //ok, lets update to a new snapshot
    if (noDisabled) { 
      __docSelects[select.name]["options"] = snapshot; 
      o2.selectDisabledFix.execEvent(select, "onChange");
    }
  }
  else {
    var selIdx = select.options.selectedIndex;
    if (select.options[selIdx].getAttribute("disabled") && select.options[selIdx].disabled) {
      select.options.selectedIndex=__docSelects[select.name]["options"];
    }
    else {
      __docSelects[select.name]["options"] = select.options.selectedIndex;
      o2.selectDisabledFix.execEvent(select, "onChange");
    }
  }
  o2.selectDisabledFix.updateOptions(select);
}

if (document.onreadystatechange == null) {
  document.onreadystatechange = function() {
    o2.selectDisabledFix.initSelects();
  };
}
else if (window.onload == null) {
  window.onload = function() {
    o2.selectDisabledFix.initSelects();
  };
}
else {
  setTimeout("o2.selectDisabledFix.initSelects()", 500);
}
