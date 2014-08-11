o2.require( "/js/util/string.js"              );
o2.require( "/js/ajax.js"                     );
o2.require( "/js/util/urlMod.js"              );
o2.require( "/js/taglibs/html/popupDialog.js" );


o2.autoCompleteInput = {

  formatResult : function(row, pos, numResults, searchTerm) {
    var html = row[0];
    if (html === "errorAuthenticationFailure") {
      return document.location.href = o2.urlMod.urlMod({ removeHash : 1 }); // Will cause redirect to login page
    }
    return o2.stripTags(html);
  }

};
