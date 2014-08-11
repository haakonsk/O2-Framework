var OPENWINDOW_URL_TO_POST;

o2.openWindow = {};

o2.openWindow.openWindow = function(properties) {
  var url = properties.url;
  var requestMethod = "get";
  if (url.length > 1000) { // Url might be too long for get request - use post instead
    OPENWINDOW_URL_TO_POST = url;
    requestMethod = "post";
    properties.windowName = properties.windowName  ||  "openendWindow" + parseInt( 1000000*Math.random() );
    url = "/o2/Js-OpenWindow/post";
  }
  if ( !properties.toolbar     ) { properties.toolbar     = "no"  }
  if ( !properties.location    ) { properties.location    = "no"  }
  if ( !properties.directories ) { properties.directories = "no"  }
  if ( !properties.status      ) { properties.status      = "no"  }
  if ( !properties.menubar     ) { properties.menubar     = "no"  }
  if ( !properties.scrollbars  ) { properties.scrollbars  = "yes" }
  if ( !properties.resizable   ) { properties.resizable   = "yes" }
  if ( !properties.width       ) { properties.width       = 400   }
  if ( !properties.height      ) { properties.height      = 300   }
  if ( !properties.windowName ) {
    var now = new Date();
    properties.windowName = now.getTime();
  }
  
  var windowsProperties
    =  "toolbar="     + properties.toolbar
    + ",location="    + properties.location
    + ",directories=" + properties.directories
    + ",status="      + properties.status
    + ",menubar="     + properties.menubar
    + ",scrollbars="  + properties.scrollbars
    + ",resizable="   + properties.resizable
    + ",width="       + properties.width
    + ",height="      + properties.height
    ;
  
  var theWindow = open(url, properties.windowName, windowsProperties);
  return theWindow;
}

o2.openWindow.getUrlToPost = function() {
  return OPENWINDOW_URL_TO_POST;
}
