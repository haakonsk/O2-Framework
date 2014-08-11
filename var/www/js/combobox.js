o2.comboBox = {};

o2.comboBox.init = function(id, value) {
  var ul = document.getElementById(id);
  var wrapper = ul.parentNode;
  wrapper.style.position = "relative";
  
  var input = document.createElement("input");
  input.value = value;
  input.name  = ul.getAttribute("name").replace(/^hidden_/, "");
  input.id    = "comboBox_input_" + id;
  input.type  = "text";
  o2.addClassName(input, "comboBox");
  ul.parentNode.insertBefore(input, ul);
  
  var btn = document.createElement("button");
  btn.innerHTML = "v";
  btn.setAttribute("title", "Vis alle valgmuligheter");
  btn.setAttribute("onClick", "o2.comboBox.toggleOptions('" + id + "'); return false;");
  btn.setAttribute("tabIndex", -1);
  o2.addClassName(btn, "comboBoxToggleButton");
  ul.parentNode.insertBefore(btn, ul);
  
  ul.style.display = "none";
  ul.style.backgroundColor = "white";
  ul.id = id;
}

o2.comboBox.toggleOptions = function(id) {
  var ul = document.getElementById(id);
  ul.style.display = ul.style.display === "none" ? "" : "none";
}

o2.comboBox.setInputValue = function(id, value) {
  var input = document.getElementById("comboBox_input_" + id);
  input.value = value;
}
