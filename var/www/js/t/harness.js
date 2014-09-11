o2.addLoadEvent(startHarness);

function startHarness(e) {
  harness.findNextFile();
}

var harness = {
  harness : function(url) {
    tester.diag("File: " + url);
    tester.resetCounter();
    o2.require(url, harness.startTesting);
  },

  startTesting : function(url) {
    tester.startTesting();
    harness.findNextFile(url);
  },

  findNextFile : function(url) { // url is the url of the js file that we just required
    var i = 0;
    if (url) {
      var found = false;
      for (i = 0; i < testFiles.length; i++) {
        if (testFiles[i] === url) {
          found = true;
          break;
        }
      }
      i++;
      if (!found || i === testFiles.length) {
        return harness.addSummaryButton();
      }
    }
    harness.harness( testFiles[i] );
  },

  parseHtml : function() {
    harness.errors = new Array();
    var currentError, originalLine, fileName;
    var html = document.body.innerHTML;
    var lines = o2.split(/<br[^>]*>/i, html);
    for (var i = 0; i < lines.length; i++) {
      originalLine = lines[i];
      var line = originalLine.replace(/\n/g, "");
      line     = line.replace(/<[\w\/][^>]*>/g, " "); // Remove tags
      line     = line.replace(/&nbsp;/g, " ");
      var matches = line.match(/#\s*File: (.+)/);
      if (matches) {
        if (currentError) {
          harness.addError(fileName, currentError + "<br>\n" + originalLine);
          currentError = "";
        }
        fileName = matches[1];
        harness.errors[fileName] = new Array();
      }
      else if (line.match(/^\s*not ok/)) {
        if (currentError) {
          harness.addError(fileName, currentError);
        }
        currentError = originalLine;
      }
      else if (line.match(/^\s*ok/)) {
        if (currentError) {
          harness.addError(fileName, currentError);
          currentError = "";
        }
        harness.registerSuccessfulTest(fileName);
      }
      else {
        if (currentError && !originalLine.match(/Summary/)) {
          currentError += "<br>\n" + originalLine;
        }
      }
    }
    if (currentError) {
      harness.addError(fileName, currentError);
      currentError = "";
      originalLine = "";
    }
    harness.printSummary();
  },

  addError : function(fileName, currentError) {
    if (!harness.errors[fileName].errors) {
      harness.errors[fileName].errors = new Array();
    }
    if (!harness.errors[fileName].numTestsTotal) {
      harness.errors[fileName].numTestsTotal      = 0;
      harness.errors[fileName].numSuccessfulTests = 0;
    }
    harness.errors[fileName].errors.push(currentError);
    harness.errors[fileName].numTestsTotal++;
  },

  registerSuccessfulTest : function(fileName) {
    if (!harness.errors[fileName].numTestsTotal) {
      harness.errors[fileName].numTestsTotal      = 0;
      harness.errors[fileName].numSuccessfulTests = 0;
    }
    harness.errors[fileName].numTestsTotal++;
    harness.errors[fileName].numSuccessfulTests++;
  },

  addSummaryButton : function() {
    var button = document.createElement("input");
    button.setAttribute("type",  "button");
    button.setAttribute("value", "Summary");
    o2.addEvent(button, "click", harness.parseHtml);
    document.body.appendChild(button);
    document.body.scrollTop = document.body.scrollHeight;
  },

  printSummary : function() {
    errors = harness.errors;
    document.body.innerHTML = "";
    print("---------------------------------- Test results ----------------------------------");
    print();
    var numFilesOk = 0, numFilesNotOk = 0;
    for (var fileName in errors) {
      var output = fileName;
      var numDots = 80 - fileName.length;
      numDots     = numDots > 0 ? numDots : 0;
      for (var i = 0; i < numDots; i++) {
        output += ".";
      }
      if (errors[fileName].errors  &&  errors[fileName].errors.length) {
        print(output + errors[fileName].numSuccessfulTests + "/" + errors[fileName].numTestsTotal, "error");
        for (var i = 0; i < errors[fileName].errors.length; i++) {
          var error = errors[fileName].errors[i];
          error     = error.replace(/^|\n/g, "  ");
          error     = error.replace(/  /g, "&nbsp;&nbsp;");
          print(error);
        }
        numFilesNotOk++;
      }
      else {
        print(output + errors[fileName].numSuccessfulTests + "/" + errors[fileName].numTestsTotal, "okTest");
        numFilesOk++;
      }
    }
    print();
    print("Num files ok:     " + numFilesOk);
    print("Num files not ok: " + numFilesNotOk);
  }
};
