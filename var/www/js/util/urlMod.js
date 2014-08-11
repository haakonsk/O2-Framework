/* Translation of Perl module O2::Util::UrlMod

   Usage:
     var newUrl = o2.urlMod.urlMod({
       "setMethod" : "myMethod",
       "setParam"  : "a=1"
     });

   The parameters are the same as in Perl.
*/

o2.require("/js/util/string.js");

o2.urlMod = {

  // May be used for testing
  setCurrentUrl : function(url) {
    o2.urlMod.currentUrl = url;
  },

  getCurrentUrl : function() {
    return o2.urlMod.currentUrl || document.location.href;
  },

  getQueryString : function() {
    var matches = o2.urlMod.getCurrentUrl().match(/[?]([^#]*)/);
    return matches ? matches[1] : "";
  },

  getParam : function(param) {
    return o2.urlMod.queryStringGetParam( o2.urlMod.getQueryString(), param );
  },

  // Returns the hash part of the url
  getHash : function() {
    var matches = o2.urlMod.getCurrentUrl().match(/[#](.*)$/);
    return matches ? matches[1] : "";
  },

  urlMod : function(params) {
    params = params || {};
    var currentUrl = o2.urlMod.getCurrentUrl().replace(/^https?:\/\/[^\/?]+/, ""); // Stripping away the protocol and server name
    if (params.setDispatcherPath || params.setClass || params.setMethod) {
      var matches = currentUrl.match(/^\/(\w+)\/([-\w:]+)(\/([^?]*))?([?]([^#]+))?(#(.*))?$/);
      if (matches) {
        var preSlash    = matches[1] || "";
        var module      = matches[2] || "";
        var method      = matches[4] || "";
        var queryString = matches[6] || "";
        var hash        = matches[8] || "";
        return o2.urlMod.buildO2Url(preSlash, module, method, queryString, hash, params);
      }
      if (currentUrl.match(/^\/o2cms\/?$/)) {
        return o2.urlMod.buildO2Url("o2cms", "", "", "", "", params);
      }
      if (!params.setDispatcherPath) {
        alert("Missing setDispatcherPath attribute");
      }
      var queryString = o2.urlMod.getQueryString();
      return o2.urlMod.buildO2Url(params.setDispatcherPath, "", "", queryString, "", params);
    }
    // A regular url (not necessarily o2-url)
    var items = o2.split(/[?#]/, o2.urlMod.getCurrentUrl(), 2);
    var baseUrl     = items[0];
    var queryString = o2.urlMod.getQueryString();
    var newQueryString = o2.urlMod.updateQueryString(queryString, params);
    var url = baseUrl;
    if (newQueryString) {
      url += "?" + newQueryString;
    }
    var hash = o2.urlMod.getHash();
    var newHash = o2.urlMod.updateHash(hash, params);
    if (newHash) {
      url += "#" + newHash;
    }
    if (params.absoluteURL || params.hasOwnProperty("setSecure")) {
      url = o2.urlMod.getProtocol(params) + "://" + o2.urlMod.getHost() + url;
    }
    return url;
  },

  buildO2Url : function(preSlash, module, method, queryString, hash, params) {
    preSlash = params.setDispatcherPath || preSlash;
    module   = params.setClass          || module;
    module   = module.replace(/::/, "-");
    method   = params.setMethod         || method;
    queryString = o2.urlMod.updateQueryString( queryString, params );
    hash        = o2.urlMod.updateHash(        hash,        params )
    var newUrl = "/" + preSlash + "/" + module + "/" + method;
    if (queryString) {
      newUrl += "?" + queryString;
    }
    if (hash) {
      newUrl += "#" + hash;
    }
    if (params.absoluteURL || params.hasOwnProperty("setSecure")) {
      newUrl = o2.urlMod.getProtocol(params) + "://" + o2.urlMod.getHost() + newUrl;
    }
    return newUrl;
  },

  getHost : function() {
    var currentUrl = o2.urlMod.getCurrentUrl();
    var matches = currentUrl.match(/^https?:\/\/([^\/?]+)/);
    if (matches) {
      return matches[1];
    }
    return document.location.href.replace(/^https?:\/\/([^\/?]+).*/, "$1");
  },

  updateQueryString : function(queryString, params) {
    if (params.removeParams) {
      return "";
    }
    if (params.removeParam) {
      queryString = o2.urlMod.updateQueryStringFromRemoveParam(queryString, params.removeParam);
    }
    if (typeof(params.setParams) === "string") {
      queryString = params.setParams;
    }
    if (typeof(params.setParams) !== "string" && typeof(params.setParams) !== "undefined") {
      var qsp = new Array();
      for (var key in params.setParams) {
        var value = params.setParams[key];
        if (value instanceof Array) {
          if (value.length === 0) {
            qsp.push( key + "[]=" );
          }
          for (var i = 0; i < value.length; i++) {
            var arrayValue = value[i];
            if (arrayValue) {
              arrayValue = o2.escape.escape( arrayValue.toString() );
            }
            qsp.push( key + "[]=" + arrayValue );
          }
        }
        else if (value instanceof Object) {
          qsp.push( key + "{}=" + JSON.stringify(value) );
        }
        else {
          if (typeof(value) === "undefined" || value === null || value.length === 0) {
            value = "";
          }
          else if (value) {
            value = o2.escape.escape( value.toString() );
          }
          qsp.push( key + "=" + value );
        }
      }
      queryString = qsp.join("&");
    }
    if (params.setParam) {
      queryString = o2.urlMod.updateQueryStringFromSetParam(queryString, params.setParam);
    }
    if (params.appendParam) {
      queryString = o2.urlMod.updateQueryStringFromAppendParam(queryString, params.appendParam);
    }
    if (params.toggleParam) {
      queryString = o2.urlMod.updateQueryStringFromToggleParam(queryString, params.toggleParam);
    }
    queryString = queryString ? queryString.replace(/^&/, "") : "";
    return queryString;
  },

  updateHash : function(hash, params) {
    if (params.removeHash) {
      return "";
    }
    if (params.setHash) {
      return params.setHash;
    }
    return hash;
  },

  parseParams : function(paramsStr) {
    var params = o2.split(/&/, paramsStr);
    var paramsHash = {};
    for (var i = 0; i < params.length; i++) {
      var param = params[i];
      var keyAndValue = o2.split(/=/, params[i], 2);
      var key   = keyAndValue[0];
      var value = keyAndValue[1];
      params.key = value;
    }
    return paramsHash;
  },

  replaceQueryStringParam : function(queryString, param, value) {
    if (o2.urlMod.queryStringParamExists(queryString, param)) {
      var regEx = new RegExp("(^|&)" + param + "=.*?(&|$)");
      return queryString.replace(regEx, "$1" + param + "=" + value + "$2");
    }
    return o2.urlMod.appendQueryStringParam(queryString, param, value);
  },

  appendQueryStringParam : function(queryString, param, value) {
    if (queryString) {
      queryString += '&';
    }
    queryString += param + "=" + value;
    return queryString;
  },

  queryStringParamExists : function(queryString, param) {
    var regEx = new RegExp("(^|&)" + param + "=(.*?)(&|$)");
    return regEx.test(queryString);
  },

  queryStringGetParam : function(queryString, param) {
    var regEx = new RegExp("(^|&)" + param + "=(.*?)(&|$)");
    var matches = regEx.exec(queryString);
    if (matches) {
      return matches[2];
    }
    return null;
  },

  deleteQueryStringParam : function(queryString, param) {
    var regEx = new RegExp("(^|&)" + param + "=[^&]*", ["g"]);
    return queryString.replace(regEx, "");
  },

  getProtocol : function(params) {
    if (params.setSecure) {
      return "https";
    }
    if (params.hasOwnProperty("setSecure") && !params.setSecure) {
      return "http";
    }
    
    var currentUrl = o2.urlMod.getCurrentUrl();
    var matches = currentUrl.match(/^(\w+):/);
    if (matches) {
      return matches[1];
    }
    return "http";
  },

  updateQueryStringFromRemoveParam : function(queryString, removeParam) {
    var removeParams = o2.split(/,/, removeParam);
    for (var i = 0; i < removeParams.length; i++) {
      queryString = o2.urlMod.deleteQueryStringParam(queryString, removeParams[i]);
    }
    return queryString;
  },

  updateQueryStringFromSetParam : function(queryString, setParam) {
    var params = o2.split(/,/, setParam);
    for (var i = 0; i < params.length; i++) {
      var keyAndValue = o2.split(/=/, params[i], 2);
      var key   = keyAndValue[0];
      var value = keyAndValue[1];
      queryString = o2.urlMod.replaceQueryStringParam(queryString, key, value);
    }
    return queryString;
  },

  updateQueryStringFromAppendParam : function(queryString, setParam) {
    var params = o2.split(/,/, setParam);
    for (var i = 0; i < params.length; i++) {
      var keyAndValue = o2.split(/=/, params[i], 2);
      var key   = keyAndValue[0];
      var value = keyAndValue[1];
      queryString = o2.urlMod.appendQueryStringParam(queryString, key, value);
    }
    return queryString;
  },

  // Example: toggleParam => a=1|2|3,b=4|5|6
  updateQueryStringFromToggleParam : function(queryString, toggleParams) {
    queryString = queryString || "";
    var toggles = o2.split(/,\s*/, toggleParams);
    for (var i = 0; i < toggles.length; i++) {
      var keyAndValue = o2.split(/=/, toggles[i], 2);
      var key    = keyAndValue[0];
      var values = keyAndValue[1];
      var values = o2.split(/\|/, values);
      var hashValues = {};
      var oldValue = o2.urlMod.queryStringGetParam(queryString, key);
      if (oldValue) {
        // arrange so e.g when toggle values is 0|1|2, toggle sequence should be like this 
        // value : toggle to value
        //  0 : 1
        //  1 : 2
        //  2 : 0
        var value;
        var firstToggleValue = values[0];
        for (var j = 0; j < values.length; j++) {
          if (oldValue === values[j]  &&  j < values.length) {
            value = values[j+1];
          }
        }
        if (!value) {
          value = firstToggleValue;
        }
        queryString = o2.urlMod.replaceQueryStringParam(queryString, key, value);
      }
      else {
        queryString = o2.urlMod.replaceQueryStringParam(queryString, key, values[0]);
      }
    }
    return queryString;
  },

  goToUrl : function(url, frameId) {
    if (url.length <= 1000) {
      if (frameId) {
        document.getElementById(frameId).src = url;
        return;
      }
      document.location.href = url;
      return;
    }
    // Url might be too long for get-request, use post instead.
    // Create a form with the parameters from the url, and submit it.
    var currentUrl = o2.urlMod.getCurrentUrl();
    o2.urlMod.setCurrentUrl(url);
    var form = document.createElement("form");
    form.setAttribute( "method", "post"                                                                   );
    form.setAttribute( "action", url.indexOf("?") !== -1  ?  url.substring( 0, url.indexOf("?") )  :  url );
    if (frameId) {
      form.setAttribute("target", frameId);
    }
    var params = o2.urlMod.getQueryString().split("&");
    for (var i = 0; i < params.length; i++) {
      var parts = o2.split(/=/, params[i], 2);
      var key   = parts[0];
      var value = parts[1];
      var hidden = document.createElement("input");
      hidden.setAttribute( "type",  "hidden"      );
      hidden.setAttribute( "name",  key           );
      hidden.setAttribute( "value", escape(value) );
      form.appendChild(hidden);
    }
    document.body.appendChild(form);
    form.submit();
    if (frameId) {
      o2.urlMod.setCurrentUrl(currentUrl);
      document.body.removeChild(form);
    }
  }

};
