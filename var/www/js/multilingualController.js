o2.require("/js/DOMUtil.js");

o2.multilingualController = {};

o2.multilingualController.currentActiveLocaleCode = "";

o2.multilingualController.rebuild = function() {
  if (!o2LocalesAvailable) {
    alert("No locales-object defined!");
    return false;
  }
  var controllerDiv = document.getElementById("o2MultilingualControllerDiv");
  if ( !controllerDiv ) {
    alert("No 'o2MultilingualControllerDiv' found in document");
    return false;
  }
  var controllerContent = "";
  for (var i = 0; i < o2LocalesAvailable.length; i++) {
    var className;
    if (o2LocalesAvailable[i].selected == 1) {
      className = "selected";
    }
    else if (o2LocalesAvailable[i].inUse == 1) {
      className = "inUse";
    }
    else {
      className = "notInUse";
    }

    var onClick = o2LocalesAvailable[i].onClick.replace(/\'/g, "&apos;");
    if (o2LocalesAvailable[i].type == "flag") {
      controllerContent += '<a href="javascript: o2.multilingualController.switchToLocale(\'' + o2LocalesAvailable[i].localeCode + '\', onSwitchPreJs, onSwitchPostJs);" class="' + className
        + '" onClick=\'' + onClick + "'>"
        + '<img src="' + o2LocalesAvailable[i].flagSrc + '" />';
    }
    else {
      controllerContent += '<a href="javascript: o2.multilingualController.switchToLocale(\'' + o2LocalesAvailable[i].localeCode + '\', onSwitchPreJs, onSwitchPostJs);" class="' + className
        + '" onClick=\'' + onClick + "'>"
        + o2LocalesAvailable[i].name + "</a>";
    }

  }
  controllerDiv.innerHTML = controllerContent;
  return true;
}

o2.multilingualController.switchToLocale = function(newLocaleCode, onSwitchPreJs, onSwitchPostJs) {
  if (onSwitchPreJs) {
    eval(onSwitchPreJs);
  }
  var availableLocales = {};
  for (var i = 0; i < o2LocalesAvailable.length; i++) {
    var selected = 0;
    if (o2LocalesAvailable[i].localeCode == newLocaleCode) {
      selected = 1;
      o2LocalesAvailable[i].inUse = 1;
    }
    availableLocales[ o2LocalesAvailable[i].localeCode ] = { "selected" : selected };
    o2LocalesAvailable[i].selected = selected;
  }
  o2.multilingualController.setHiddenValues(newLocaleCode);
  o2.multilingualController.rebuild();
  if (onSwitchPostJs) {
    eval(onSwitchPostJs);
  }
}

o2.multilingualController.onSwitchReloadPage = function(localeCode) {
  var href = document.location.href;
  if (href.match(/localeCode=/)) {
    href = href.replace(/localeCode=\w\w_\w\w/, "localeCode=" + localeCode);
  }
  else {
    href += "&localeCode=" + localeCode;
  }
  document.location.href = href;
}

o2.multilingualController.setHiddenValues = function(newLocaleCode) {
  var multilingualElements = o2.multilingualController.getElementsByAttribute("multilingual");

  for (var i = 0; i < multilingualElements.length; i++) {
    var element = multilingualElements[i];
    var name = element.name;

    if (o2.multilingualController.currentActiveLocaleCode) {
      for (var j = 0; j < o2LocalesAvailable.length; j++) {
        var locale = o2LocalesAvailable[j].localeCode;
        var hiddenField = o2.multilingualController._getHiddenFieldFor(element, locale);
        if ((!hiddenField || hiddenField.getAttribute("type") !== "hidden") && window.console) {
          console.error("Didn't find hidden field for " + element.id);
        }
        var oldHiddenValue = hiddenField.value;
        if (hiddenField && o2.multilingualController.currentActiveLocaleCode && o2.multilingualController.currentActiveLocaleCode == locale) {
          if (window.xinha_editors && xinha_editors[element.id]) {
            hiddenField.value = xinha_editors[element.id].getHTML();
          }
          else {
            hiddenField.value = element.value;
          }
        }
      }
    }
    // First time this method is called we do the opposite of what the method name suggests: Copy from hidden field to visible field
    if (newLocaleCode) {
      for (var j = 0; j < o2LocalesAvailable.length; j++) {
        var locale = o2LocalesAvailable[j].localeCode;
        var hiddenField = o2.multilingualController._getHiddenFieldFor(element, locale);
        if ((!hiddenField || hiddenField.getAttribute("type") !== "hidden") && window.console) {
          console.error("Didn't find " + locale + " hidden field for " + element.id);
        }
        if (hiddenField && newLocaleCode === locale  &&  o2.multilingualController.currentActiveLocaleCode !== newLocaleCode) {
          element.value = hiddenField.value;
          if (window.xinha_editors && xinha_editors[element.id]) {
            xinha_editors[element.id].setHTML(hiddenField.value);
          }
        }
      }
    }
  }
  if (newLocaleCode) {
    o2.multilingualController.currentActiveLocaleCode = newLocaleCode;
  }
}

if (!o2.rules) {
  o2.rules = {};
}
o2.rules.multilingualSubmitForm = function() {
  o2.multilingualController.setHiddenValues();
  // Avoid fuckup with $cgi->getStructure()
  var multilingualElements = o2.multilingualController.getElementsByAttribute("multilingual");
}

o2.multilingualController.getElementsByAttribute = function(attributeName) {
  var allElements      = new Array();
  var selectedElements = new Array();
  if (document.all) {
    allElements = document.all;
  }
  else {
    allElements = document.getElementsByTagName("*");
  }
  for (var i = 0; i < allElements.length; i++) {
    var attributeValue = allElements[i].getAttribute( attributeName );
    if ( typeof attributeValue == "string" && attributeValue.length > 0 ) {
      selectedElements.push( allElements[i] );
    }
  }  
  return selectedElements;
}

o2.multilingualController._getHiddenFieldFor = function(element, locale) {
  var hiddenField;
  var tmpField = element;
  while (tmpField = o2.getPreviousElement(tmpField)) {
    if (tmpField.tagName.toLowerCase() !== "input") {
      break;
    }
    var regex = new RegExp("\\b" + locale + "\\.");
    if (tmpField.name.match(regex)) {
      hiddenField = tmpField;
    }
  }
  return hiddenField;
}
