o2.slides = {
  currentSlideNum : o2.urlMod.getHash().replace(/page/, '') || 1,
  slides          : new Array(),
  fontSizes       : new Array(),
  
  numUnavailablePixelsAtTheTop    : 60,
  numUnavailablePixelsAtTheBottom : 60,
  
  init : function(e) {
    o2.slides.makeSlides();
    o2.addEvent( window, "click",  o2.slides.showNextSlide );
    o2.addEvent( window, "resize", o2.slides.reload        );
    
    // keypress doesn't work in ie7 for some reason.. We'll remove 1 of these events in the handleKeyPress function
    o2.addEvent( document, "keypress", o2.slides.handleKeyPress );
    o2.addEvent( document, "keydown",  o2.slides.handleKeyPress );
    
    // Don't go to next slide if a link is clicked
    var slidesTag = o2.getElementsByClassName("slides")[0];
    var links = slidesTag.getElementsByTagName("a");
    for (var i = 0; i < links.length; i++) {
      links[i].onclick = function(e) {
        e.stopPropagation();
      }
    }
  },
  
  makeSlides : function() {
    o2.slides.slides = o2.getElementsByClassName("slideMain", null, "div");
    o2.slides.calculateFontSizePerPage();
    o2.slides.hideSlides();
    o2.slides.showCurrentSlide();
    o2.getElementsByClassName("slides")[0].style.visibility = "visible"; // Make content visible
  },
  
  reload : function(e) {
    // Have to make some change to the url to be able to reload. Strange..
    var url;
    if (o2.urlMod.getQueryString()) {
      url = o2.urlMod.urlMod({ removeParams : "1" });
    }
    else {
      url = o2.urlMod.urlMod({ setParam : "a=1" });
    }
    window.location.href = url;
  },
  
  calculateFontSizePerPage : function() {
    var bodyHeight = o2.slides.getBodyHeight() - o2.slides.numUnavailablePixelsAtTheTop - o2.slides.numUnavailablePixelsAtTheBottom;
    var bodyWidth  = o2.slides.getBodyWidth();
    
    for (var i = 0; i < o2.slides.slides.length; i++) {
      var slide = o2.slides.slides[i];
      var contentHeight = o2.getComputedStyle( slide, "height" );
      var contentWidth  = o2.getComputedStyle( slide, "width"  );
      var yEnlargement = bodyHeight / contentHeight;
      var xEnlargement = bodyWidth  / contentWidth;
      var enlargement  = Math.min(yEnlargement, xEnlargement);
      o2.slides.fontSizes.push(   parseInt( parseInt(o2.getComputedStyle(slide, "fontSize")) * enlargement  -  1)  +  "px"   );
    }
  },
  
  hideSlides : function() {
    for (var i = 0; i < o2.slides.slides.length; i++) {
      o2.slides.slides[i].parentNode.style.display = "none";
    }
  },
  
  showCurrentSlide : function() {
    var slide = o2.slides.slides[ o2.slides.currentSlideNum-1 ];
    slide.style.fontSize = o2.slides.fontSizes[ o2.slides.currentSlideNum-1 ];
    slide.parentNode.style.display = "";
    slide.style.float   = "";
    var unusedHeight = o2.slides.getBodyHeight()  -  o2.getComputedStyle( slide, "height" )  -  o2.slides.numUnavailablePixelsAtTheTop  -  o2.slides.numUnavailablePixelsAtTheBottom;
    var unusedWidth  = o2.slides.getBodyWidth()   -  o2.getComputedStyle( slide, "width"  );
    slide.style.top  = unusedHeight/2 + o2.slides.numUnavailablePixelsAtTheTop + "px";
    slide.style.left = unusedWidth/2  + "px";
    window.location.hash = "page" + o2.slides.currentSlideNum;
  },
  
  showNextSlide : function() {
    if (o2.slides.currentSlideNum === o2.slides.slides.length) {
      return;
    }
    var currentSlide = o2.slides.slides[ o2.slides.currentSlideNum-1 ];
    currentSlide.parentNode.style.display = "none";
    o2.slides.currentSlideNum++;
    o2.slides.showCurrentSlide();
  },
  
  showPreviousSlide : function() {
    if (o2.slides.currentSlideNum === 1) {
      return;
    }
    o2.slides.hideCurrentSlide();
    o2.slides.currentSlideNum--;
    o2.slides.showCurrentSlide();
  },
  
  showFinalSlide : function() {
    o2.slides.hideCurrentSlide();
    o2.slides.currentSlideNum = o2.slides.slides.length;
    o2.slides.showCurrentSlide();
  },
  
  showFirstSlide : function() {
    o2.slides.hideCurrentSlide();
    o2.slides.currentSlideNum = 1;
    o2.slides.showCurrentSlide();
  },
  
  hideCurrentSlide : function() {
    o2.slides.slides[ o2.slides.currentSlideNum-1 ].parentNode.style.display = "none";    
  },
  
  handleKeyPress : function(e) {
    switch (e.getKeyCode()) {
    case  8:                                                           // Backspace
    case 33:                                                           // Page up
    case 37:                                                           // Left arrow
    case 38: o2.slides.showPreviousSlide(); e.preventDefault(); break; // Up arrow
    case 13:                                                           // Enter
    case 32:                                                           // Space bar
    case 34:                                                           // Page down
    case 39:                                                           // Right arrow
    case 40: o2.slides.showNextSlide();     e.preventDefault(); break; // Down arrow
    case 35: o2.slides.showFinalSlide();                        break; // End
    case 36: o2.slides.showFirstSlide();                        break; // Home
    }
    
    // Remove the event we're not using (browser dependent)
    if (e.getType() === "keypress") {
      o2.removeEvent(document, "keydown", o2.slides.handleKeyPress);
    }
    else if (e.getType() === "keydown") {
      o2.removeEvent(document, "keypress", o2.slides.handleKeyPress);
    }
    
    e.stopPropagation();
  },
  
  getBodyWidth : function() {
    var marginLeft  = o2.getComputedStyle( document.body, "marginLeft"  );
    var marginRight = o2.getComputedStyle( document.body, "marginRight" );
    if (marginLeft.match(/%$/)) {
      marginLeft = parseInt(  o2.getWindowWidth() * parseInt(marginLeft) / 100  );
    }
    if (marginRight.match(/%$/)) {
      marginRight = parseInt(  o2.getWindowWidth() * parseInt(marginRight) / 100  );
    }
    return parseInt(o2.getWindowWidth() - parseInt(marginLeft) - parseInt(marginRight));
  },
  
  getBodyHeight : function() {
    return o2.getWindowHeight();
  }
  
};

o2.addLoadEvent(o2.slides.init);
