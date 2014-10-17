o2.require("/js/jquery.js");

o2.checkboxGroup = {};

o2.checkboxGroup.setOnSubmit = function(formName, checkboxGroupName) {
  o2.rules.addOnSubmitEval(formName, "o2.checkboxGroup.submitEmptyCheckbox('" + formName + "', '" + checkboxGroupName + "');");
}

o2.checkboxGroup.submitEmptyCheckbox = function(formName, checkboxGroupName) {
  var form = document.forms[formName];
  if (form.getAttribute("isAjaxForm")) {
    return;
  }
  var values = o2.getCheckboxValues(form, checkboxGroupName);
  if (values.length === 0) {
    var hiddenInputExists = false;
    var hiddenInputs = o2.checkboxGroup.getHiddenInputs(form, checkboxGroupName);
    for (var i = 0; i < hiddenInputs.length; i++) {
      var input = hiddenInputs[i];
      hiddenInputExists = true;
    }
    if (!hiddenInputExists) {
      $(form).append( $("<input type='hidden' name='" + checkboxGroupName + "' value=''>") );
    }
  }
  else {
    var hiddenInputs = o2.checkboxGroup.getHiddenInputs(form, checkboxGroupName);
    for (var i = 0; i < hiddenInputs.length; i++) {
      var input = hiddenInputs[i];
      input.parentNode.removeChild(input);
    }
  }
}

o2.checkboxGroup.getHiddenInputs = function(form, checkboxGroupName) {
  var hiddenInputs = [];
  var inputs = form.getElementsByTagName("input");
  for (var i = 0; i < inputs.length; i++) {
    var input = inputs[i];
    if (input.name === checkboxGroupName && !input.value) {
      hiddenInputs.push(input);
    }
  }
  return hiddenInputs;
}
