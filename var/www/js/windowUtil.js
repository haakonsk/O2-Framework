o2.require("/js/util.js");

/* Returns the (i)frame element that elm is a part of as seen from the (i)frame's parent */
o2.getFrameElement = function(elm) {
  var doc = elm.nodeName === "#document" ? elm : elm.ownerDocument;
  var win = o2.getWindowByDocument(doc); // The window object of the iframe
  if (!win) {
    return null;
  }

  // Find all frames in parent window
  var frames  = new Array();
  var _frames = win.parent.document.getElementsByTagName("frame");
  for (var i = 0; i < _frames.length; i++) {
    frames.push( _frames[i] );
  }
  var iframes = win.parent.document.getElementsByTagName("iframe");
  for (var i = 0; i < iframes.length; i++) {
    frames.push( iframes[i] );
  }

  for (var i = 0; i < frames.length; i++) {
    var frame = frames[i];

    if (frame.contentDocument  &&  o2.getWindowByDocument( frame.contentDocument ) === win) {
      return frame;
    }
    if (frame.contentWindow  &&  frame.contentWindow === win) {
      return frame;
    }
  }
  throw new O2Exception("getFrameElement: Didn't find frame");
}

// This code throws security exception when trying to access iframes with content from other domains
o2.getWindowByDocument = function(doc) {
  if (!doc) {
    return alert("getWindowByDocument: document missing");
  }
  try {
    if (document.domain != doc.domain) {
      return null;
    }
  }
  catch (e) {
    return null;
  }       
  var win = doc.defaultView || doc.parentWindow;

  if (!win) {
    return alert("Browser doesn't support defaultView or parentWindow");
  }
  return win;
}

// The distance (in pixels) from the top of the current frame down to where the frame comes into view in the browser,
// the part not visible due to scrolling.
o2.getFrameTopToVisibleFrameTopOffset = function(win) {
  if (win === top.window) {
    return $(win.document).scrollTop();
  }
  var frameElm = o2.getFrameElement(win.document);
  return o2.getFrameTopToVisibleFrameTopOffset(win.parent) + $(win.document).scrollTop() - (frameElm.tagName.toLowerCase() === "frame" ? 0 : $(frameElm).offset().top);
}
