var ids = new Array("ajaxTesterElement1", "ajaxTesterElement2", "ajaxTesterElement3", "ajaxTesterElement4");
for (var i = 0; i < ids.length; i++) {
  var elm = document.getElementById( ids[i] );
  if (elm && o2.getComputedStyle(elm, "display") === "none") {
    elm.parentNode.removeChild(elm);
  }
}
