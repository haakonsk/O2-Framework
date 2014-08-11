o2.perlDump = function(obj) {
  if (obj == null) {
    return "undef";
  }
  switch (typeof obj) {
    case("string"):
      return "'" + ((obj.indexOf("'") >= 0) ? obj.replace(/'/g, "\\'") : obj) + "'"; // '
    case("object"): 
      if (!o2.isHash(obj) && obj.constructor == Array) {
        var str = "[";
        for (var i = 0; i < obj.length; i++) {
          if (i != 0) {
            str += ",";
          }
          str += o2.perlDump( obj[i] );
        }
        return str + "]";
      }
      else {  // hash or object
        var str = "{";
        for (var key in obj) {
          if (str != "{") {
            str += ",";
          }
          str += o2.perlDump(key) + "=>" + o2.perlDump( obj[key] );
        }
        return str + "}";
      }
    default: return obj;
  }
}

o2.dump = function(obj) {
  if (obj == null) {
    return "null";
  }
  switch (typeof obj) {
    case("string"):
      return "'" + ((obj.indexOf("'") >= 0) ? obj.replace(/'/g, "\\'") : obj) + "'"; // '
    case("object"): 
      if (!o2.isHash(obj) && obj.constructor == Array) {
        var str = "[";
        for (var i = 0; i < obj.length; i++ ) {
          if (i != 0) {
            str += ",";
          }
          str += o2.dump( obj[i] );
        }
        return str + "]";
      }
      else {  // hash or object
        var str = "{";
        for (var key in obj) {
          if (str != "{") {
            str += ",";
          }
          str += o2.dump(key) + ":" + o2.dump( obj[key] );
        }
        return str + "}";
      }
    default: return obj;
  }
}

o2.formattedDump = function(obj, level) {
  if (obj == null) {
    return "null";
  }
  if (level == null) {
    level = 0;
  }
  
  var spaces = "";
  for (var i = 0; i < level; i++) {
    spaces += "\t";
  }
  
  switch (typeof obj) {
    case("string"):
      return "'" + ((obj.indexOf("'") >= 0) ? obj.replace(/'/g, "\\'") : obj) + "'"; // '
    case("object"): 
      if (!o2.isHash(obj) && obj.constructor == Array) {
        var str = "[\n";
        for (var i=0; i<obj.length; i++) {
          if (i != 0) {
            str += ",\n";
          }
          str += o2.formattedDump( obj[i], level+1 );
        }
        return str + "\n" + spaces + "]";
      }
      else {  // hash or object
        var str = "{\n";
        for (var key in obj) {
          if (str != "{\n") {
            str += ",\n";
          }
          str += spaces + o2.formattedDump(key, level+1) + ":" + o2.formattedDump( obj[key], level+1 );
        }
        return str + "\n" + spaces + "}";
      }
    default: return obj;
  }
}

o2.dumpXml = function(obj) {
  if (obj == null) {
    return "<null/>";
  }
  switch( typeof obj ) {
    case("string"):
      return obj;
    case("object"): 
      if (!o2.isHash(obj) && obj.constructor == Array) {
        var str = "<array>";
        for (var i = 0; i < obj.length; i++) {
          str += "<item>" + o2.dumpXml( obj[i] ) + "</item>";
        }
        return str+"</array>";
      }
      else {  // hash or object
        var str = "<hash>";
        for (var key in obj) {
          str += "<item>" + key + "</item><item>" + o2.dumpXml( obj[key] ) + "</item>";
        }
        return str + "</hash>";
      }
    default: return obj;
  }
}

o2.isHash = function(obj) {
  if (typeof obj == "object" && obj.length == 0) {
    try {
      for (var key in obj) {
        return true;
      }
    }
    catch(e) {
      return false;
    }
    return false;
  }
  return false;
}

o2.cloneObject = function(obj) {
  if (typeof(obj) != "object") {
    return obj;
  }
  if (obj == null) {
    return obj;
  }
  var nObj = new Object();
  for (var i in obj) {
    nObj[i] = o2.cloneObject( obj[i] );
  }
  return nObj;
}
