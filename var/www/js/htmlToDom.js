// Need this because IE isn't so good with innerHTML :(

o2.htmlToDom = {};

var isIE = navigator.userAgent.indexOf("MSIE") != -1;

o2.htmlToDom.log = function(str, arg2) {
  if (window.console && arg2) {
    console.log(str);
  }
}

// Try to close tags that haven't been closed (keep in sync with o2ml-mode!)
o2.htmlToDom.makeWellFormed = function(html) {
  html = html.replace(/<(br|hr)>\s*<\/\1>/gi, "<$1 />");
  html = html.replace(/<(br|hr)>/gi,          "<$1 />");
  html = html.replace(/<(input|img|link|meta|param)([^>]*[^\/])>\s*<\/\1>/gi, "<$1$2 />");
  html = html.replace(/<(input|img|link|meta|param)([^>]*[^\/])>/gi,          "<$1$2 />");
  return html;
}

o2.htmlToDom.setInnerHtml = function(elm, html) {
  // First extract javascript to be executed:
  var jsAndHtml = o2.htmlToDom.extractJs(html);
  var js = jsAndHtml.js;
  html   = jsAndHtml.html;

  // Then insert the html without the javascript and execute the javascript:
  if (!isIE || !elm.nodeName.match(/^(col|colGroup|frameSet|html|head|style|table|tBody|tFoot|tHead|title|tr|select)$/i) ) { // innerHTML is read-only for these elements in ie!
    elm.innerHTML = html;
    o2.htmlToDom.executeJs(js);
    return;
  }
  while (elm.childNodes.length > 0) {
    elm.removeChild( elm.childNodes[0] );
  }
  o2.htmlToDom.htmlToDom(html, elm);
  o2.htmlToDom.executeJs(js);
}

o2.htmlToDom.extractJs = function(html) {
  var js = "";
  var closingTag = "</script>";
  while (matches = html.match(/<script[^>]*>/mi)) {
    var openingTag = matches[0];
    var startIndex = html.indexOf(openingTag);
    var endIndex   = html.indexOf(closingTag);
    if (startIndex > endIndex) {
      alert("Trouble in o2.htmlToDom.extractJs. Please debug me!");
      break;
    }
    js  += html.substring(startIndex + openingTag.length, endIndex) + "\n";
    html = html.substring(0, startIndex)  +  html.substring(endIndex + closingTag.length);
  }
  return {
    "js"   : js,
    "html" : html
  };
}

o2.htmlToDom.executeJs = function(js) {
  if (js) {
    eval(js);
  }
}

o2.htmlToDom.addInnerHtml = function(elm, html, where) {
  if (where == "before") {
    alert("where == before not implemented");
  }
  else if (where == "after") {
    alert("where == after not implemented");
  }
  else if (where == "top") {
    var divNode = document.createElement("div");
    var jsAndHtml = o2.htmlToDom.extractJs(html);
    var js = jsAndHtml.js;
    html   = jsAndHtml.html;
    o2.htmlToDom.htmlToDom(html, divNode);
    for (var i = 0; i < divNode.childNodes.length; i++) {
      var node = divNode.childNodes[i];
      elm.insertBefore(node, elm.firstChild);
    }
    o2.htmlToDom.executeJs(js);
  }
  else if (where == "bottom") {
    var divNode = document.createElement("div");
    var jsAndHtml = o2.htmlToDom.extractJs(html);
    var js = jsAndHtml.js;
    html   = jsAndHtml.html;
    
    o2.htmlToDom.htmlToDom(html, divNode);
    
    for (var i = 0; i < divNode.childNodes.length; i++) {
      var node = divNode.childNodes[i];
      elm.appendChild(node);
    }
    o2.htmlToDom.executeJs(js);
  }
  else {
    alert("error: unknown value for where: " + where);
  }
}

/* Found this function on the net, had to make quite a few changes */
o2.htmlToDom.htmlToDom = function(str, parent) {
  str = str.replace(/<!--(.|\n|\r)*?-->/g, ""); // Remove all comments
  str = str.replace(/&amp;/g, "&"); // Ampersands will be encoded by appendChild, which we kind of don't want, at least not if it's double encoded, so let's at least make sure they don't get double encoded!
  str = o2.htmlToDom.makeWellFormed(str);
  str = o2.htmlToDom.trim(str);
  var lastIndex = str.length;
  if (!lastIndex) {
    lastIndex=str.length;
  }
  var obj, substr, indentlevel=0, charat=0, tracechar=0, subelstart=0, subelend=0, end=0;
  while (charat < lastIndex) {
    if (str.charAt(charat) == '<') { // element
      end    = str.indexOf('>', charat+1);
      substr = str.substring(charat, end+1);

      switch (str.charAt(charat+1)) {
      case '?':case '!':{
        obj = document.createElement('!'); // XXX Don't think this works
        break;
      }
      default: {
        // var tName=substr.substring(1,substr.length).replace(/[ />].*/,'');
        var spacePos  = substr.indexOf(" ", substr);
        var slashPos  = substr.indexOf("/", substr);
        var endTagPos = substr.indexOf(">", substr);
        var endOfTagnamePosition = substr.length;
        endOfTagnamePosition   =   spacePos  > 0                                       ?   spacePos    :   endOfTagnamePosition;
        endOfTagnamePosition   =   slashPos  > 0 && slashPos  < endOfTagnamePosition   ?   slashPos    :   endOfTagnamePosition;
        endOfTagnamePosition   =   endTagPos > 0 && endTagPos < endOfTagnamePosition   ?   endTagPos   :   endOfTagnamePosition;
        // alert(endOfTagnamePosition);
        var tName = substr.substring(1, endOfTagnamePosition);
        //alert(tName+":"+substr);
        obj = document.createElement(tName);

        // obj=document.createElement(substr.substring(1,substr.length).replace(/[ />].*/,''));
        var parameters = [];
        if (tName.length+3 < substr.length) {
          var paramstr = substr.substring(tName.length+2, substr.length-1);
          if (paramstr.charAt(paramstr.length-1) == '/') {
            paramstr = paramstr.substring(0, paramstr.length-1);
          }
          var i=0, name='', value='', stage=0, inquotes=0, quote = "";
          o2.htmlToDom.log("paramstr: " + paramstr);
          while (i < paramstr.length) {
            switch (stage) {
            case 0:{ // name
              if (paramstr.charAt(i) == '=') {
                stage=1;
              }
              else {
                name += paramstr.charAt(i);
              }
              break;
            }
            case 1:{ // value
              if (i > 0  &&  paramstr.charAt(i-1) == "="  &&  !inquotes  &&  (paramstr.charAt(i) == "'" || paramstr.charAt(i) == '"') ) {
                quote = paramstr.charAt(i);
                o2.htmlToDom.log("quote is " + quote);
              }
              if ( (paramstr.charAt(i)=='"' && quote == '"')  || (paramstr.charAt(i) == "'" && quote == "'") ) {
                inquotes = !inquotes;
                if (value) {
                  name = o2.htmlToDom.trim(name); // name = name.replace(/^\s+|\s+$/, ''); // Trim name
                  o2.htmlToDom.log("name is " + name + ", value is " + value);
                  if (name != '') {
                    if (name == 'class') {
                      obj.className = value;
                      // obj.setAttribute('className', value);
                    }
                    else if (name == 'style') {
                      var styles = value.split(';');
                      for (var cnt = 0; cnt < styles.length; cnt++) {
                        var style = styles[cnt];
                        if (!style) {
                          continue;
                        }
                        var attrAndValue   = style.split(':');
                        var styleName      = o2.htmlToDom.trim( attrAndValue[0] );
                        var styleNameParts = styleName.split('-');
                        if (styleNameParts.length == 2) {
                          styleName = styleNameParts[0] + styleNameParts[1].substring(0,1).toUpperCase() + styleNameParts[1].substring(1);
                        }
                        var styleValue = o2.htmlToDom.trim( attrAndValue[1] );
                        eval("obj.style." + styleName + " = '" + styleValue + "';");
                      }
                    }
                    else if (name.indexOf("on") == 0) { // Name starts with "on" - in other words, we have an event
                      name = name.toLowerCase();
                      var strToEval = "obj." + name + " = function() {" + value + " };";
                      try {
                        eval(strToEval);
                      }
                      catch (e) {
                        alert("htmlToDom (htmlToDom.js): Error evaling:\n  " + strToEval + "\n" + o2.getExceptionMessage(e) + "\n\nhtml is:\n  " + str);
                      }
                    }
                    else {
                      obj.setAttribute(name, value);
                    }
                  }
                }
              }
              else {
                if ((paramstr.charAt(i) == ' ') && !inquotes) { // XXX improve this test!
                  stage = 0;
                  name  = '';
                  value = '';
                }
                else {
                  value += paramstr.charAt(i);
                }
              }
            }
            }
            i++;
          }
          // if(name!='')obj.setAttribute(name,value);
          if (!name.match(/^\s*$/)) {
            if (name == 'class') {
              obj.className = value;
              // obj.setAttribute('className', value);
            }
            else if (name.indexOf("on") == 0) { // Name starts with "on" - in other words, we have an event
              name = name.toLowerCase();
              var strToEval = "obj." + name + " = function() {" + value + " };";
              try {
                eval(strToEval);
              }
              catch (e) {
                alert("htmlToDom (htmlToDom.js): Error evaling:\n  " + strToEval + "\n" + o2.getExceptionMessage(e) + "\n\nhtml is:\n  " + str);
              }
            }
            else {
              try {
                obj.setAttribute(name, value);
              }
              catch (e) {
                alert( 'could not set attribute "' + name + '" to "' + value + "\"\n\nParsing:\n" + str + "\n\n" + o2.getExceptionMessage(e) );
              }
            }
          }
        }
        if (str.charAt(end-1) != '/') { // not self-closing
          indentlevel = 1;
          subelstart  = end+1;
          tracechar   = end;
          while (indentlevel) {
            subelend = str.indexOf('<', tracechar+1);
            end      = str.indexOf('>', subelend+1);
            if (str.charAt(subelend+1) == '/') {
              indentlevel--;
            }
            else if (str.charAt(end-1) != '/') {
              indentlevel++;
            }
            tracechar = end;
          }
          obj = o2.htmlToDom.htmlToDom( str.substring(subelstart, subelend), obj );
        }
      }
      }
      charat = end+1;
    }
    else { // text
      end = str.indexOf('<', charat+1);
      if (end < 1) {
        end = str.length;
      }
      var _str = str.substring(charat, end);
      obj = document.createTextNode(_str);
      charat = end;
    }
    try {
      parent.appendChild(obj);
    }
    catch (e) {
      // ignore
    }
  }
  return parent;
}

o2.htmlToDom.trim = function(str) {
  str = str.replace(/^\s+/, '');
  str = str.replace(/\s+$/, '');
  return str;
}
