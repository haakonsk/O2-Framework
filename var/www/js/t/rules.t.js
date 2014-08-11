o2.require("/js/rules.js");

var rulesTest = {
  runTests : function() {
    for (var i = 0; i < rulesTest.tests.length; i++) {
      var test = rulesTest.tests[i];
      tester.is( o2.rules.rules.email(test.value, test.notRequired ? "notRequired" : ""), test.valid, test.value );
    }
  },

  tests : new Array(
    {
      rule  : "email",
      value : "nn@linpro.no",
      valid : true
    },
    {
      rule  : "email",
      value : "nn@linprono",
      valid : false
    },
    {
      rule  : "email",
      value : "nnAlinpro.no",
      valid : false
    },
    {
      rule  : "email",
      value : "nn@lin pro.no",
      valid : false
    },
    {
      rule  : "email",
      value : "n n@linpro.no",
      valid : false
    },
    {
      rule  : "email",
      value : "nn@linpro.no ",
      valid : false
    },
    {
      rule  : "email",
      value : " nn@linpro.no",
      valid : false
    },
    {
      rule        : "email",
      value       : "",
      notRequired : true,
      valid       : true
    },
    {
      rule        : "email",
      value       : "",
      valid       : false
    },
    {
      rule        : "email",
      value       : "nn@redpill-linpro.com",
      valid       : true
    }
  )
};

tester.setStartMethod(rulesTest.runTests);
