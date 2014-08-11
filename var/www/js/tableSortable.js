/*
   Can sort tables and "pseudo-tables". Sorting is done by clicking on a column header.

   <table class="sortable">
     <tr>
       <th>Header 1<th>
       ...
     </tr>
     <tr>
       <td>Some content</td>
       ...
     </tr>
     ...
   </table>
   created with divs instead of table and tr and span instead of td.

   <div class="sortableColumns">
     <div>
       <span>Header 1</span>
       ...
     </div>
     <div class="row">
       <span class="cell">Some content</span>
       ...
     </div
     ...
   </div>


   class="noSort" on a header cell, disables sorting of that column.
   class="sortbottom" on a row, makes those rows get sorted separately, at the bottom of the table.

   It's possible to add a callback function that will be executed every time a sort is performed.
   Arguments to the callback function will be the header cell that was clicked, the sort direction
   (ASC or DESC) and the sort type (numeric, string, date, ...)

   Default arrow styles at /css/tableSortable.css.
*/

o2.tableSorter = {

  sortColumnIndex  : null,
  sortDirection    : "ASC",
  callbackFunction : null,

  init : function() {
    // Find all tables with class sortable and make them sortable
    if (!document.getElementsByTagName) {
      return;
    }
    var tables = document.getElementsByTagName("table");
    for (i = 0; i < tables.length; i++) {
      table = tables[i];
      if (o2.hasClassName(table, "sortable")) {
        o2.tableSorter.makeSortable(table);
      }
    }
    tables = document.getElementsByTagName("div");
    for (i = 0; i < tables.length; i++) {
      table = tables[i];
      if (o2.hasClassName(table, "sortableColumns")) {
        o2.tableSorter.makeSortable(table);
      }
    }
  },

  addCallback : function(callbackFunction) {
    o2.tableSorter.callbackFunction = callbackFunction;
  },

  makeSortable : function(table) {
    var firstRow = o2.tableSorter.getFirstRow(table);
    if (!firstRow) {
      throw new O2Exception("makeSortable: Couldn't find first row");
      // return; // alert("o2.tableSorter.makeSortableDiv: Couldn't find first row");
    }

    // Add event and className to all headers without a "noSort" class:
    var headerCells = o2.tableSorter.getCells(firstRow);
    for (var i = 0; i < headerCells.length; i++) {
      var cell = headerCells[i];
      if (!o2.hasClassName(cell, "nosort") && !o2.hasClassName(cell, "noSort")) {
        o2.addEvent(cell, "click", o2.tableSorter.resortTable);
        o2.addClassName(cell, "sortableColumn");
      }
    }
  },

  getInnerText : function(el) {
    if (typeof el == "string") {
      return el;
    }
    if (typeof el == "undefined") {
      return el;
    }
    if (el.innerText) {
      return el.innerText; // Not needed but it is faster
    }
    var str = "";
    var cs = el.childNodes;
    var l = cs.length;
    for (var i = 0; i < l; i++) {
      switch (cs[i].nodeType) {
        case 1: str += o2.tableSorter.getInnerText( cs[i] ); break; // ELEMENT_NODE
        case 3: str += cs[i].nodeValue;                     break; // TEXT_NODE
      }
    }
    return str;
  },

  resortTable : function(e) {
    var header = e.getTarget();
    if (!header.nodeName.match(/^t[hd]$/i)  &&  !o2.hasClassName(header, "cell")) {
      return;
    }
    var columnIndex = o2.tableSorter.getCellIndex( header );
    var table       = o2.tableSorter.getTable(     header );
    var rows        = o2.tableSorter.getRows(      table );

    // Work out a type for the column
    if (rows.length <= 1) {
      return;
    }
    var item = o2.tableSorter.getInnerText( o2.tableSorter.getCellByRowAndIndex(rows[1], columnIndex) );
    sortfn = o2.tableSorter.sort_caseinsensitive;
    o2.tableSorter.sortType = "string";
    if ((header.getAttribute("sortType") && header.getAttribute("sortType").toLowerCase() === "numeric") || item.match(/^[\d\. ]+$/)  ||  item.match(/^[\d \.]+,[\d]+$/)) {
      o2.tableSorter.sortType = "numeric";
      sortfn = o2.tableSorter.sort_numeric;
    }
    if (item.match(/^\d{2}[\.\/-]\d{2}[\.\/-]\d{4}$/)) {
      o2.tableSorter.sortType = "date";
      sortfn = o2.tableSorter.sort_date;
    }
    if (item.match(/^\d{2} \w{3} \d{4}$/)) {
      o2.tableSorter.sortType = "date";
      sortfn = o2.tableSorter.sort_date;
    }
    if (item.match(/^\d\d[\.\/-]\d\d[\.\/-]\d\d$/)) {
      o2.tableSorter.sortType = "date";
      sortfn = o2.tableSorter.sort_date;
    }
    if (item.match(/^[£$]/)) {
      o2.tableSorter.sortType = "currency";
      sortfn = o2.tableSorter.sort_currency;
    }
    o2.tableSorter.sortColumnIndex = columnIndex;
    var newRows  = new Array(); // The rows to sort

    // Don't sort the header row:
    for (j = 1; j < rows.length; j++) {
      newRows[j-1] = rows[j];
    }

    newRows.sort(sortfn);
    if (header.getAttribute("sortdir") == "down") {
      o2.tableSorter.sortDirection = "DESC";
      newRows.reverse();
      header.setAttribute("sortdir", "up");
    }
    else {
      o2.tableSorter.sortDirection = "ASC";
      header.setAttribute("sortdir", "down");
    }
    
    // We appendChild rows that already exist to the row's parent, so it moves them rather than creating new ones
    // don't do sortbottom rows
    for (i = 0; i < newRows.length; i++) {
      var row = newRows[i];
      if (!o2.hasClassName(row, "sortbottom")) {
        row.parentNode.appendChild(row); // XXX Could be a problem with more than one tbody - sorting will be done within each tbody, but maybe that's ok?
      }
    }
    // do sortbottom rows only
    for (i = 0; i < newRows.length; i++) {
      var row = newRows[i];
      if (o2.hasClassName(row, "sortbottom")) {
        row.parentNode.appendChild(row);
      }
    }

    // Remove "activeSort" class name from header cells:
    var firstRow = o2.tableSorter.getFirstRow( table );
    var cells    = o2.tableSorter.getCells( firstRow );
    for (var i = 0; i < cells.length; i++) {
      var cell = cells[i];
      o2.removeClassName(cell, "activeSort");
      var spans = cell.getElementsByTagName("span");
      for (var j = 0; j < spans.length; j++) {
        var span = spans[j];
        if (o2.hasClassName(span, "up")  ||  o2.hasClassName(span, "down")) {
          span.parentNode.removeChild(span);
          continue;
        }
      }
    }

    o2.addClassName(header, "activeSort");

    var span = document.createElement("span");
    o2.addClassName(span, header.getAttribute("sortdir"));
    header.appendChild(span);
    if (table.nodeName.toLowerCase() === "table") {
      var span2 = document.createElement("span");
      span.appendChild(span2); // For tables, we need an extra span to be able to style the headers the way we want.
    }

    if (o2.tableSorter.callbackFunction) {
      o2.tableSorter.callbackFunction.call(this, header, o2.tableSorter.sortDirection, o2.tableSorter.sortType);
    }
  },

  getFirstRow : function(table) {
    if (table.nodeName.toLowerCase() === "table"  &&  table.rows  &&  table.rows.length > 0) {
      return table.rows[0];
    }
    if (table.nodeName.toLowerCase() === "div") {
      var elm = table.childNodes[0];
      while (elm  &&  (elm.nodeName.toLowerCase() !== "div" || !o2.hasClassName(elm, "row"))) {
        elm = elm.nextSibling;
      }
      if (elm  &&  (elm.nodeName.toLowerCase() !== "div" || !o2.hasClassName(elm, "row"))) {
        return null;
      }
      return elm;
    }
    return null;
  },

  getCellIndex : function(cell) {
    var tagName = cell.nodeName.toLowerCase();
    if (tagName.match(/^t[hd]$/i)) {
      return cell.cellIndex;
    }
    if (tagName === "span") {
      var row = cell.parentNode;
      while (!o2.hasClassName(row, "row")) {
        if (!row.parentNode) {
          throw new O2Exception("getCellIndex: Couldn't find row");
        }
        row = row.parentNode;
      }

      var cells = o2.tableSorter.getCells(row);
      for (var i = 0; i < cells.length; i++) {
        if (cells[i] === cell) {
          return i;
        }
      }
    }
    throw new O2Exception("getCellIndex: Couldn't find cell");
  },

  getCells : function(row) {
    var tagName = row.nodeName.toLowerCase();
    if (tagName === "tr"  &&  row.cells) {
      return row.cells;
    }
    if (tagName === "div") {
      return o2.getElementsByClassName("cell", row, "span");
    }
    return new Array();
  },

  getRows : function(table) {
    var tagName = table.nodeName.toLowerCase();
    if (tagName === "table"  &&  table.rows) {
      return table.rows;
    }
    if (tagName === "div") {
      var divs = table.getElementsByTagName("div");
      var rows = new Array();
      for (var i = 0; i < divs.length; i++) {
        var div = divs[i];
        if (o2.hasClassName(div, "row")) {
          rows.push(div);
        }
      }
      return rows;
    }
    return new Array();
  },

  /* elm is some item inside the table. Searching through parent, grandParent etc until we find a table or "pseudo-table" that is sortable. */
  getTable : function(elm) {
    while (elm && elm.parentNode && !o2.tableSorter.isSortableTable(elm)) {
      elm = elm.parentNode;
    }
    if (o2.tableSorter.isSortableTable(elm)) {
      return elm;
    }
    return null;
  },

  isSortableTable : function(elm) {
    var tagName = elm.nodeName.toLowerCase();
    if (tagName === "table"  &&  o2.hasClassName(elm, "sortable")) {
      return true;
    }
    if (tagName === "div"  &&  o2.hasClassName(elm, "sortableColumns")) {
      return true;
    }
    return false;
  },

  getCellByRowAndIndex : function(row, index) {
    var cells = o2.tableSorter.getCells(row);
    return cells[index];
  },

  sort_date : function(a, b) {
    // y2k notes: two digit years less than 50 are treated as 20XX, greater than 50 are treated as 19XX
    aa = o2.tableSorter.getSortValue(a);
    bb = o2.tableSorter.getSortValue(b);
    if (aa.length == 11) {
      if (aa.substr(7,4) < bb.substr(7,4)) {
        return -1;
      }
      else if (aa.substr(7,4) > bb.substr(7,4)) {
        return 1;
      }
      // Same year.
      if (aa.substr(3,3) === bb.substr(3,3)) {
        // Same month
        if (aa.substr(0,2) < bb.substr(0,2)) {
          return -1;
        }
        else if (aa.substr(0,2) > bb.substr(0,2)) {
          return 1;
        }
        return 0; // Same date
      }
      else {
        // Different months
        return o2.tableSorter.month_cmp(aa.substr(3,3), bb.substr(3,3));
      }
    }
    else if (aa.length == 10) {
      dt1 = aa.substr(6,4) + aa.substr(3,2) + aa.substr(0,2);
    }
    else {
      yr = aa.substr(6,2);
      if (parseInt(yr) < 50) {
        yr = "20" + yr;
      }
      else {
        yr = "19" + yr;
      }
      dt1 = yr + aa.substr(3,2) + aa.substr(0,2);
    }
    if (bb.length == 10) {
      dt2 = bb.substr(6,4)+bb.substr(3,2)+bb.substr(0,2);
    }
    else {
      yr = bb.substr(6,2);
      if (parseInt(yr) < 50) {
        yr = "20"+yr;
      }
      else {
        yr = "19"+yr;
      }
      dt2 = yr+bb.substr(3,2)+bb.substr(0,2);
    }
    if (dt1 == dt2) {
      return 0;
    }
    if (dt1 < dt2) {
      return -1;
    }
    return 1;
  },

  month_cmp : function(a, b) {
    a = a.toLowerCase();
    b = b.toLowerCase();
    var months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
    for (var i = 0; i < 12; i++) {
      if (a === months[i]) {
        var a_month_num = i;
      }
      if (b === months[i]) {
        var b_month_num = i;
      }
    }
    if (a_month_num < b_month_num) {
      return -1;
    }
    if (a_month_num > b_month_num) {
      return 1;
    }
    return 0;
  },

  sort_currency : function(a,b) {
    aa = o2.tableSorter.getSortValue(a).replace(/[^0-9.]/g,"");
    bb = o2.tableSorter.getSortValue(b).replace(/[^0-9.]/g,"");
    return parseFloat(aa) - parseFloat(bb);
  },

  sort_numeric : function(a,b) {
    aa = o2.tableSorter.getSortValue(a);
    if (isNaN(aa)) {
      aa = aa.replace(/ /, "");
      if (aa.match(/,/)) {
        aa = aa.replace(/\./, "");
        aa = aa.replace(/,/, ".");
      }
    }
    aa = parseFloat(aa);
    if (isNaN(aa)) {
      aa = 0;
    }

    bb = o2.tableSorter.getSortValue(b);
    if (isNaN(bb)) {
      bb = bb.replace(/ /, "");
      if (bb.match(/,/)) {
        bb = bb.replace(/\./, "");
        bb = bb.replace(/,/, ".");
      }
    }
    bb = parseFloat(bb);
    if (isNaN(bb)) {
      bb = 0;
    }
    return aa - bb;
  },

  sort_caseinsensitive : function(a,b) {
    aa = o2.tableSorter.getSortValue(a).toLowerCase();
    bb = o2.tableSorter.getSortValue(b).toLowerCase();
    if (aa == bb) {
      return 0;
    }
    if (aa < bb) {
      return -1;
    }
    return 1;
  },

  sort_default : function(a,b) {
    aa = o2.tableSorter.getSortValue(a);
    bb = o2.tableSorter.getSortValue(b);
    if (aa == bb) {
      return 0;
    }
    if (aa < bb) {
      return -1;
    }
    return 1;
  },

  getSortValue : function(row) {
    return o2.tableSorter.getInnerText( o2.tableSorter.getCellByRowAndIndex(row, o2.tableSorter.sortColumnIndex) );
  }

};

o2.addLoadEvent(o2.tableSorter.init);
