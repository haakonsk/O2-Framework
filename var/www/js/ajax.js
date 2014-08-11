o2.require( "/js/o2escape.js"    );
o2.require( "/js/htmlToDom.js"   );
o2.require( "/js/util/urlMod.js" );

o2.ajax = {};

var ajaxIframeId = "o2ajaxIframe";
var _timeoutHandler     = new Object();
var o2xmlHttpRequest    = new Array();
var o2ActiveAjaxTargets = {};
var O2_AJAX_URLS        = {};
var O2_AJAX_PARAMS      = {};
o2ActiveAjaxTargets.classNames = {};

o2.ajax.addHiddenIframe = function() {
  if (document.getElementById(ajaxIframeId)) {
    return;
  }
  var iframe = document.createElement("iframe");
  iframe.setAttribute("id",   ajaxIframeId);
  iframe.setAttribute("name", ajaxIframeId);
  iframe.setAttribute("onload", "o2.ajax.handleServerResponseIframe();");
  iframe.style.display = "none";
  document.body.appendChild(iframe);
}

function sAjaxCall(params) { // For backward compatibility
  if (window.console) {
    console.warn("Deprecated function sAjaxCall used, use o2.ajax.sCall instead");
  }
  return o2.ajax.sCall(params);
}

function ajaxCall(params, isSynchronous) { // For backward compatibility
  if (window.console) {
    console.warn("Deprecated function ajaxCall used, use o2.ajax.call instead");
  }
  return o2.ajax.call(params, isSynchronous);
}

// Synchronous "ajax" call
o2.ajax.sCall = function(params) {
  return o2.ajax.call(params, true);
}

o2.ajax.call = function(params, isSynchronous) {
  isSynchronous = isSynchronous || false;
  var urlParams = "";

  var timeout = 0;
  if (params.timeout && parseInt(params.timeout) > 0) {
    timeout = parseInt( params.timeout );
  }

  // Make it possible to use css to do something with target, so the user can see that something is going to happen.
  // Setting class=activeAjaxTarget on all targets
  var targets = o2.ajax.getTargetsAsArray( params.target ? params.target.toString() : "" );
  for (var i = 0; i < targets.length; i++) {
    var elm = document.getElementById( targets[i] );
    if (elm) {
      if ( !o2ActiveAjaxTargets.classNames[ targets[i] ] ) {
        o2ActiveAjaxTargets.classNames[ targets[i] ] = 1;
        o2.addClassName(elm, "activeAjaxTarget");
      }
      else {
        o2ActiveAjaxTargets.classNames[ targets[i] ]++;
      }
    }
  }

  var src = params.serverScript;
  src = o2.ajax.removeHash(src);
  if (src && src.indexOf("?") !== -1) {
    var queryString = src.substring( src.indexOf("?")+1 );
    var parameters = queryString.split("&");
    for (var i = 0; i < parameters.length; i++) {
      var paramAndValue = parameters[i].split("=");
      var name  = paramAndValue[0];
      var value = paramAndValue[1];
      urlParams += o2.escape.escape(name) + "=" + o2.escape.escape(value) + "&";
    }
    src = src.substring( 0, src.indexOf("?") );
  }
  else if (!src) {
    // Don't call o2.escape.escape on the param values if urlMod parameters have been used.
    src = o2.urlMod.urlMod(params);
    src = o2.ajax.removeHash(src);
    urlParams = src.match(/\?/) ? src.substring( src.indexOf("?")+1 ) : "";
    if (urlParams) {
      urlParams += "&";
    }
    if (src.indexOf("?") !== -1) {
      src = src.substring( 0, src.indexOf("?") );
    }
  }
  
  if (typeof(params.params) !== "string") {
    var qsp = new Array();
    for (var key in params.params) {
      qsp.push( key + "=" + o2.escape.escape(params.params[key]) );
    }
    params.params = qsp.join("&");
  }

  if (params.params) {
    urlParams += params.params + "&";
  }
  // Escape params:
  for (var key in params) {
    if (key !== "params" &&  typeof(params[key]) !== "function" ) {
      params[key] = o2.escape.escape( params[key] );
    }
  }
  
  var paramsString = o2.ajax.buildQueryString({
    isAjaxRequest       : 1,
    _target             : params.target,
    _where              : params.where,
    onError             : params.onError,
    onSuccess           : params.onSuccess,
    ignoreMissingTarget : params.ignoreMissingTarget,
    debug               : params.debug,
    ajaxId              : params.ajaxCallId,
    errorHandler        : params.errorHandler
  });
  if ( typeof(params.handler) !== "function" ) {
    paramsString += "&" + o2.ajax.buildQueryString({ handler : params.handler });
  }
  var ajaxId = params.ajaxCallId  ||  parseInt( 1000000*Math.random() );
  if (o2xmlHttpRequest[ajaxId]) {
    o2xmlHttpRequest[ajaxId].abort();
    delete o2xmlHttpRequest[ajaxId];
  }
  o2ActiveAjaxTargets[ajaxId] = params.target;
  if (window.XMLHttpRequest) {
    try {
      o2xmlHttpRequest[ajaxId] = new XMLHttpRequest();
    }
    catch (e) {
      delete o2xmlHttpRequest[ajaxId];
    }
  }
  else if (window.ActiveXObject) { // branch for IE/Windows ActiveX version
    try {
      o2xmlHttpRequest[ajaxId] = new ActiveXObject("Msxml2.XMLHTTP");
    }
    catch (e) {
      try {
        o2xmlHttpRequest[ajaxId] = new ActiveXObject("Microsoft.XMLHTTP");
      }
      catch (e) {
        delete o2xmlHttpRequest[ajaxId];
      }
    }
  }
  
  // Saving this in case there's an internal server error and we don't get anything useful back
  O2_AJAX_URLS[   ajaxId ] = src;
  O2_AJAX_PARAMS[ ajaxId ] = params;
  urlParams    = urlParams.replace(/&$/, "");
  paramsString = urlParams + "&" + paramsString;
  paramsString = paramsString.replace(/&$/, "");
  if (urlParams.length + src.length > 2048) { // Browsers support at least 2048 characters in the URL (http://stackoverflow.com/questions/1344616/max-length-of-query-string-in-an-ajax-get-request)
    if (window.console) {
      console.info(src, " - Request too long for GET (" + (urlParams.length + src.length) + "), switching to POST.");
    }
    urlParams = "";
    params.method = "POST";
  }
  
  O2_AJAX_PARAMS[ajaxId] = params;
  var paramsHash = o2.ajax.urlParamsToHash(  paramsString.substring( 0, paramsString.indexOf("isAjaxRequest=") )  );
  for (var key in paramsHash) {
    O2_AJAX_PARAMS[ajaxId][key] = paramsHash[key];
  }
  
  if (o2xmlHttpRequest[ajaxId]) {
    paramsString += "&xmlHttpRequestSupported=1&o2AjaxEncoding=" + o2.escape.getEncoding();
    if (!isSynchronous) {
      o2xmlHttpRequest[ajaxId].onreadystatechange = o2.ajax.handleServerResponseXmlHttp;
    }
    var requestMethod = params.method ? params.method.toUpperCase() : "GET";
    if (requestMethod === "POST") {
      o2xmlHttpRequest[ajaxId].open("POST", src + (urlParams ? "?" + urlParams : ""), !isSynchronous); // Third parameter: true means asynchronous, false is synchronous
      o2xmlHttpRequest[ajaxId].setRequestHeader("Content-type", "application/x-www-form-urlencoded");  // Request looks better in Firebug with this content type
      o2xmlHttpRequest[ajaxId].send(paramsString);
    }
    else if (requestMethod === "GET") {
      o2xmlHttpRequest[ajaxId].open("GET", src + "?" + paramsString, !isSynchronous);                 // Third parameter: true means asynchronous, false is synchronous
      o2xmlHttpRequest[ajaxId].setRequestHeader("Content-type", "application/x-www-form-urlencoded"); // Request looks better in Firebug with this content type
      o2xmlHttpRequest[ajaxId].send();
    }
    else {
      alert("Request method " + requestMethod + " not supported");
      return;
    }
    
    if (isSynchronous) {
      if ( typeof(params.handler) === "function" ) {
        o2xmlHttpRequest[ajaxId].o2AjaxCallbackHandler = params.handler;
      }
      return o2.ajax.parseResponse(ajaxId);
    }
    if (timeout > 0) {
      _timeoutHandler[ajaxId] = params.errorHandler !== null  ?  params.errorHandler  :  "_noErrorHandler_";
      setTimeout("o2.ajax.checkTimeoutOnAjaxId(" + ajaxId + ")", timeout*1000);
    }
    if ( typeof(params.handler) === "function" ) {
      o2xmlHttpRequest[ajaxId].o2AjaxCallbackHandler = params.handler;
    }
  }
  else { // Use a hidden iframe (xmlHttpRequest not supported)
    src += src.indexOf("?") === -1 ? "?" : "&";
    src += paramsString + "&xmlHttpRequestSupported=0";
    document.getElementById(ajaxIframeId).src = src;
  }
}

o2.ajax.buildQueryString = function(hash) {
  var str = "";
  for (var key in hash) {
    var value = hash[key];
    if (typeof(value) === "undefined" || value === null || value === "") {
      continue;
    }
    str += key + "=" + value + "&";
  }
  str = str.substr(0, str.length-1);
  return str;
}

o2.ajax.urlParamsToHash = function(paramsString) {
  paramsString = paramsString.replace(/&$/, ""); // Remove trailing "&"
  
  var params = {};
  
  var valuePairs = paramsString.split("&");
  for (var i = 0; i < valuePairs.length; i++) {
    var pair = valuePairs[i];
    if (!pair) {
      continue;
    }
    var keyAndValue = pair.split("=");
    var key   = keyAndValue[0];
    var value = keyAndValue[1];
    params[key] = value;
  }
  
  return params;
}

o2.ajax.checkTimeoutOnAjaxId = function(ajaxId) {
  if ( _timeoutHandler[ajaxId] !== null &&  o2xmlHttpRequest[ajaxId] !== null && o2xmlHttpRequest[ajaxId].readyState < 4) {
    o2xmlHttpRequest[ajaxId].onreadystatechange = function() {}; // Workaround for mozilla bug
    o2xmlHttpRequest[ajaxId].abort();
    delete o2xmlHttpRequest[ajaxId];

    if (_timeoutHandler[ajaxId] !== "_noErrorHandler_") {
      try {
        var params = O2_AJAX_PARAMS[ajaxId];
        params.result = "timeout";
        eval(_timeoutHandler[ajaxId] + "(params);");
      }
      catch(e) {}
    }
  }
  delete _timeoutHandler[ajaxId];
}

o2.ajax.handleServerResponseXmlHttp = function() {
  // only if o2xmlHttpRequest shows "loaded"
  for (ajaxId in o2xmlHttpRequest) {
    if (o2xmlHttpRequest.hasOwnProperty(ajaxId)) {
      o2.ajax.parseResponse(ajaxId);
    }
  }
}

o2.ajax.parseResponse = function(ajaxId) {
  if (o2xmlHttpRequest[ajaxId] && o2xmlHttpRequest[ajaxId].readyState === 4) {
    // only if "OK"
    if (o2xmlHttpRequest[ajaxId].status === 200) {
      var response = o2xmlHttpRequest[ajaxId].responseText;
      var result;
      try {
        eval(response);
      }
      catch (e) {
        o2.ajax.alert(o2.getExceptionMessage(e) + "\nTried to eval:\n" + response, "o2XmlHttpRequest Error", "error");
        delete o2xmlHttpRequest[ajaxId];
        o2.ajax.removeClassNameActiveAjaxTarget( o2ActiveAjaxTargets[ajaxId] );
        return;
      }
      if (!result) {
        delete o2xmlHttpRequest[ajaxId];
        o2.ajax.removeClassNameActiveAjaxTarget( o2ActiveAjaxTargets[ajaxId] );
        return;
      }
      if ( o2xmlHttpRequest[ajaxId].o2AjaxCallbackHandler ) { // Doing this here to make sure that o2.ajax.handleServerResponse has it
        result.handler = o2xmlHttpRequest[ajaxId].o2AjaxCallbackHandler;
      }
      delete o2xmlHttpRequest[ajaxId]; // Very important that this line comes before o2.ajax.handleServerResponse(result)!
      o2.ajax.handleServerResponse(result);
    }
    else {
      var errorTitle = "There was a problem retrieving the XML data";
      var errorText  = o2xmlHttpRequest[ajaxId].statusText + "\n\n" + o2xmlHttpRequest[ajaxId].responseText;
      if (o2xmlHttpRequest[ajaxId].status === 500) {
        if (errorText.match(/^<!DOCTYPE/) || errorText.match(/^Service Unavailable/)) {
          var matches = errorText.match(/(<div class="errorDetails">(.|\n)+)<\/body>/);
          if (matches) {
            errorText  = "Error with " + O2_AJAX_URLS[ajaxId] + ": " + matches[1];
            errorTitle = "";
          }
          else if (window.console) {
            console.warn("Couldn't parse Internal Server Error:");
            console.log(errorText);
          }
          result = O2_AJAX_PARAMS[ajaxId];
          if (result.errorHandler || result.onError) {
            result.errorHandler = unescape( result.errorHandler || "" );
            result.onError      = unescape( result.onError      || "" );
            result.result       = "error";
            o2.ajax.handleServerResponse(result);
          }
        }
        o2.ajax.alert(errorText, errorTitle, "error", true);
      }
      else if (document.location.href.indexOf("debug") !== -1) {
        o2.ajax.alert(errorText, errorTitle, "error");
      }
      delete o2xmlHttpRequest[ajaxId];
      o2.ajax.removeClassNameActiveAjaxTarget( o2ActiveAjaxTargets[ajaxId] );
      delete o2ActiveAjaxTargets[ajaxId];
    }
    return result;
  }
}

o2.ajax.handleServerResponseIframe = function(response) {
  o2.ajax.handleServerResponse(response);
}

o2.ajax.handleServerResponse = function(result) {
  if (!result) {
    return;
  }
  if (result.debug == "1") {
    var debugString = "DEBUG:\n";
    for (var key in result) {
      debugString += key + " => " + result[key] + "\n";
    }
    o2.ajax.alert(debugString);
  }

  // Error handling
  if (result.result === "error") {
    o2.ajax.removeClassNameActiveAjaxTarget( result._target );
    if (result.errorMsg === "notLoggedIn") {
      return document.location.href = result.loginUrl; // Will cause redirect to login page
    }
    if (result.onError === "ignore") {
      return;
    }
    if (result.onError) {
      eval(result.onError);
    }
    else if (result.errorHandler) {
      try {
        eval(result.errorHandler + "(result);");
      }
      catch (e) {
        o2.ajax.alert( "Error evaluating errorHandler (" + result.errorHandler + "): " + o2.getExceptionMessage(e), result.errorHeader, "error" );
      }
    }
    else if (result.errorMsg && result.onError !== "ignore") {
      o2.ajax.alert(result.errorMsg, result.errorHeader, "error", true);
    }
    else if (result.onError !== "ignore") {
      o2.ajax.alert("An error occurred", result.errorHeader, "error");
    }
    return;
  }

  if (result._html  ||  (result._target && result._where !== "none")) {
    o2.ajax.updateContent({
      target              : result._target || "",
      content             : result._html,
      where               : result._where ? result._where : "replace",
      ignoreMissingTarget : result.ignoreMissingTarget
    });
  }
  else if (result._target && result._where.match(/^delete/)) {
    o2.ajax.updateContent({
      target              : result._target,
      where               : result._where,
      ignoreMissingTarget : result.ignoreMissingTarget
    });
  }

  if (result.handler) {
    if ( typeof(result.handler) === "function" ) {
      result.handler(result);
    }
    else {
      try {
        eval(result.handler + "(result);");
      }
      catch (e) {
        o2.ajax.alert( "Error evaluating ajax handler (" + result.handler + "): " + o2.getExceptionMessage(e), result.errorHeader, "error" );
      }
    }
  }

  if (result.javascriptFiles && result.javascriptFiles.length) {
    for (var i = 0; i < result.javascriptFiles.length; i++) {
      o2.require( result.javascriptFiles[i], function() { o2.ajax.continueHandleServerResponse(result) } );
    }
  }
  else if ((result.javascriptsToExecute && result.javascriptsToExecute.length) || (result.cssFiles && result.cssFiles.length)) {
    o2.ajax.continueHandleServerResponse(result);
  }
  else {
    o2.ajax.handleSuccess(result);
  }
}

o2.ajax.continueHandleServerResponse = function(result) {
  if (result.continueAjaxHandleServerResponseDone) {
    return;
  }
  
  // Dont't continue until all the required JS files have been loaded
  if (result.javascriptFiles) {
    for (var i = 0; i < result.javascriptFiles.length; i++) {
      var url = result.javascriptFiles[i];
      if (!o2.hasBeenRequiredAndLoaded(url)) {
        return;
      }
    }
  }
  result.continueAjaxHandleServerResponseDone = true;

  if (result.javascriptsToExecute) {
    for (var _i = 0; _i < result.javascriptsToExecute.length; _i++) {
      o2.ajax.executeJavascript( result.javascriptsToExecute[_i] );
    }
  }
  o2.ajax.executeOnloadJsWhenAppropriate(result.javascriptsToExecuteOnLoad);
  if (result.cssFiles) {
    for (var i = 0; i < result.cssFiles.length; i++) {
      o2.require( result.cssFiles[i] );
    }
  }
  o2.ajax.handleSuccess(result);
}

o2.ajax.executeOnloadJsWhenAppropriate = function(javascript) {
  var ajaxElm = document.getElementById("_o2AjaxElement");
  if (ajaxElm) {
    if (javascript) {
      o2.ajax.executeJavascript(javascript);
    }
    ajaxElm.parentNode.removeChild(ajaxElm);
    return;
  }
  
  // _o2AjaxElement wasn't found, so the HTML hasn't been fully loaded yet. Try calling this function again in a few milliseconds:
  setTimeout(
    function() {
      o2.ajax.executeOnloadJsWhenAppropriate(javascript);
    },
    50
  );
}

o2.ajax.executeJavascript = function(js) {
  try {
    eval(js);
  }
  catch (e) {
    alert( "Couldn't eval:\n" + js + ":\n\n" + o2.getExceptionMessage(e) );
  }
}

o2.ajax.handleSuccess = function(result) {
  if (result.onSuccess) {
    eval(result.onSuccess);
  }
  o2.ajax.removeClassNameActiveAjaxTarget(result._target);
}

o2.ajax.removeClassNameActiveAjaxTarget = function(target) {  // Target elements should no longer have the className "activeAjaxTarget" (it's not active anymore)
  if (!target) {
    return;
  }
  var targets = o2.ajax.getTargetsAsArray( target.toString() );
  for (var i = 0; i < targets.length; i++) {
    var elm = document.getElementById( targets[i] );
    if (elm) {
      o2ActiveAjaxTargets.classNames[ targets[i] ]--;
      if (o2ActiveAjaxTargets.classNames[ targets[i] ] == 0) {
        o2.removeClassName(elm, "activeAjaxTarget");
      }
    }
  }
}

o2.ajax.getTargetsAsArray = function(targetStr) {
  if (!targetStr) {
    return new Array();
  }
  var targets = targetStr.split(",");
  for (var i = 0; i < targets.length; i++) {
    targets[i] = targets[i].replace(/^\s+/, "");
    targets[i] = targets[i].replace(/\s+$/, "");
  }
  return targets;
}

o2.ajax.updateContent = function(params) {
  var content = params.content;
  var where   = params.where;
  var ids = params.target.toString().split(",");
  for (var i = 0; i < ids.length; i++) {
    var target = ids[i].replace(/^\s+/, "");
    var elm = document.getElementById(target);
    if (!elm) {
      if (!params.ignoreMissingTarget) {
        alert("o2.ajax.updateContent (ajax.js): Target element \"" + target + "\" does not exist");
      }
      continue;
    }
    if (where === "replace") {
      o2.htmlToDom.setInnerHtml(elm, content);
    }
    else if (where === "delete") {
      elm.parentNode.removeChild(elm);
    }
    else if (where === "deleteContent") {
      o2.htmlToDom.setInnerHtml(elm, "");
    }
    else {
      o2.htmlToDom.addInnerHtml(elm, content, where);
    }
  }
}

o2.ajax.isInProgress = function(ajaxId) {
  return o2xmlHttpRequest[ajaxId] ? true : false;
}

o2.ajax.alert = function(msg, title, type, dontEncode) {
  // top.displayMessage may give a permission denied error (!), hence the try/cactch
  var hasTopDisplayMessage;
  try {
    hasTopDisplayMessage = top.displayMessage ? true : false;
  }
  catch (e) {
    hasTopDisplayMessage = false;
  }

  if (!hasTopDisplayMessage) {
    if (navigator.appVersion.toLowerCase().match(/msie 6/)) {
      if (title) {
        msg = title + "\n\n" + msg;
      }
      return alert("Ajax Alert:" + msg);
    }
    var div = document.getElementById("ajaxMessageDiv");
    if (!div) {
      div = o2.ajax.createMessageDiv();
    }
    var html = dontEncode ? msg : "<pre>" + o2.ajax.encodeHtml(msg) + "</pre>";
    if (title) {
      html = "<h1>" + title + "</h1>" + html;
    }
    html += "<p><input type='button' value='OK' id='ajaxMessageDivCloseButton' onClick='document.getElementById(\"ajaxMessageDiv\").style.display = \"none\";'></p>";
    div.innerHTML = html;
    div.style.display = "";
    document.getElementById("ajaxMessageDivCloseButton").focus();
    div.scrollTop = 0;
    return;
  }
  if (type) {
    type = type.toLowerCase();
  }
  if (!type || type === "info") {
    top.displayMessage(msg);
  }
  else if (type === "error") {
    top.displayError(msg);
  }
}

o2.ajax.createMessageDiv = function() {
  var div = document.createElement("div");
  div.id = "ajaxMessageDiv";
  document.body.appendChild(div);
  return div;
}

o2.ajax.encodeHtml = function(html) {
  html = html.replace(/</g, "&lt;");
  html = html.replace(/>/g, "&gt;");
  return html;
}

// IE (and possibly some other browsers) seem to remove the hash character from the url when performing the ajax request,
// causing the url to become unusable... To get around the problem we remove the hash character ourselves AND remove all
// characters following it:
o2.ajax.removeHash = function(str) {
  if (!str) {
    return str;
  }
  var hashPos = str.indexOf("#");
  if (hashPos !== -1) {
    str = str.substring(0, hashPos);
  }
  return str;
}
