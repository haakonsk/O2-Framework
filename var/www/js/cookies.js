// Usage: var myCookieValue = o2.getCookie('cookieName');
o2.getCookie = function(cookieName) {
  var search = cookieName + "=";
  if (document.cookie.length > 0) { // if there are any cookies
    offset = document.cookie.indexOf(search);
    if (offset != -1) { // if cookie exists
      offset += search.length;                    // set index of beginning of value
      end = document.cookie.indexOf(";", offset); // set index of end of cookie value
      if (end == -1) {
        end = document.cookie.length;
      }
      return o2.escape.unescape( document.cookie.substring(offset, end) );
    }
    else {
      console.warn("Didn't find cookie " + cookieName);
    }
  }
}

// name - name of the cookie
// value - value of the cookie
// [expires] - expiration date of the cookie (defaults to end of current session)
// [path] - path for which the cookie is valid (defaults to path of calling document)
// [domain] - domain for which the cookie is valid (defaults to domain of calling document)
// [secure] - Boolean value indicating if the cookie transmission requires a secure transmission
// * an argument defaults when it is assigned null as a placeholder
// * a null placeholder is not required for trailing omitted arguments
o2.setCookie = function(name, value, expires, path, domain, secure) {
  var curCookie
    = name + "=" + o2.escape.escape(value)
    + (expires ? "; expires=" + expires.toGMTString() : "")
    + (path    ? "; path="    + path                  : "")
    + (domain  ? "; domain="  + domain                : "")
    + (secure  ? "; secure"                           : "")
    ;
  document.cookie = curCookie;
}

// name - name of the cookie
// [path] - path of the cookie (must be same as path used to create cookie)
// [domain] - domain of the cookie (must be same as domain used to create cookie)
// * path and domain default if assigned null or omitted if no explicit argument proceeds
o2.deleteCookie = function(name, path, domain) {
  if (o2.getCookie(name)) {
    document.cookie
      = name + "="
      + (path   ? "; path="   + path   : "")
      + (domain ? "; domain=" + domain : "")
      + "; expires=Thu, 01-Jan-70 00:00:01 GMT"
      ;
  }
}
