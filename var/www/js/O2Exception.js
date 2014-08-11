function O2Exception(message) {
  this.message = message;
  this.name    = "O2Exception";
}

O2Exception.prototype.toString = function() {
  return this.name + ": " + this.message;
}

o2.getExceptionMessage = function(exception, full) {
  if (typeof exception !== "object") {
    return exception;
  }
  var message = "";
  if (!exception["name"] || !exception.message) {
    message += exception.toString();
  }
  else {
    if (exception["name"]) {
      message += exception["name"] + ": ";
    }
    if (exception.message) {
      message += exception.message;
    }
  }
  if (full) {
    var extraInfo = "";
    for (var key in exception) {
      if (key !== "name" && key !== "message" && typeof exception[key] !== "function") {
        extraInfo += "  " + key + " = " + exception[key] + "\n";
      }
    }
    if (extraInfo) {
      message += "\n\nOther info:\n" + extraInfo;
    }
  }
  return message;
}
