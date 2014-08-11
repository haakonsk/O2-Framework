o2.require("/js/cookies.js");

o2.publicSession = {};

o2.publicSession.delete = function() {
  var session = o2.publicSession.getSession();
  o2.deleteCookie( o2.publicSession.getCookiename() );
}

o2.publicSession.getCookiename = function() {
  var href = window.location.href;
  var server = href.substr(7, href.indexOf('/', 7)-7);
  return server + "_session";
}

o2.publicSession.getSession = function() {
  var cookiename = o2.publicSession.getCookiename();
  var cookie = o2.getCookie(cookiename) || "{}";
  eval("session = " + cookie + ";");
  return session;
}

function O2Session() {
  if (!o2.getCookie) {
    return;
  }
  var session = o2.publicSession.getSession();
  for (var key in session) {
    eval("this." + key + " = '" + session[key] + "';");
  }
}

O2Session.prototype.deleteSession = o2.publicSession.delete;

/*
  Usage:
  var session = new O2Session();
  alert(session.hakonTest);
  session.deleteSession();
*/
