(function($){
  $.fn.fadeCarousel = function (options) {
    var mergedOptions = $.extend( {}, $.fn.fadeCarousel.defaults, options);
    
    var elements = this;
    elements.hide();
    var current = mergedOptions.startElementIndex;
    if (mergedOptions.startElementIndex == "random") {
      current = Math.floor(Math.random() * elements.length);
    }
    else if (mergedOptions.startElementIndex == "last") {
      current = elements.length - 1;
    }
    else if (mergedOptions.startElementIndex == "first") {
      current = 0;
    }
    var next = current;
    elements.eq(current).show();
    
    setInterval(function() {
      if (++next >= elements.length) { next = 0 }
      elements.eq(current).hide();
      elements.eq(next).fadeIn("slow");
      current = next;
    }, mergedOptions.displayTime);
    return elements;
  }
  $.fn.fadeCarousel.defaults = {
    startElementIndex : "random",
    displayTime       : 5000,
  };
})(jQuery);
