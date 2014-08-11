var TMP_MSG_CLASSNAMES = new Array();

o2.temporaryMessage = {};

o2.temporaryMessage.setMessage = function(params) {
  var type     = params.type; /* info, error, warning */
  type         = type.substr(0, 1).toUpperCase() + type.substr(1, type.length); // Titlecase
  var duration = params.duration || 5;
  var message  = params.message;
  var id       = params.id;

  var elm = document.getElementById(id);

  TMP_MSG_CLASSNAMES[id] = elm.className;
  elm.innerHTML = message;
  elm.className = "temporaryMessage temporaryMessage" + type + " " + elm.className;
  if (elm.style.display == "none") {
    elm.style.display = "";
  }
  setTimeout("o2.temporaryMessage.removeMessage('" + id + "');", duration*1000);
}

o2.temporaryMessage.removeMessage = function(id) {
  var elm = document.getElementById(id);
  elm.innerHTML = "";
  elm.style.display = "none";
  elm.className = TMP_MSG_CLASSNAMES[id];
}
