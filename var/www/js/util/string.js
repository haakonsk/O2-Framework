/* This is a split function that works like Perl's. Javascript's split function is strange..!
   If the string doesn't match the regEx, Javascript's split returns an empty array.
   If maxElements is given, it ignores the elements after that number of matches.
   This function corrects those flaws: If the regEx doesn't match, we return an array
   with one element (the original string). If maxElements is given, the last element
   returned is the concatenation of all the elements after maxElements-1 elements.
*/
o2.split = function(regEx, string, maxElements) {
  if (!string) {
    return new Array();
  }
  if (typeof(regEx) !== "function"  &&  typeof(regEx) !== "object") {
    alert("split: regEx parameter is not a regEx, it's of type " + typeof regEx);
    return new Array();
  }
  if (typeof(string) === "number") {
    string = string.toString();
  }
  if (typeof(string) !== "string") {
    alert("split: string parameter is not a string, it's of type " + typeof string);
    return new Array();
  }
  var elements = string.split(regEx);
  if (!elements) {
    return new Array(string);
  }
  if (!maxElements) {
    return elements;
  }
  var newElements = new Array();
  for (var i = 0; i < elements.length; i++) {
    if (i < maxElements) {
      newElements.push( elements[i] );
    }
    else {
      newElements[ newElements.length-1 ] += elements[i];
    }
  }
  return newElements;
}

o2.stripTags = function(string) {
  return string.replace(/<[\w\/][^>]*>/g, "");
}
