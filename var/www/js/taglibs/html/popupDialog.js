o2.require("/js/DOMUtil.js");
o2.require("/js/ajax.js");

o2.popupDialog = {

  submitFunc          : null,
  currentOpenDialogId : null,
  dialogCloseIsSet    : false,

  init : function() {
    if (!document.getElementById("o2PopupDialog")) {
      var html;
      html  = '<div class="modal fade" id="o2PopupDialog" tabindex="-1" role="dialog" aria-labelledby="o2PopupDialogLabel" aria-hidden="true">';
      html += '  <div class="modal-dialog">';
      html += '    <div class="modal-content">';
      html += '      <div class="modal-header">';
      html += '        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>';
      html += '        <h4 class="modal-title" id="o2PopupDialogLabel"></h4>';
      html += '      </div>';
      html += '      <div class="modal-body" id="o2PopupDialogBody"></div>';
      html += '      <div class="modal-footer"></div>';
      html += '    </div>';
      html += '  </div>';
      html += '</div>';
      $(document.body).append( $(html) );
    }
  },

  define : function(id, params) {
    if (!o2.popupDialog[id]) {
      o2.popupDialog[id] = {};
    }
    o2.popupDialog[id].buttons = [];
    o2.popupDialog[id].params = params;
  },

  addSubmitBtn : function(id, text, func) {
    func = func || function () {
      var form = o2.popupDialog.findForm( document.getElementById("o2PopupDialog") );
      if ( ( form && form.onsubmit && form.onsubmit.call(form) )  ||  (form && !form.onsubmit) ) {
        form.submit();
      }
      o2.popupDialog.hide();
    };
    o2.popupDialog[id].buttons.push({
      "text"  : text,
      "class" : "btn-primary",
      "click" : func
    });
  },

  addCloseBtn : function(id, text) {
    o2.popupDialog[id].buttons.push({
      "text"       : text,
      "class"      : "btn-default",
      "isCloseBtn" : true
    });
  },

  addBtn : function(id, text, onClick, className) {
    o2.popupDialog[id].buttons.push({
      "text"  : text,
      "class" : className,
      "click" : function () { eval(onClick) }
    });
  },

  display : function(id, extraParams) {
    o2.popupDialog.currentOpenDialogId = id;
    o2.popupDialog.clear();

    if (!o2.popupDialog[id]) {
      var params = {};
      var linkTag = document.getElementById(id);
      for (var i = 0; i < linkTag.attributes.length; i++) {
        var attr = linkTag.attributes[i];
        if (attr.name !== "id" && attr.name !== "class") {
          params[ attr.name ] = attr.value;
        }
      }
      o2.popupDialog.define(id, params);
      var submitText = params.submitText || params.submittext;
      if (submitText) {
        o2.popupDialog.addSubmitBtn(id, submitText);
      }
      var closeText = params.closeText || params.closetext;
      if (closeText) {
        o2.popupDialog.addCloseBtn(id, closeText);
      }
    }

    var params = o2.popupDialog[id].params;
    for (var key in extraParams) {
      params[key] = extraParams[key];
    }
    var contentId   = params.contentId   || params.contentid;
    var contentUrl  = params.contentUrl  || params.contenturl;
    var contentHtml = params.contentHtml || params.contenthtml;
    if (params.onClose) {
      var onClose = params.onClose;
      delete params.onClose;
      params.close = function() { eval(onClose); }
    }

    o2.popupDialog.drawButtons(id);
    $("#o2PopupDialog .modal-body"  ).css( "height", params.height );
    $("#o2PopupDialog .modal-dialog").css( "width",  params.width  );
    $("#o2PopupDialog").modal("toggle");
    if (!o2.popupDialog.dialogCloseIsSet) {
      o2.popupDialog.dialogCloseIsSet = true;
      $("#o2PopupDialog").on("dialogclose", function (event, ui) {
        o2.popupDialog.copyHtmlToHiddenContainer();
      } );
    }
    var popupDialog = document.getElementById("o2PopupDialog");
    $("#o2PopupDialog .modal-title").html(params.title);
    if (contentHtml) {
      $("#o2PopupDialog .modal-body").html(contentHtml);
    }
    else if (contentId) {
      $("#o2PopupDialog .modal-body").html( document.getElementById(contentId).innerHTML );
    }
    else if (contentUrl) {
      //popupDialog.parentNode.style.display = "none";
      o2.ajax.call({
        serverScript : contentUrl,
        target       : "o2PopupDialogBody",
        where        : "replace",
        onSuccess    : "var elm = document.getElementById('o2PopupDialog').parentNode; elm.id = '" + id + "'; elm.style.display = '';"
      });
    }
  },

  hide : function() {
    $("#o2PopupDialog").modal({ show : false });
  },

  findForm : function(elm) {
    for (var i = 0; i < elm.childNodes.length; i++) {
      var child = elm.childNodes[i];
      if (child.nodeType == 3) {
        continue;
      }
      if (child.nodeName.toLowerCase() === "form") {
        return child;
      }
      var form = o2.popupDialog.findForm(child);
      if (form) {
        return form;
      }
    }
    return null;
  },
  
  copyHtmlToHiddenContainer : function() {
    var id = o2.popupDialog.currentOpenDialogId;
    if (!id) {
      return;
    }
  },
  
  drawButtons : function(id) {
    var buttons = o2.popupDialog[id].buttons;
    for (var i = 0; i < buttons.length; i++) {
      o2.popupDialog.drawButton( id, buttons[i] );
    }
    o2.popupDialog[id].buttons = [];
  },

  drawButton : function(id, button) {
    var buttonElm = $(
        '<button type="button" class="btn '
      + button.class
      + '"'
      + (button.isCloseBtn ? " data-dismiss='modal'" : "")
      + '>'
      + button.text
      + '</button>'
    );
    buttonElm.click(button.click);
    $("#o2PopupDialog .modal-footer").append(buttonElm);
  },

  clear : function() {
    $( "#o2PopupDialogLabel"          ).html("");
    $( "#o2PopupDialogBody"           ).html("");
    $( "#o2PopupDialog .modal-footer" ).html("");
  },
};
