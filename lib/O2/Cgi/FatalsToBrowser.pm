package O2::Cgi::FatalsToBrowser;

use strict;

use O2 qw($context);

#--------------------------------------------------------------------------------------------
sub html {
  my ($message, %params) = @_;
  my @stackTrace = @{ $params{stackTrace} || [] };
  O2::Cgi::FatalsToBrowser::logError($message, @stackTrace) unless $params{dontLog};
  
  $message = O2::Cgi::FatalsToBrowser::updateErrorMessage($message, 0, @stackTrace);
  
  require Encode;
  $message = Encode::encode( $O2::Cgi::CGI->getCharacterSet(), $message );
  
  my $output = "Status: 500 Service Unavailable\n";
  $output   .= "Content-type: text/html\n\n";
  $output   .= join "\n",
    '<!DOCTYPE html><html><head>',
    '<link rel="stylesheet" type="text/css" href="/css/errorPage.css">',
    '<title>Application error</title></head><body>',
    '<h1>Application error</h1>',
    '<h2>The application performed an illegal operation and could not execute properly.</h2>',
    '<p>You can report this problem for further investigation if you',
    'currently have a valid SLA-agreement with Redpill-Linpro AS, or if this error occured during',
    'testing and/or debugging.</p>',
    '<a class="button" href="https://support.redpill-linpro.com/">Report this error</a>',
    '<p>Please include the details below:</p>',
    '<div class="errorDetails">', $message, '</div>',
    '</body></html>';
  return $output;
}
#--------------------------------------------------------------------------------------------
sub ajax {
  my ($message, %params) = @_;
  my @stackTrace = @{ $params{stackTrace} || [] };
  O2::Cgi::FatalsToBrowser::logError($message, @stackTrace) unless $params{dontLog};
  
  $message = O2::Cgi::FatalsToBrowser::updateErrorMessage($message, 1, @stackTrace);
  
  eval {
    $O2::Cgi::CGI->ajaxError($message, '');
  };
}
#--------------------------------------------------------------------------------------------
sub logError {
  my ($message, @stackTrace) = @_;
  eval {
    $context->getConsole()->error(
      $message,
      stackTrace  => \@stackTrace,
      callerLevel => 6,
    );
  };
}
#--------------------------------------------------------------------------------------------
sub updateErrorMessage {
  my ($message, $isAjax, @stackTrace) = @_;
  
  my $errorId;
  my $session = $context->getSession();
  if ($session) { # Important that we don't die inside this method, so checking if session exists
    $errorId = $session->get('latestConsoleLogId');
    $session->delete('latestConsoleLogId');
  }
  
  my $indent = 1;
  my $printErrorId = $errorId && !$context->isBackend();
  
  require O2::Template::TagParser;
  my $tagParser = O2::Template::TagParser->new();
  
  $message  = $tagParser->encodeEntities($message, '<>');
  $message  = ($isAjax ? "An error occurred<br><br>\n" : '') . "Error ID: $errorId" if $printErrorId;
  $message  = qq{<b class="o2ApplicationErrorMessage">$message</b><br><br>\n};
  $message .= join "<br>\n",  map { '&nbsp;' x (($indent++)*2) . "- $_" } @stackTrace unless $printErrorId;
  return $message;
}
#--------------------------------------------------------------------------------------------
1;
