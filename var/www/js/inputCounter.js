o2.inputCount = function(elm, countContainerId, maxLength) {
  var currentCount = 0;
  var type = "element";
  if (elm == parseInt(elm)) {
    currentCount = elm;
    type = "count";
  }
  else {
    currentCount = elm.value.length;
  }
  var counter = currentCount || 0;
  if (maxLength >= 0) {
    if (type == "element" && counter > maxLength) { elm.value = elm.value.substring(0,maxLength); }
    counter += "/" + maxLength;
  }
  var countContainer = document.getElementById( countContainerId );
  if (countContainer) {
    countContainer.innerHTML = counter;
  }
}
