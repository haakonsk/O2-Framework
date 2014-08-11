var o2 = {
  version : _o2Version,
};

var LOADING_JS_FILES = new Array();

// Can require both javascript and css files.
o2.require = function(url, onLoadCallback, isJson) {
  var urlWithoutVersion = o2.getUrlWithoutVersion(url);
  var urlWithVersion    = o2.getUrlWithVersion(urlWithoutVersion);
  if (!window.includedUrls) {
    window.includedUrls = new Array();
  }
  if (o2.hasBeenRequired(urlWithoutVersion)) {
    o2._executeRequireCallback(onLoadCallback, urlWithoutVersion);
    return;
  }

  var newNode;
  if (urlWithoutVersion.match(/\.css([?]|$)/i)) { // It's a css file
    if (!o2._validateBrowser(urlWithoutVersion)) {
      return;
    }
    newNode = document.createElement("link");
    newNode.setAttribute( "rel",  "stylesheet"   );
    newNode.setAttribute( "type", "text/css"     );
    newNode.setAttribute( "href", urlWithVersion );
    document.getElementsByTagName("head").item(0).appendChild(newNode);
  }
  else if (isJson) {
    LOADING_JS_FILES[urlWithoutVersion] = true;
    o2._getUrlWithAjax(urlWithoutVersion, onLoadCallback);
  }
  else { // Let's just assume it's a javascript file
    LOADING_JS_FILES[urlWithoutVersion] = true;
    var newNode = document.createElement("script");
    newNode.onreadystatechange = function() { // IE
      if (newNode.readyState === "complete" || newNode.readyState === "loaded") {
        delete LOADING_JS_FILES[urlWithoutVersion];
        o2._executeRequireCallback(onLoadCallback, url);
      }
    };
    newNode.onload = function() { // Firefox
      delete LOADING_JS_FILES[urlWithoutVersion];
      o2._executeRequireCallback(onLoadCallback, url);
    }
    newNode.onerror = function(e) {
      console.warn("Failed to load " + url);
    }
    newNode.setAttribute( "type", "text/javascript" );
    newNode.setAttribute( "src",  urlWithVersion    );
    document.getElementsByTagName("head").item(0).appendChild(newNode);
  }
  includedUrls[urlWithoutVersion] = true;
  if (o2.isJqueryUrl(urlWithoutVersion)) {
    includedUrls.jquery = true;
  }
  else if (o2.isJqueryUiUrl(urlWithoutVersion)) {
    includedUrls.jqueryUi = true;
  }
}

o2.requireJs = function(file, onLoadCallback) {
  o2._requireJsOrCss("js", file, onLoadCallback);
}

o2.requireJson = function(file, onLoadCallback) {
  o2._requireJsOrCss("json", file, onLoadCallback);
}

o2.requireCss = function(file, onLoadCallback) {
  o2._requireJsOrCss("css", file, onLoadCallback);
}

o2._requireJsOrCss = function(type, file, onLoadCallback) {
  if (file.match(/^\//)) { // Starts with a slash
    return o2.require(file, onLoadCallback);
  }

  var isJson = type === "json";
  if (isJson) {
    type = "js";
  }
  var url = "/" + type + "/" + file + "." + type;
  return o2.require(url, onLoadCallback, isJson);
}

/* Inspired by: http://www.hunlock.com/blogs/Howto_Dynamically_Insert_Javascript_And_CSS */
o2._getUrlWithAjax = function(url, callback) {
  var xmlHttp = o2._getXmlHttpRequest();
  if (!xmlHttp) {
    return false;
  }
  xmlHttp.onreadystatechange = function() {
    if (xmlHttp.readyState == 4) {
      if (xmlHttp.status == 200) {
        var jsCode = xmlHttp.responseText;
        eval(jsCode);
        delete LOADING_JS_FILES[url];
        o2._executeRequireCallback(callback, url);
      }
      delete xmlHttp;
    }
  }
  xmlHttp.open("GET", url + '?timestamp=' + (new Date()).getTime(), true);
  xmlHttp.send();
  return true;
}

o2.hasBeenRequired = function(url) {
  var urlWithoutVersion = o2.getUrlWithoutVersion(url);
  if (o2.isJqueryUrl(urlWithoutVersion)) {
    return includedUrls.jquery;
  }
  if (o2.isJqueryUiUrl(urlWithoutVersion)) {
    return includedUrls.jqueryUi;
  }
  return includedUrls[urlWithoutVersion];
}

o2.isJqueryUrl = function(url) {
  return url.match(/\bjquery(-\d+[.]\d+[.]\d+)?([.]min)?[.]js\b/);
}

o2.isJqueryUiUrl = function(url) {
  return url.match(/\bjquery-ui(-\d+[.]\d+[.]\d+)?([.]\w+)?([.]min)?[.]js\b/);
}

o2.hasBeenRequiredAndLoaded = function(url) {
  var urlWithoutVersion = o2.getUrlWithoutVersion(url);
  return o2.hasBeenRequired(urlWithoutVersion) && !LOADING_JS_FILES[urlWithoutVersion];
}

o2._executeRequireCallback = function(onLoadCallback, url) {
  if (onLoadCallback) {
    onLoadCallback.call(this, url);
  }
}

o2.allRequiredJsFilesLoaded = function() {
  var count = 0;
  for (var key in LOADING_JS_FILES) {
    return false;
  }
  return true;
}

o2._getXmlHttpRequest = function() {
  var xmlHttp;
  if (window.XMLHttpRequest) {
    xmlHttp = new XMLHttpRequest();
  }
  else if (window.ActiveXObject) { // branch for IE/Windows ActiveX version
    try {
      xmlHttp = new ActiveXObject("Msxml2.XMLHTTP");
    }
    catch (e) {
      xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
    }
  }
  return xmlHttp;
}

o2._validateBrowser = function(url) {
  if (url.match(/^[^.]+[.]css$/)) {
    return true;
  }
  var userAgent = navigator.userAgent.toLowerCase();
  var isIe      = userAgent.indexOf("msie")  !== -1  &&  userAgent.indexOf("opera") === -1  &&  userAgent.indexOf("webtv") === -1;
  if (!isIe) {
    return false;
  }
  var allowedIeVersion = url.replace(/^.*[.]ie(\d*)[.]css$/, "$1");
  if (!allowedIeVersion) {
    return true;
  }
  var ieVersion = parseFloat( userAgent.replace(/^.*msie ([\d.]+).*$/, "$1") );
  return parseFloat(allowedIeVersion) === ieVersion;
}

o2.getUrlWithVersion = function(url) {
  if (url.match(/[&?]v=\d+/)) {
    return url; // Already contains version (v) attribute
  }
  var urlWithoutVersion = o2.getUrlWithoutVersion(url);
  return urlWithoutVersion + (urlWithoutVersion.match(/[?]/) ? "&" : "?") + "v=" + o2.version;
}

o2.getUrlWithoutVersion = function(url) {
  return url.replace(/([&?])v=\d+(&|$)/, "$1").replace(/[?]$/, ""); // Remove v (version) attribute from url
}
