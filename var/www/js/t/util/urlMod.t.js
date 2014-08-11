o2.require("/js/util/urlMod.js");

var urlMod = {
  runTests : function() {
    var url = "/js/util/urlMod.t.js";
    for (var i = 0; i < urlMod.tests.length; i++) {
      var test = urlMod.tests[i];
      o2.urlMod.setCurrentUrl(test.currentUrl);
      tester.is( o2.urlMod.urlMod( test.urlModParams ),  test.resultUrl, "urlMod" );
    }
  },

  tests : new Array(
    {
      currentUrl : '/',
      urlModParams : {
        setDispatcherPath : 'o2',
        setClass          : 'Newsletter-Letter',
        setMethod         : 'init',
        setParams         : 'objectId=2'
      },
      resultUrl  : '/o2/Newsletter-Letter/init?objectId=2'
    },
    {
      currentUrl : '/someCategory/123.o2?objectId=2',
      urlModParams   : {
        setDispatcherPath : 'o3',
        setClass          : 'Newsletter-Letter',
        setMethod         : 'init',
        removeParams      : 1
      },
      resultUrl  : '/o3/Newsletter-Letter/init'
    },
    {
      currentUrl : '/someCategory/123.o2?objectId=2',
      urlModParams   : {
        setDispatcherPath : 'o3',
        setClass          : 'Newsletter-Letter',
        setMethod         : 'init',
        removeParams      : 1,
        setSecure         : 1
      },
      resultUrl  : 'https://' + document.location.href.replace(/^https?:\/\/([^\/]+).*/, "$1") + '/o3/Newsletter-Letter/init'
    },
    {
      currentUrl : '/someCategory/someCategory2?a=1',
      urlModParams : {
        setDispatcherPath : 'o2',
        setClass          : 'Newsletter-Letter',
        setMethod         : 'init',
        setParam          : 'objectId=2'
      },
      resultUrl  : '/o2/Newsletter-Letter/init?a=1&objectId=2'
    },
    {
      currentUrl : '/someCategory/someCategory2?a=1',
      urlModParams : {
        setDispatcherPath : 'o2',
        setClass          : 'Newsletter-Letter',
        setMethod         : 'init',
        setParams         : 'objectId=2'
      },
      resultUrl  : '/o2/Newsletter-Letter/init?objectId=2'
    },
    {
      currentUrl : '/o2/User-Profile/loginForm',
      urlModParams  : {
        setClass    : 'Newsletter-Letter',
        setMethod   : 'init',
        setParams   : 'objectId=2',
        absoluteURL : 1
      },
      resultUrl  : "http://" + document.location.href.replace(/^https?:\/\/([^\/]+).*/, "$1") + "/o2/Newsletter-Letter/init?objectId=2"
    },
    {
      currentUrl : '/o3/User-Profile/loginForm?a=2&b=6',
      urlModParams  : {
        setClass    : 'Newsletter-Letter',
        setMethod   : 'init',
        toggleParam : 'a=1|2|3,b=4|5|6'
      },
      resultUrl  : '/o3/Newsletter-Letter/init?a=3&b=4'
    },
    {
      currentUrl : '/o2/User-Profile/loginForm',
      urlModParams  : {
        setClass    : 'Newsletter-Letter',
        setMethod   : 'init',
        toggleParam : 'a=1|2|3,b=4|5|6'
      },
      resultUrl  : '/o2/Newsletter-Letter/init?a=1&b=4'
    },
    {
      currentUrl : '/o2/User-Profile/loginForm?a=2&b=6',
      urlModParams  : {
        setClass    : 'Newsletter-Letter',
        setMethod   : 'init',
        setParam    : 'a=1,b=2'
      },
      resultUrl  : '/o2/Newsletter-Letter/init?a=1&b=2'
    },
    {
      currentUrl : '/o2/User-Profile/loginForm?a=2&b=6',
      urlModParams  : {
        setClass    : 'Newsletter-Letter',
        setMethod   : 'init',
        setParam    : 'a=3,b=4'
      },
      resultUrl  : '/o2/Newsletter-Letter/init?a=3&b=4'
    },
    {
      currentUrl : '/o2/User-Profile/loginForm?a=2&b=6',
      urlModParams  : {
        setClass    : 'Newsletter-Letter',
        setMethod   : 'init',
        appendParam : 'a=3,b=4'
      },
      resultUrl  : '/o2/Newsletter-Letter/init?a=2&b=6&a=3&b=4'
    },
    {
      currentUrl : '/o2/InfoPage-InfoPageReports',
      urlModParams  : {
        setMethod : 'showReport'
      },
      resultUrl  : '/o2/InfoPage-InfoPageReports/showReport'
    },
    {
      currentUrl : '/o2cms',
      urlModParams  : {
        setClass  : 'User-Login',
        setMethod : 'login'
      },
      resultUrl  : '/o2cms/User-Login/login'
    },
    {
      currentUrl : '/o2cms/User-Login/login',
      urlModParams  : {
        setMethod : 'logout'
      },
      resultUrl  : '/o2cms/User-Login/logout'
    },
    { 
      currentUrl : '/o2/Shop-Order/init?offerId=154855&startDate=20080422',
      urlModParams  : {
        removeParam : 'startDate'
      },
      resultUrl  : '/o2/Shop-Order/init?offerId=154855'
    },
    { 
      currentUrl : '/o2/Shop-Order/init?offerId=154855&startDate=20080422&startDate=20080423',
      urlModParams  : {
        removeParam : 'startDate'
      },
      resultUrl  : '/o2/Shop-Order/init?offerId=154855'
    },
    { 
      currentUrl : '/lpReport/2?dates=20080417&logType=all&searchForFrom=&fromUrl=&searchForTo=&toUrl=&category=&accumulate=100&viewMode=month',
      urlModParams  : {
        setParam : 'viewMode=notAggregated'
      },
      resultUrl  : '/lpReport/2?dates=20080417&logType=all&searchForFrom=&fromUrl=&searchForTo=&toUrl=&category=&accumulate=100&viewMode=notAggregated'
    },
    { 
      currentUrl : 'http://www.vg.no?a=1',
      urlModParams  : {
        toggleParam : 'a=1|2'
      },
      resultUrl  : 'http://www.vg.no?a=2'
    },
    {
      currentUrl : 'http://lp1.linkpulse.com/lpReport/2?dates=20080502&logType=all&searchForFrom=&fromUrl=&searchForTo=&toUrl=&category=&accumulate=100&viewMode=month',
      urlModParams : {
        removeParam : "dates,viewMode,logType",
        appendParam : "viewMode=notAggregate,dates=20080502"
      },
      resultUrl  : 'http://lp1.linkpulse.com/lpReport/2?searchForFrom=&fromUrl=&searchForTo=&toUrl=&category=&accumulate=100&viewMode=notAggregate&dates=20080502'
    },
    {
      currentUrl : '/o2cms/Newsletter-Letter/testSend?listId=1314977',
      urlModParams : {
        setMethod : "testSend",
        setParams : ""
      },
      resultUrl  : '/o2cms/Newsletter-Letter/testSend'
    },
    {
      currentUrl : '/o2/Salmon-SalmonPool/listSearchResults?countyInput=17&riverSystemId=1446715&riverId=-1&skip=0',
      urlModParams : {
        setParam  : "skip=10"
      },
      resultUrl  : '/o2/Salmon-SalmonPool/listSearchResults?countyInput=17&riverSystemId=1446715&riverId=-1&skip=10'
    },
    {
      currentUrl : '/o2/Salmon-SalmonPool/listSearchResults',
      urlModParams : {
        setSecure  : 1
      },
      resultUrl  : 'https://' + document.location.href.replace(/^https?:\/\/([^\/]+).*/, "$1") + '/o2/Salmon-SalmonPool/listSearchResults'
    },
    {
      currentUrl : 'http://phoenix.i.bitbit.net/o2/Test/test#page1',
      urlModParams : {
        setParams : 'a=1'
      },
      resultUrl  : 'http://phoenix.i.bitbit.net/o2/Test/test?a=1#page1'
    },
    {
      currentUrl : '/o2/Test/test#page1',
      urlModParams : {
        setParam : 'a=1'
      },
      resultUrl  : '/o2/Test/test?a=1#page1'
    },
    {
      currentUrl : '/o2/Test/test#page1',
      urlModParams : {
        removeParams : '1'
      },
      resultUrl  : '/o2/Test/test#page1'
    }
  )
};

tester.setStartMethod(urlMod.runTests);
