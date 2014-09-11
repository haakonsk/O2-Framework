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
  var match;
  var hours   = 0;
  var minutes = 0;
  if (match = o2Format.match(/(H+|m+)(\W)(H+|m+)/i)) { // Catches some time formats, at least...
    var hoursFormat   = match[1];
    var timeSeparator = match[2];
    var minutesFormat = match[3];
    var hoursPos   = o2Format.indexOf( hoursFormat   );
    var minutesPos = o2Format.indexOf( minutesFormat );
    hours   = dateStr.substring( hoursPos,   hoursPos+hoursFormat.length     );
    minutes = dateStr.substring( minutesPos, minutesPos+minutesFormat.length );
    if (!hours.match(/\d+/) || hours.length !== hoursFormat.length || !minutes.match(/\d+/) || minutes.length !== minutesFormat.length) {
      throw "Error in time. Format: " + match[0] + ", " + "value: " + dateStr.substring( hoursPos, hoursPos+match[0].length );
    }
    o2Format = o2Format.replace( match[0], "" );
    o2Format = o2Format.replace( /\W+$/,   "" );
  }

  var partsOfFormat = o2Format.match(/e+|M+|y+|[^eMy]+/g);
  var jqueryFormat = "";

  for (var i = 0; i < partsOfFormat.length; i++) {
    var part = partsOfFormat[i];
    jqueryFormat += O2_FORMAT_TO_JQUERY_FORMAT[part] ? O2_FORMAT_TO_JQUERY_FORMAT[part] : part;
  }
  var date = $.datepicker.parseDate(jqueryFormat, dateStr);
  date.setHours(hours);
  date.setMinutes(minutes);
  return date;
}
