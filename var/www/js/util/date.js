o2.requireJs("jquery");
o2.requireJs("jquery-ui");

var O2_FORMAT_TO_JQUERY_FORMAT = {
  'eee'  : 'D',
  'EEE'  : 'D',
  'MMMM' : 'MM',
  'MMM'  : 'M',
  'MM'   : 'mm',
  'M'    : 'm',
  'yyyy' : 'yy',
  'yy'   : 'y'
};

o2.parseDate = function(o2Format, dateStr) {
  var partsOfFormat = o2Format.match(/e+|M+|y+|[^eMy]+/g);
  var jqueryFormat = "";
  for (var i = 0; i < partsOfFormat.length; i++) {
    var part = partsOfFormat[i];
    jqueryFormat += O2_FORMAT_TO_JQUERY_FORMAT[part] ? O2_FORMAT_TO_JQUERY_FORMAT[part] : part;
  }
  return $.datepicker.parseDate(jqueryFormat, dateStr);
}
