o2.flexigrid = o2.flexigrid || {};

o2.flexigrid.init = function() {
  $(".flexigrid").each(function() {
    var table = $(this);
    if (table.hasClass("flexigridInitialized")) {
      return;
    }
    table.addClass("flexigridInitialized");
    // Fix to make table headers the same width as content cells
    table.find("th").each(function() {
      $(this).attr("width", $(this).width());
    });
    // Need to delay flexigrid call, or else the grid won't load correctly
    setTimeout(
      function() {
        // Make into flexigrid
        table.flexigrid({
          height: "auto"
        });
      },
      1000
    );
  });
}

o2.flexigrid.fixRow = function(id) {
  var row     = $("#" + id);
  var headers = $(".flexigrid").find("thead tr th div");
  var columnWidths = [];
  for (var i = 0; i < headers.length; i++) {
    columnWidths.push( $( headers[i] ).css("width") );
  }
  var cells = row.find("td");
  for (var i = 0; i < cells.length; i++) {
    o2.flexigrid.fixCell( $( cells[i] ), columnWidths[i] );
  }
}

o2.flexigrid.fixCell = function(cell, width) {
  cell.html( "<div style='width: " + width + "'>" + cell.html() + "</div>" );
}

o2.flexigrid.setCellContent = function(cell, content) {
  cell.find("div").html(content);
}
