o2.systemModel = {};

o2.systemModel.deleteField = function(link, fieldName) {
  if (confirm( o2.lang.getString("System.Model.confirmDeleteField", {fieldName : fieldName}) )) {
    document.location.href = link.getAttribute("href");
  }
}

o2.systemModel.deleteBaseClass = function(link) {
  if (confirm( o2.lang.getString("System.Model.confirmDeleteBaseClass") )) {
    document.location.href = link.getAttribute("href");
  }
}

o2.systemModel.deleteClass = function(link) {
  if (confirm( o2.lang.getString("System.Model.confirmDeleteClass") )) {
    var href = link.getAttribute("href");
    if (confirm( o2.lang.getString("System.Model.confirmDeleteDatabaseTable") )) {
      href += "&deleteDbTable=1";
    }
    if (confirm( o2.lang.getString("System.Model.confirmDeleteObjects") )) {
      href += "&deleteObjects=1";
    }
    document.location.href = href;
  }
}

o2.systemModel.toggleDisplay = function(elm, visibleDisplayType) {
  elm.style.display = elm.style.display === visibleDisplayType  ?  "none"  :  visibleDisplayType;
}
