var PROCESSES = {};

function backgroundProcessStarted(result) {
  var process = PROCESSES[result.pid] = {};
  process.id         = result.id;
  process.pid        = result.pid;
  process.maxCounter = result.maxCounter;
  if (result.callback) {
    eval(result.callback);
  }
  if (result.onStart) {
    eval(result.onStart);
  }
  if (result.onEnd) {
    process.onEnd = result.onEnd;
  }
  if (result.showProgressBar) {
    showProgressBar(result.id);
    process.percentFilled                 = 0;
    process.checkIntervalSeconds          = result.checkIntervalSeconds;
    process.estimateProgressBetweenChecks = result.estimateProgressBetweenChecks;
    process.checkTimeoutSeconds           = result.checkTimeoutSeconds;
    updateProgress(result, true);
  }
}

function updateProgress(result, justStarting) {
  var process = PROCESSES[result.pid];
  if (result && !justStarting) {
    process.percentFilled = 100 * result.counter / process.maxCounter;
    if (process.percentFilled > 100) {
      process.percentFilled = 100;
    }
    $("#progressBarFor_" + process.id + " div").css("width", process.percentFilled + "%"); 
    if (process.percentFilled) {
      if (process.timeout) {
        clearTimeout(process.timeout);
      }
      process.percentPerUpdate = 0.050 * process.percentFilled / result.seconds;
      if (process.estimateProgressBetweenChecks) {
        process.timeout = setTimeout( function() { updateProgressCss(process); }, 50 );
      }
    }
  }
  if (justStarting || result.result === "timeout" || result.counter < process.maxCounter) {
    setTimeout( function() { getProgressCounter(process); }, 1000 * process.checkIntervalSeconds );
  }
  else if (result.result === "error") {
    alert(result.errorMsg);
  }
  else if (result.counter >= process.maxCounter) {
    if (process.timeout) {
      clearTimeout(process.timeout);
    }
    o2.ajax.call({
      setClass  : "Taglibs-BackgroundProcess",
      setMethod : "cleanup",
      setParams : { pid : result.pid },
      onSuccess : "eval('" + process.onEnd + "'); hideProgressBar(" + process.id + ");",
      method    : "post"
    });
  }
}

function updateProgressCss(process) {
  process.percentFilled += process.percentPerUpdate;
  if (process.percentFilled > 100) {
    process.percentFilled = 100;
  }
  $("#progressBarFor_" + process.id + " div").css("width", process.percentFilled + "%");
  if (process.estimateProgressBetweenChecks) {
    process.timeout = setTimeout( function() { updateProgressCss(process) }, 50 );
  }
}

function getProgressCounter(process) {
  o2.ajax.call({
    setClass     : "Taglibs-BackgroundProcess",
    setMethod    : "getProgressCounter",
    setParams    : { pid : process.pid },
    timeout      : process.checkTimeoutSeconds,
    errorHandler : "updateProgress",
    handler      : "updateProgress"
  });
}

function hideProgressBar(id) {
  $("#progressBarFor_" + id).css("display", "none");
  $("#progressBarFor_" + id + " div").css("width", 0); 
}

function showProgressBar(id) {
  $("#progressBarFor_" + id).css("display", "block");
}
