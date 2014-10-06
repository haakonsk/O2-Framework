o2.requireJson("util/date");
o2.require("/js/DOMUtil.js");
o2.requireJs("jquery");

if (!o2.rules) {
  o2.rules = {};
}
o2.rules.rules = {
  "int" : function(value, param) {
    if (param.match(/notRequired/) && !value.length) { return true; }
    var minMax = param.split(",");
    testValue = parseInt(value);
    if (value != testValue)                 { return false; }
    if (minMax[0] && testValue < minMax[0]) { return false; }
    if (minMax[1] && testValue > minMax[1]) { return false; }
    return true;
  },
  "float" : function(value, param) {
    if (param.match(/notRequired/) && !value.length) { return true; }
    var minMax = param.split(",");
    testValue = parseFloat(value);
    if (value != testValue)                 { return false; }
    if (minMax[0] && testValue < minMax[0]) { return false; }
    if (minMax[1] && testValue > minMax[1]) { return false; }
    return true;
  },
  europeanDecimal : function(value, param) {
    if (param.match(/notRequired/) && !value.length) { return true; }
    value = value.replace(/\,/, ".");
    var minMax = param.split(",");
    testValue = parseFloat(value);
    if (value != testValue)                 { return false; }
    if (minMax[0] && testValue < minMax[0]) { return false; }
    if (minMax[1] && testValue > minMax[1]) { return false; }
    return true;
  },
  email : function(value, param) {
    if (param.match(/notRequired/) && !value.length) { return true; }
    var mailRegex = /^[^\@\s]+\@[^\.\s]+(\.[^\.\s]+)+$/;
    if (value.match(mailRegex)) { return true; }
    return false;
  },
  hostname : function(value, param) {
    if (param.match(/notRequired/) && !value.length) { return true; }
    var hostnameRegex = /[\w\d\.\-]+/;
    if (value.match(hostnameRegex)) { return true; }
    return false;
  },
  url : function(value, param) {
    if (param.match(/notRequired/) && !value.length) { return true; }
    var urlRegex = /^(http|ftp|mailto)\:\/\/[\%a-zA-z0-9\-\/\_\:\@\.]+$/;
    if (value.match(urlRegex)) { return true; }
    return false;
  },
  "regex" : function(value, param) {
    if (param.match(/notRequired/)) {
      param = param.replace(":notRequired", "");
      if (!value.length) {
        return true;
      }
    }
    var regex = eval(param);
    return value.match(regex);
  },
  path : function(value, param) {
    alert("You should note that this is a fake test! Please implement rule: path");
    return true;
  },
  fileExt : function(value, param) {
    if (param.match(/notRequired/) && !value.length) { return true; }
    param = "/^.+\." + param + "$/i";
    var regex = eval(param);
    return value.match(regex);
  },
  required : function(value, param) {
    return value.length > 0;
  },
  length : function(value, param) {
    var minMax = param.split(",");
    if (minMax[0]>0 && !value) { return false; }
    if (value) {
      if (minMax[0] > 0 && value.length < minMax[0]) { return false; }
      if (minMax[1] > 0 && value.length > minMax[1]) { return false; }
    }
    return true;
  },
  numChecked : function(value, param) {
    return value;
  },
  "javascript" : function(value, param) {
    return eval(param);
  },
  repeat : function(value, param) {
    var fieldName  = param;
    var otherValue = "";
    var elements = document.getElementsByTagName("input");
    var numFound = 0;
    for (var i = 0; i < elements.length; i++) {
      if (elements[i].name == fieldName) {
        numFound++;
        otherValue = elements[i].value;
      }
    }
    if (numFound == 0) {
      alert("Internal error: Didn't find element with name " + fieldName);
    }
    else if (numFound > 1) {
      alert("Internal error: More than one element exists with name " + fieldName);
    }
    return value == otherValue;
  },
  date : function(value, param) {
    // XXX Allow "," in date range by wrapping dates in quotes
    if (param.match(/notRequired/) && !value.length) { return true; }
    if (!value) {
      return false;
    }
    param.replace(/:notRequired/, "");

    var params = param.split(":");
    if (params[params.length-1] === "notRequired") {
      params.splice(params.length-1, 1); // Removes the last item
    }
    var format = params.splice(0, 1).toString(); // Removes and returns the first item
    while (format && format.substring(0, 1).match(/[\"\']/) && !format.substring(format.length-1, format.length).match(/[\"\']/)) {
      format += ":" + params.splice(0, 1);
    }
    format = format.replace(/^[\"\']/, ""); // Remove leading quotes
    format = format.replace(/[\"\']$/, ""); // Remove trailing quotes
    var givenDate;
    try {
      givenDate = o2.parseDate(format, value);
    }
    catch (e) {
      if (window.console) {
        console.warn( "Date '" + value + "' does not match format '" + format + "': " + o2.getExceptionMessage(e) );
      }
      return false;
    }
    if (params.length > 0) { // We have a date range
      var dateRange = params[0].split(",");
      var fromDate = o2.rules._getDate( dateRange[0], format );
      var toDate   = o2.rules._getDate( dateRange[1], format );
      if (givenDate < fromDate || givenDate > toDate) {
        return false;
      }
    }
    return true;
  }
};

o2.rules._getDate = function(dateStr, format) {
  if (dateStr === "today") {
    return new Date();
  }
  if (dateStr.match(/^[+-]\d+\w$/)) {
    var matches = dateStr.match(/^([+-])(\d+)(\w)$/);
    var now  = new Date();
    var date = new Date();
    var sign = matches[1];
    var num  = matches[2];
    var type = matches[3];
    var delta = num * (sign === "-" ? -1 : 1);
    if (type === "y") {
      date.setFullYear( now.getFullYear() + delta );
    }
    else if (type === "M") {
      date.setMonth( now.getMonth() + delta );
    }
    else if (type === "w") {
      date.setDate( now.getDate() + 7*delta );
    }
    else if (type === "d") {
      date.setDate( now.getDate() + delta );
    }
    else if (type === "h") {
      date.setHours( now.getHours() + delta );
    }
    else if (type === "m") {
      date.setMinutes( now.getMinutes() + delta );
    }
    else if (type === "s") {
      date.setSeconds( now.getSeconds() + delta );
    }
    return date;
  }
  else {
    return o2.parseDate(format, dateStr);
  }
};

o2.rules.formErrors    = [];
o2.rules.formElements  = {};
o2.rules.formHasErrors = false;
o2.rules.onSubmitEval  = {}; // Add code to be evaluated on submit here. Form name is key, codestring is value

o2.rules.addOnSubmitEval = function(formName, evalJs) {
  if ( !o2.rules.onSubmitEval[formName] ) {
    o2.rules.onSubmitEval[formName] = "";
  }
  o2.rules.onSubmitEval[formName] += evalJs + ";";
}

o2.rules.submitForm = function(f, functionName) {
  if (o2.rules.checkForm(f, functionName)) {
    f.submit();
  }
}

o2.rules.checkForm = function(f, functionName) {
  if (!f) return;   // vonheim@20060308 <form onsubmit> and <input type=submit> both calls this method. one of them does not include "f"

  // added by nilschd 20070115, submit button sends it self as an f with firefox 2.x
  if (f.type == "button") {
    f = f.form; // then we set the f to be the this buttons parent form
  }

  if (f.name && o2.rules.onSubmitEval[f.name]) {
    eval( o2.rules.onSubmitEval[f.name] );
  }
  o2.rules.verifyForm(f);

  if (o2.rules.formHasErrors) {
    o2.rules.onRuleCheckFailure(f, functionName);
    return false;
  }

  if (o2.rules.multilingualSubmitForm) {
    o2.rules.multilingualSubmitForm();
  }
  // In case you want to have som javascript executed before submitting the form, but after the rules are checked
  if (o2.rules.onRuleCheckSuccess) {
    o2.rules.onRuleCheckSuccess();
  }
  return true;
}

o2.rules.onRuleCheckFailure = function(form, functionName) {
  var errorTitle = form.getAttribute("ruleTitle") || "";
  var errorBody = "";
  if (functionName) {
    if (o2.rules.formErrors && o2.rules.formErrors.length) {
      errorBody = o2.rules.formErrors.join("<br>");
    }
    if (functionName && !window[functionName]) {
      return alert("Method '" + functionName + "' does not exist");
    }
    window[functionName].call(this, errorTitle, errorBody);
  }
  else if (form.getAttribute("errorMessageHandler")) {
    // Want to allow client code to format the error messages. Not doing this inside "if (functionName)" because we need to be backward compatible.
    functionName = form.getAttribute("errorMessageHandler");
    if (functionName && !window[functionName]) {
      return alert("Method '" + functionName + "' does not exist");
    }
    window[functionName].call(this, errorTitle, o2.rules.formErrors);
  }
  else {
    if (o2.rules.formErrors && o2.rules.formErrors.length) {
      errorBody = o2.rules.formErrors.join("\n");
    }
    alert(errorTitle + "\n" + errorBody);
  }
}

o2.rules.verifyForm = function(form, ignoreEmptyFields) {
  o2.rules.formErrors.length     = 0;
  o2.rules.formHasErrors         = false;
  o2.rules.radioOrCheckBoxGroups = {};
  o2.rules.ruleMsgSeen           = {};
  o2.rules.formElements          = {};

  o2.rules.checkNode(form, ignoreEmptyFields);

  var defaultRuleHandler = form.getAttribute("ruleHandler");
  for (var nodeName in o2.rules.formElements) {
    var element = o2.rules.formElements[nodeName];
    if (typeof element !== "object") {
      continue;
    }
    var ruleHandler = element.node.getAttribute("ruleHandler") || defaultRuleHandler;
    if (!ruleHandler) {
      continue;
    }
    if (!window[ruleHandler]) {
      alert("Method '" + ruleHandler + "' does not exist");
      continue;
    }
    window[ruleHandler].call(this, form, element.node, element.ruleMsg, element.success);
  }

  return !o2.rules.formHasErrors;
}

o2.rules.getVerifyErrors = function() {
  return o2.rules.formErrors;
}

o2.rules.checkNode = function(node, ignoreEmptyFields) {
  if (!node) return;
  if (node.nodeType == 1) {
    var rule            = node.getAttribute("RULE");
    var forceValidation = rule && rule.match(/:forceValidation/i);
    if (node.disabled && !forceValidation) {
      return;
    }
    var isDragList = o2.hasClassName(node, "dragList");
    if (isDragList && !$(node).is(":visible")) {
      return;
    }
    if ( ( node.tagName === "INPUT" || node.tagName === "SELECT" || node.tagName === "TEXTAREA" || isDragList )
         && rule && (!node.disabled || forceValidation) ) {
      var ruleParts = rule.split(":");
      if (!o2.rules.rules[ ruleParts[0] ]) {
        alert("No such rule: "+ruleParts[0]);
        o2.rules.markError(node);
      }
      else {
        var params = new Array;
        for (var i = 1; i < ruleParts.length; i++) {
          params[params.length] = ruleParts[i];
        }
        var param = params.join(":");
        var value;

        if (node.tagName == "SELECT") {
          value = node.options[node.selectedIndex].value;
        }
        else if (o2.hasClassName(node, "dragList")) {
          value = getComponentById(node.id).listValues();
        }
        else if (o2.rules.isCheckbox(node) && ruleParts[0] == "numChecked") {
          value = o2.rules.checkCheckBoxGroup(node, param);
        }
        else if (o2.rules.isRadio(node)) {
          if (ruleParts[0] == "required") {
            node.setAttribute("rule", "numChecked:1,1");
            ruleParts[0] = "numChecked";
          }
          if (ruleParts[0] == "numChecked") {
            value = o2.rules.checkCheckBoxGroup(node, param);
          }
        }
        else if (node.id.substring(0,9) == "comboBox_" && node.getAttribute("mode") == "select") {
          //20080208 nilschd, adding support for ComboBox in mode "select".
          //Select mode allows you to use ComboBox as a select compononent with "type ahead feature"
          var comboBoxId = node.id.substring(9, node.id.length-4 );
          value = document.getElementById(comboBoxId).value;
        }
        else {
          value = node.value;
        }
        if (!value && ignoreEmptyFields) {
          return;
        }

        var ok = o2.rules.rules[ ruleParts[0] ](value, param);
        if (ok) {
          o2.removeClassName( node,            "formRuleFailed"            );
          o2.removeClassName( node.parentNode, "descendantsFormRuleFailed" );

          var wrapper = o2.rules.getRadioOrCheckboxWrapper(node);
          if (wrapper) {
            o2.removeClassName(wrapper, "descendantsFormRuleFailed");
            if (o2.rules.isCheckbox(node) || o2.rules.isRadio(node)) {
              o2.removeClassName(wrapper, node.type + "RuleFailed");
            }
          }

          o2.rules.formElements[ node.name ] = {
            node    : node,
            ruleMsg : node.getAttribute("ruleMsg"),
            success : true
          };
        }
        else {
          o2.rules.markError(node);
        }
      }
    }
    else if (node.hasChildNodes) {
      var nodes = node.childNodes;
      for (var i = 0; i < nodes.length; i++) {
        o2.rules.checkNode( nodes[i], ignoreEmptyFields );
      }
    }
  }
}

o2.rules.isCheckboxOrRadio = function(node) {
  return o2.rules.isCheckbox(node) || o2.rules.isRadio(node);
}

o2.rules.isCheckbox = function(node) {
  return node.type && node.type.toLowerCase() === "checkbox";
}

o2.rules.isRadio = function(node) {
  return node.type && node.type.toLowerCase() === "radio";
}

o2.rules.ruleMsgSeen = {};
o2.rules.markError = function(node) {
  o2.rules.formHasErrors = true;
  var ruleMsg = node.getAttribute("ruleMsg");
  if (ruleMsg) {
    // To disable duplicate ruleMsg'es for checkboxes and radiogroups
    if (o2.rules.isCheckbox(node) || o2.rules.isRadio(node)) {
      if (!o2.rules.ruleMsgSeen[ node.name ]) {
        o2.rules.formErrors.push(ruleMsg);
        o2.rules.ruleMsgSeen[ node.name ] = true;
      }
    }
    else {
      o2.rules.formErrors.push(ruleMsg);
    }
  }

  if (!o2.getClosestAncestorByTagName(node, "form").getAttribute("ruleHandler") && !node.getAttribute("ruleHandler")) {
    o2.addClassName(node, "formRuleFailed");
    // To allow colors on checkboxes and radio buttons
    // Set className=descendantsFormRuleFailed on element surrounding the input field whose rule failed.
    var wrapper = o2.rules.getRadioOrCheckboxWrapper(node);
    if (wrapper) {
      o2.addClassName(wrapper, "descendantsFormRuleFailed");
      if (o2.rules.isCheckbox(node) || o2.rules.isRadio(node)) {
        o2.addClassName(wrapper, node.type + "RuleFailed");
      }
    }
  }

  o2.rules.formElements[ node.name ] = {
    node    : node,
    ruleMsg : ruleMsg,
    success : false
  };
}

o2.rules.getRadioOrCheckboxWrapper = function(node) {
  var wrapper = node.parentNode;
  if (o2.hasClassName(wrapper.parentNode, "o2RadioButtons")  ||  o2.hasClassName(wrapper.parentNode, "o2Checkboxes")) {
    wrapper = wrapper.parentNode.parentNode;
  }
  else if (o2.rules.isCheckbox(node) || o2.rules.isRadio(node)) {
    wrapper = o2.rules.findCheckboxOrRadioWrapper(node);
  }
  return wrapper;
}

o2.rules.findCheckboxOrRadioWrapper = function(node) {
  var form = o2.getClosestAncestorByTagName(node, "form");
  var checkboxesOrRadios = o2.rules.getInputFields(form, node.name);
  return o2.rules.findClosestCommonAncestor(checkboxesOrRadios);
}

o2.rules.findClosestCommonAncestor = function(nodes) {
  var parent = nodes[0].parentNode;
  while (parent) {
    var failure = false;
    for (var i = 0; i < nodes.length; i++) {
      if (!o2.rules.isCheckbox( nodes[i] )  &&  !o2.rules.isRadio( nodes[i] )) {
        throw new O2Exception( nodes[i].type );
      }
      if (!o2.rules.hasAncestor( nodes[i], parent )) {
        failure = true;
        break;
      }
    }
    if (!failure) {
      return parent;
    }
    parent = parent.parentNode;
  }
  throw new O2Exception("Didn't find a common ancestor");
}

o2.rules.hasAncestor = function(node, potentialAncestor) {
  while (node) {
    node = node.parentNode;
    if (node === potentialAncestor) {
      return true;
    }
  }
  return false;
}

o2.rules.getInputFields = function(node, name) {
  var inputFields = new Array();

  var inputs    = node.getElementsByTagName("input");
  var textareas = node.getElementsByTagName("textarea");
  var selects   = node.getElementsByTagName("select");

  for (var i = 0; i < inputs.length; i++) {
    if (!name  ||  inputs[i].name === name) {
      inputFields.push( inputs[i] );
    }
  }
  for (var i = 0; i < textareas.length; i++) {
    if (!name  ||  textareas[i].name === name) {
      inputFields.push( textareas[i] );
    }
  }
  for (var i = 0; i < selects.length; i++) {
    if (!name  ||  selects[i].name === name) {
      inputFields.push( selects[i] );
    }
  }

  return inputFields;
}

// To allow having a group of checkboxes and to specify that e.g. 2 or more must be selected
o2.rules.radioOrCheckBoxGroups = {};
o2.rules.checkCheckBoxGroup = function(node, param) {
  var f = o2.getClosestAncestorByTagName(node, "form"); // the form
  var groupName       = node.name; // the group of checkBoxes
  var checkboxGroupId = f.name + "_" + groupName;
  if (o2.rules.radioOrCheckBoxGroups[checkboxGroupId]) { // we have allready checked this group, aka cached
    return o2.rules.radioOrCheckBoxGroups[checkboxGroupId];
  }
  var totalChecked = 0;
  if (param === "") { // ok lets use default rule 1,*. Then the checkboxes acts like a radiogroup
    param = "1,*";
  }
  else {
    var matches = param.match(/^\d+$/);
    if (matches) {
      var num = matches[0];
      param = num + "," + num;
    }
  }
  
  var rules = param.split(",");

  if (f[groupName].length) {
    for (var i = 0; i < f[groupName].length; i++) {
      if ( f[groupName][i].checked ) {
        totalChecked++;
      }
    }
  }
  else { // f[groupName].length is undefined if there's just one element in the group.
    if (node.checked) {
      totalChecked++;
    }
  }

  if ( totalChecked >= parseInt( rules[0] )  &&  (rules[1] === "*" || totalChecked <= parseInt( rules[1] )) ) {
    o2.rules.radioOrCheckBoxGroups[checkboxGroupId] = true;
  }
  else {
    o2.rules.radioOrCheckBoxGroups[checkboxGroupId] = false; // Didn't meet requirments in the provided rule
  }
  return o2.rules.radioOrCheckBoxGroups[checkboxGroupId];
}
