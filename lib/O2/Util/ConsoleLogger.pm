package O2::Util::ConsoleLogger;

use strict;

use O2 qw($context $db);

# Log entries older than this number of days will be deleted:
my $MAX_AGE_ERRORS     = 180; # Errors may cause strange bugs that we may not notice before long after they occurred, so we shouldn't delete them too early.
my $MAX_AGE_NOT_ERRORS =  14; # Less important and we don't want the tables to grow too big.

#--------------------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  return bless {}, $pkg;
}
#--------------------------------------------------------------------------------
# The error is logged regardless of whether the die is caught or not
sub error {
  my ($obj, $msg, %params) = @_;
  $params{stackTrace} = $context->getConsole()->getStackTrace() if !$params{stackTrace} || !@{ $params{stackTrace} };
  $obj->logError($msg, %params);
  die "DONT_LOG:$msg";
}
#--------------------------------------------------------------------------------
sub logError {
  my ($obj, $msg, %params) = @_;
  $obj->_log('error', $msg, %params);
}
#--------------------------------------------------------------------------------
sub _warning {
  my ($obj, $msg, %params) = @_;
  return $obj->_log('warning', $msg, %params);
}
#--------------------------------------------------------------------------------
sub _message {
  my ($obj, $msg, %params) = @_;
  return $obj->_log('message', $msg, %params);
}
#--------------------------------------------------------------------------------
sub _debug {
  my ($obj, $msg, %params) = @_;
  return $obj->_log('debug', $msg, %params);
}
#--------------------------------------------------------------------------------
sub _log {
  my ($obj, $logType, $message, %params) = @_;
  return if $obj->{_isLogging};
  $obj->{_isLogging} = 1;
  
  my $callerLevel = exists $params{callerLevel} ? delete $params{callerLevel} : 2;

  my $info;
  if (%params) {
    require O2::Data;
    $info = O2::Data->new()->dump(\%params);
  }
  
  my $line = [caller $callerLevel]->[2];
  my ($package, $filename, $_line, $method) = caller ($callerLevel+1);
  $method  =~ s{ :: ([^:]+) \z }{}xms;
  $package = $method;
  $method  = $1;

  if ($package =~ m/eval/) {
    $method  = $package . " at line $line";
    $package = caller $callerLevel-1; # If it's an eval, we need to get the package directly
  }

  my $url = $context->getEnv('REQUEST_URI');
  if (!$url) {
    my $queryString = $context->getEnv('QUERY_STRING');
    $url  = $context->getEnv('PATH_INFO');
    $url .= "?$queryString" if $queryString;
  }

  if (length $message > 255) {
    $info   .= "\nMessage = $message";
    $message = substr $message, 0, 255;
  }

  my $dbClone = $obj->{_dbh} ||= $context->getDbh()->clone(); # Can't use the default DB handler, we risk being rolled back!
  my $epoch   = int time; # In case we have Time::HiRes
  my $userId  = $context->getUserId(),
  my $ip      = $context->getClientIp() || '';
  my $errorId;
  eval {
    $errorId = $dbClone->idInsert(
      'O2_CONSOLE_LOG', 'id',
      logType   => $logType,
      timestamp => $epoch,
      package   => $package,
      method    => $method,
      line      => $line,
      message   => $message,
      info      => $info,
      url       => $url                             || '',
      referrer  => $context->getEnv('HTTP_REFERER') || '',
      userId    => $userId,
      ip        => $ip,
      processId => $$,
    );
    if ($0 =~ m{ /Dispatch/ }xms || $0 =~ m{ [.]cgi \z }xms) { # It's probably a web request, not a script
      my $session = $context->getSession();
      $session->set(    'latestConsoleLogId', "$errorId\@$epoch" ) if  $errorId && $session;
      $session->delete( 'latestConsoleLogId'                     ) if !$errorId && $session;
    }
  };
  if ($@) {
    warn "Couldn't log to O2_CONSOLE_LOG: $@";
    $context->getSession()->delete('latestConsoleLogId');
  }
  $obj->{_isLogging} = 0;
  return $errorId;
}
#--------------------------------------------------------------------------------
sub getStackTrace {
  my ($obj) = @_;
  my $stackTrace = "Stack trace (most recent call on top):\n";
  my @stackTrace = $obj->getStackTraceArray(2);
  foreach my $item (@stackTrace) {
    my ($module, $method);
    ($module, $method) = $item->{subroutine} =~ m{ \A (.+) :: ([^:]+) \Z }xms if $item->{subroutine} =~ m{ :: }xms;
    $method    ||= $item->{subroutine};
    $module    ||= $item->{package};
    $stackTrace .= qq{-Called method "$method" in "$module" from "$item->{fileName}", line $item->{line}.\n};
  }
  return $stackTrace;
}
#--------------------------------------------------------------------------------
sub getStackTraceHtml {
  my ($obj) = @_;
  my $stackTrace = "Stack trace (most recent call on top):\n";
  my @stackTrace = $obj->getStackTraceArray(2);
  foreach my $item (@stackTrace) {
    my ($module, $method);
    ($module, $method) = $item->{subroutine} =~ m{ \A (.+) :: ([^:]+) \Z }xms if $item->{subroutine} =~ m{ :: }xms;
    $method    ||= $item->{subroutine};
    $module    ||= $item->{package};
    $stackTrace .= "<li>Called method <b>$method</b> in <b>$module</b> from $item->{fileName}, line $item->{line}.</li>\n";
  }
  return $stackTrace;
}
#--------------------------------------------------------------------------------
sub getStackTraceArray {
  my ($obj, $startAt) = @_;
  $startAt = 1 unless $startAt;

  my @stack;

  my $i = $startAt;
  my ($package, $fileName, $line, $subroutine, $hasArgs, $wantarray, $evalText, $isRequire, $hints, $bitmask) = caller ($i++);
  while ($package) {
    push @stack, {
      package    => $package,
      fileName   => $fileName,
      line       => $line,
      subroutine => $subroutine,
      hasArgs    => $hasArgs,
      wantarray  => $wantarray,
      evalText   => $evalText,
      isRequire  => $isRequire,
      hints      => $hints,
      bitmask    => $bitmask,
    };
    ($package, $fileName, $line, $subroutine, $hasArgs, $wantarray, $evalText, $isRequire, $hints, $bitmask) = caller ($i++);
  }
  return @stack;
}
#--------------------------------------------------------------------------------
sub deleteOldEntries {
  my ($obj) = @_;
  $db->sql( "delete from O2_CONSOLE_LOG where logType != 'error' and timestamp < ?", time - $MAX_AGE_NOT_ERRORS*24*60*60 );
  $db->sql( "delete from O2_CONSOLE_LOG where logType  = 'error' and timestamp < ?", time - $MAX_AGE_ERRORS*24*60*60     );
}
#--------------------------------------------------------------------------------
1;
