o2.require("/js/ajax.js");
o2.require("/js/DOMUtil.js"); // Used by test_ajax2.js

var ajaxTester = {
  runTests : function() {
    o2.ajax.handleServerResponse({
      result               : "ok",
      onSuccess            : "tester.ok(true, 'onSuccess called');",
      javascriptsToExecute : new Array("tester.ok(true, 'javascript 1 to execute executed');",
                                       "tester.ok(true, 'javascript 2 to execute executed');")
    });

    o2.ajax.handleServerResponse({
      result               : "ok",
      javascriptFiles      : new Array("/js/t/includes/test_ajax.js")
    });
  },

  jsFileIncludedCallback : function() { // Callback from test_ajax.js
    tester.is(tester.getCounter(), 4, "All 4 tests passed");
    ajaxTester.continueTesting();
  },

  continueTesting : function() {
    document.body.innerHTML
      += "<span class='okTest' id='ajaxTesterElement1' style='display: none;'>ok 6 - css file included</span>"
      +  "<span class='error'  id='ajaxTesterElement2'>not ok 6 - css file included</span><br id='ajaxTesterElement3'>\n"
      +  "<span class='info'   id='ajaxTesterElement4'># Failed test 'css file included'</span><br>\n";

    o2.ajax.handleServerResponse({
      result   : "ok",
      cssFiles : new Array("/js/t/includes/css/test_ajax.css") // Sets the display property to "none" on ajaxTesterElement
    });

    setTimeout("o2.require('/js/t/includes/test_ajax2.js')", 200); // The code in this file removes the element with the error message if it has its display property set to "none"
  }
};

tester.setStartMethod(ajaxTester.runTests);
