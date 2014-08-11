// Check out Test::More on cpan for documentation of most of these methods

function Tester() {
  this.counter = 0;
  this.startMethod = null;
}

Tester.prototype.setStartMethod = function(startMethod) {
  this.startMethod = startMethod;
}

Tester.prototype.startTesting = function() {
  if (!this.startMethod) {
    return alert("Can't start testing, no startMethod set.");
  }
  this.startMethod.call(null);
  this.startMethod = null;
}

Tester.prototype.resetCounter = function() {
  this.counter = 0;
}

Tester.prototype.getCounter = function() {
  return this.counter;
}

Tester.prototype.is = function(got, expected, testName) {
  if (got === expected) {
    return this.ok(true, testName);
  }
  this.reportError(testName, got, expected);
}

Tester.prototype.isnt = function(got, expected, testName) {
  if (got !== expected) {
    return this.ok(true, testName);
  }
  this.reportError(testName, got, expected);
}

Tester.prototype.ok = function(shouldBeTrue, testName) {
  this.counter++;
  if (shouldBeTrue) {
    print("ok " + this.counter + " - " + testName, "okTest");
    return true;
  }
  this.reportError(testName);
}

Tester.prototype.like = function(got, expectedRegex, testName) {
  if (expectedRegex.exec(got)) {
    return this.ok(true, testName);
  }
  this.reportError(testName, got, expectedRegex);
}

Tester.prototype.unlike = function(got, expectedRegex, testName) {
  if (!expectedRegex.exec(got)) {
    return this.ok(true, testName);
  }
  this.reportError(testName, got, "!" + expectedRegex.toString());
}

Tester.prototype.cmp_ok = function(got, operator, expected, testName) {
  if (typeof(got) === "string") {
    got = "'" + got + "'";
  }
  if (typeof(expected) === "string") {
    expected = "'" + expected + "'";
  }
  if (eval(got + operator + expected)) {
    return this.ok(true, testName);
  }
  this.reportError(testName, got, expected, operator);
}

Tester.prototype.reportError = function(testName, got, expected, operator) {
  this.counter++;
  print("not ok " + this.counter + " - " + testName, "error");
  print("# Failed test '" + testName + "'", "info");
  if (got || expected) {
    if (operator) {
      print("#    " + got, "info");
      print("#        " + operator, "info");
      print("#    " + expected.toString(), "info");
      return;
    }
    print("#    Got:      " + got,                 "info");
    print("#    Expected: " + expected.toString(), "info");
  }
}

Tester.prototype.diag = function(msg) {
  print("# " + msg, "info");
}

function print(msg, type) {
  msg = msg || "";
  msg = msg.replace(/  /g, "&nbsp;&nbsp;");
  var span = document.createElement("span");
  if (type) {
    span.className = type;
  }
  span.innerHTML = msg;
  document.body.appendChild(span);
  document.body.appendChild( document.createElement("br") );
  document.body.scrollTop = document.body.scrollHeight;
}

window.tester = new Tester();
