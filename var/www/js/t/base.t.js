o2.require("/js/t/includes/test_require.js");

var base = {
  runTests : function() {
    var url = "/js/t/base.t.js";
    base.testRequire();
    base.testClassNameFunctions();
  },

  testRequire : function() {
    tester.diag("Testing function require");
    tester.is( myTest(), "myTest", "Function returned correct value" );
  },

  testClassNameFunctions : function() {
    tester.diag("Testing functions to manipulate className (addClassName, hasClassName, removeClassName)");
    var div = document.createElement("div");
    o2.addClassName(div, "class1");
    tester.ok(  o2.hasClassName(div, "class1"), "added class1" );
    tester.ok( !o2.hasClassName(div, "class2"), "doesn't have a class that hasn't been added yet" );
    o2.addClassName(div, "class2");
    o2.addClassName(div, "class3");
    tester.ok( o2.hasClassName(div, "class1") && o2.hasClassName(div, "class2") && o2.hasClassName(div, "class3"), "added class2 and class3" );
    o2.removeClassName(div, "class2");
    tester.ok( o2.hasClassName(div, "class1") && !o2.hasClassName(div, "class2") && o2.hasClassName(div, "class3"), "removed class2" );
  }
};

tester.setStartMethod(base.runTests);
