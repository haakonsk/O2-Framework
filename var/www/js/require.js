var o2 = {
  version : _o2Version,
};

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
  else {
    $.ajaxSetup({async:false});
    if (isJson) {
      $.getScript(urlWithoutVersion);
    }
    else { // Let's just assume it's a javascript file
      $.getScript(url);
    }
    $.ajaxSetup({async:true});
    includedUrls[urlWithoutVersion] = true;
  }
  if (o2.isJqueryUrl(urlWithoutVersion)) {
    includedUrls.jquery = true;
  }
  else if (o2.isJqueryUiUrl(urlWithoutVersion)) {
    includedUrls.jqueryUi = true;
  }
  o2._executeRequireCallback(onLoadCallback, url);
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
  return o2.hasBeenRequired(urlWithoutVersion);
}

o2._executeRequireCallback = function(onLoadCallback, url) {
  if (onLoadCallback) {
    onLoadCallback.call(this, url);
  }
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
  if (url.match(/^[^.]+([.]min)?[.]css$/)) {
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
