(function($){
  $(document).ready( function () {
    if (!$.cookie) {
      var cookiePlugin = document.createElement('script');
      cookiePlugin.src = '/js/jquery/plugins/jquery.cookie.js';
      cookiePlugin.onload = function () {
        var cookie = $.cookie( 'rememberWindowPosition_' + window.name );
        
        if (cookie) {
          var saved = JSON.parse(cookie);
          window.resizeTo( saved.width, saved.height );
        }
      }
      document.head.appendChild(cookiePlugin);
    }
  });
  
  $.fn.forgetWindowPosition = function (savingText) { 
    $(this).rememberWindowPosition( savingText, { forget: true } );
  }
  
  $.fn.rememberWindowPosition = function (savingText, options) {
    var button = this[0];
    var windowInfo = options && options.forget ? null : JSON.stringify({
      x      : window.screenX,
      y      : window.screenY,
      width  : $(window).width(),
      height : window.outerHeight
    });
    $.cookie( 'rememberWindowPosition_' + window.name, windowInfo, {expires:365} );
    buttonOrgText    = button.innerHTML;
    button.innerHTML = savingText;
    button.disabled  = true;
    setTimeout( function () {
      button.innerHTML = buttonOrgText; button.disabled = false;
    }, 500 );
  }
})(jQuery);
