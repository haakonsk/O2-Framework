function O2Lang(localeCode) {
  this.localeCode = localeCode;
  this.languageVariables = new Array();
  this.currentPrefix = "";
}

O2Lang.prototype.setCurrentPrefix = function (prefix) {
  this.currentPrefix = prefix;
}

O2Lang.prototype.clearCurrentPrefix = function () {
  this.currentPrefix = "";
}

O2Lang.prototype.setString = function (key, value) {
  var key = key;
  if (this.currentPrefix) {
    key = this.currentPrefix + "." + key;
  }
  this.languageVariables[key] = value;
}

O2Lang.prototype.getString = function (key, params) {
  if (this.currentPrefix) {
    key = this.currentPrefix + "." + key;
  }
  if (typeof(this.languageVariables[key]) == "undefined") {
    return key + " [" + this.localeCode + "]";
  }
  var value = this.languageVariables[key];
  if (params) {
    for (var variableName in params) {
      var re = new RegExp('\\$' + variableName, 'g');
      value = value.replace(re, params[variableName]);
      re = new RegExp('\\$\{' + variableName + '\}', 'g');
      value = value.replace(re, params[variableName]);
    }
  }
  return value;
}
