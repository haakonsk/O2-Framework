var formSubmitTime = {};

o2.formWasRecentlySubmitted = function(formName) {
  var msTime = (new Date()).getTime(); // Milliseconds since 1970
  if ( formSubmitTime[formName]  &&  msTime - formSubmitTime[formName] < 2000 ) { // Less than two seconds
    return true;
  }
  formSubmitTime[formName] = msTime;
  return false;
}

o2.getAllFormParamsAsQueryString = function(form) {
  var inputs    = form.getElementsByTagName("input");
  var textareas = form.getElementsByTagName("textarea");
  var selects   = form.getElementsByTagName("select");
  
  var seenRadiosOrCheckboxes = new Array();
  var params = "";
  // Merge arrays
  for (var i = 0; i < inputs.length; i++) {
    var elm = inputs[i];
    if (elm.type == "button") { // This was a problem with date select
      continue;
    }
    if (elm.name) {
      if ((elm.type == "checkbox" || elm.type == "radio")) {
        if (!seenRadiosOrCheckboxes[elm.name]) {
          seenRadiosOrCheckboxes[elm.name] = 1;
          params += o2.escape.escape(elm.name) + "=" + o2.getEscapedInputValueFromElement(form, elm, 1) + "&";
        }
      }
      else {
        params += o2.escape.escape(elm.name) + "=" + o2.getEscapedInputValueFromElement(form, elm, 1) + "&";
      }
    }
  }
  for (var i = 0; i < textareas.length; i++) {
    var elm = textareas[i];
    if (elm.name) {
      params += o2.escape.escape(elm.name)  +  "="  +  o2.getEscapedInputValueFromElement(form, elm)  +  "&"; // encodeURIComponent
    }
  }
  var seenSelects = new Array(); // XXX May have to do this for other input types as well?
  for (var i = 0; i < selects.length; i++) {
    var elm = selects[i];
    if (elm.name && !seenSelects[ elm.name ]) {
      seenSelects[ elm.name ] = true;
      params += o2.escape.escape(elm.name) + "=" + o2.getEscapedInputValueFromElement(form, elm, 1) + "&";
    }
  }
  params = params.substring(0, params.length-1);
  return params;
}

o2.getEscapedInputValue = function(form, name) {
  var element;
  eval("element = form[\"" + name + "\"];");
  if (!element) {
    alert("Didn't find element: " + name);
    return;
  }
  return o2.getEscapedInputValueFromElement(form, element);
}

o2.getEscapedInputValueFromElement = function(form, element) {
  if (element.toString() == "[object NodeList]") {
    element = element[0];
  }
  var name = element.name;
  if (element.toString() == "[object HTMLSelectElement]") {
    return o2.getSelectValuesAsString(form, name);
  }
  if (element.type == "radio") {
    var radioValue = o2.getRadioValue(form, name);
    return o2.escape.escape(radioValue);
  }
  if (element.type == "checkbox") {
    return o2.getCheckboxValuesAsString(form, name);
  }
  if (element.value) {
    return o2.escape.escape(element.value);
  }
  return "";
}

o2.getInputValueFromElement = function(form, element) {
  /*
  if (element.type == "text" || element.type == "hidden" || element.type == "password") {
    return element.value;
  }
  */
  if (element.toString() == "[object NodeList]") {
    element = element[0];
  }
  var name = element.name;
  if (element.toString() == "[object HTMLSelectElement]") {
    return o2.getSelectValues(form, name);
  }
  if (element.type == "radio") {
    var radioValue = o2.getRadioValue(form, name);
    return radioValue;
  }
  if (element.type == "checkbox") {
    return o2.getCheckboxValues(form, name);
  }
  if (element.value) {
    return element.value;
  }
  return "";
}

o2.getInputValue = function(form, name) {
  var element;
  eval("element = form[\"" + name + "\"];");
  if (!element) {
    alert("Didn't find element: " + name);
    return;
  }
  return o2.getInputValueFromElement(form, element);
}

o2.getRadioValue = function(form, name) {
  var radioElements = form.getElementsByTagName("input");
  for (var i = 0; i < radioElements.length; i++) {
    var input = radioElements[i];
    if (input.name == name   &&   input.type == "radio") {
      if (input.checked) {
        return input.value;
      }
    }
  }
  return null;
}

o2.isChecked = function(form, name, value) {
  var radioElements = form.getElementsByTagName("input");
  for (var i = 0; i < radioElements.length; i++) {
    var input = radioElements[i];
    if (input.name == name   &&   input.value == value) {
      return input.checked;
    }
  }
  return false;
}

o2.getCheckboxValues = function(form, name) {
  var values = new Array();
  var j = 0;
  
  var checkboxElements = form.getElementsByTagName("input");
  for (var i = 0; i < checkboxElements.length; i++) {
    var input = checkboxElements[i];
    if (input.name == name   &&   input.type == "checkbox") {
      if (input.checked) {
        values[j++] = input.value;
      }
    }
  }
  return values;
}

o2.getCheckboxValuesAsString = function(form, name) {
  var values = o2.getCheckboxValues(form, name);
  return o2.arrayToString(values, name);
}

o2.getSelectValues = function(form, name) {
  var values = new Array();
  var k = 0;
  
  var selectElements = form.getElementsByTagName("select");
  for (var i = 0; i < selectElements.length; i++) {
    var select = selectElements[i];
    if (select.name == name) {
      var optionElements = selectElements[i].getElementsByTagName("option");
      for (var j = 0; j < optionElements.length; j++) {
        var option = optionElements[j];
        if (option.selected) {
          values[k++] = option.value;
        }
      }
    }
  }
  return values;
}

o2.getSelectValuesAsString = function(form, name) {
  var values = o2.getSelectValues(form, name);
  return o2.arrayToString(values, name);
}

o2.arrayToString = function(array, name) {
  var string = "";
  for (var i = 0; i < array.length; i++) {
    if (i == 0) {
      string += o2.escape.escape( array[i] );
    }
    else {
      string += "&" + o2.escape.escape(name) + "=" + o2.escape.escape( array[i] );
    }
  }
  return string;
}

o2.getCurrentForm = function(elm) {
  if (elm.form) {
    return elm.form;
  }
  while (elm.parentNode) {
    elm = elm.parentNode;
    if (elm.nodeName == "FORM") {
      return elm;
    }
  }
  return null;
}

o2.clearForm = function(form) {

  var selects = form.getElementsByTagName("select");
  for (var i = 0; i < selects.length; i++) {
    var select = selects[i];
    var options = select.getElementsByTagName("option");
    for (var j = 0; j < options.length; j++) {
      options[j].selected = "";
    }
  }

  var inputs = form.getElementsByTagName("input");
  for (var i = 0; i < inputs.length; i++) {
    var input = inputs[i];
    if (input.type == "text" || input.type == "password") {
      input.value = "";
    }
    else if (input.type == "checkbox" || input.type == "radio") {
      input.checked = "";
    }
    else if (input.type == "hidden" && input.className.match(/multilingual/)) {
      input.value = "";
    }
  }

  var textareas = form.getElementsByTagName("textarea");
  for (var i = 0; i < textareas.length; i++) {
    var textarea = textareas[i];
    textarea.value = "";
  }

  if (window.setFormChanged) {
    setFormChanged();
  }
}
