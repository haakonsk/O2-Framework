o2.dateSelect = {

  setupDateSelects : {}, // Keys are ID of dateSelects that are set up.

  setupDatePickerDateSelect : function(id, format, minDate, maxDate) {
    var elm = $("#" + id);
    if (elm.length === 0 || o2.dateSelect.dateSelectIsSetup(id)) {
      return;
    }
    elm.datepicker({
      dateFormat : format,
      minDate    : minDate,
      maxDate    : maxDate
    });
    o2.dateSelect.setupDateSelects[id] = true;
  },

  dateSelectIsSetup : function(id) {
    return o2.dateSelect.setupDateSelects[id] || false;
  }
};
