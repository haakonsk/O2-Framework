package O2::Gui::Autoflush;

use strict;

use O2 qw($cgi);

my $AUTO_SCROLL_ENABLED;
my $AUTO_NEWLINE_ENABLED;
#--------------------------------------------------------------------------------------- 
BEGIN {
  my $flush = \&O2::Cgi::flush;
  *O2::Cgi::flush = sub {
    my ($obj) = @_;
    $obj->{content} = _getLine( $obj->{content} );
    goto $flush;
  }
}
#--------------------------------------------------------------------------------------- 
sub new {
  my ($pkg, %params) = @_;
  $cgi->enableAutoflush();
  $AUTO_SCROLL_ENABLED  = 0;
  $AUTO_NEWLINE_ENABLED = 0;
  return bless \%params, $pkg;
}
#--------------------------------------------------------------------------------------- 
sub enableAutoScroll {
  my ($obj) = @_;
  $AUTO_SCROLL_ENABLED = 1;
}
#---------------------------------------------------------------------------------------
sub disableAutoScroll {
  my ($obj) = @_;
  $AUTO_SCROLL_ENABLED = 0;
}
#---------------------------------------------------------------------------------------
# Foreach print a <br> and newline is added
sub enableAutoNewline {
  my ($obj) = @_;
  $AUTO_NEWLINE_ENABLED = 1;
}
#---------------------------------------------------------------------------------------
sub disableAutoNewline {
  my ($obj) = @_;
  $AUTO_NEWLINE_ENABLED = 0;
}
#---------------------------------------------------------------------------------------
sub printHeader {
  my ($obj, %params) = @_;
  my $css = '';
  if ($params{cssFile}) {
    $css = qq{<link rel="stylesheet" type="text/css" href="$params{cssFile}">};
  }
  else {
    my $fgColor = $params{foregroundColor} || 'black';
    my $bgColor = $params{backgroundColor} || 'white';
    $css = "<style>body { color: $fgColor; padding: 10px; font: 11px Verdana, Arial, sans-serif, Geneva, Helvetica; background: $bgColor; }</style>";
  }

  my $autoNewlineEnabled = $AUTO_NEWLINE_ENABLED;
  my $autoScrollEnabled  = $AUTO_SCROLL_ENABLED;

  $AUTO_NEWLINE_ENABLED = 0;
  $AUTO_SCROLL_ENABLED  = 0;

  my $charset = $cgi->getCharacterSet();
  print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">"; # Standards compliance mode
  print qq{
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=$charset">
    $css
    <script src="/js/jquery.js"></script>
  </head>
  <body>\n};

  $AUTO_NEWLINE_ENABLED = $autoNewlineEnabled;
  $AUTO_SCROLL_ENABLED  = $autoScrollEnabled;

  $| = 1; # Turn off Perl's buffering of the html.
}
#---------------------------------------------------------------------------------------
sub print {
  my ($obj, $str) = @_;
  
  my $autoNewlineEnabled = $AUTO_NEWLINE_ENABLED;
  $AUTO_NEWLINE_ENABLED = 0;
  
  print $str;
  
  $AUTO_NEWLINE_ENABLED = $autoNewlineEnabled;
}
#---------------------------------------------------------------------------------------
sub printLine {
  my ($obj, $str) = @_;

  my $autoNewlineEnabled = $AUTO_NEWLINE_ENABLED;
  $AUTO_NEWLINE_ENABLED = 1;

  print $str;

  $AUTO_NEWLINE_ENABLED = $autoNewlineEnabled;
}
#--------------------------------------------------------------------------------------- 
sub _getLine {
  my ($str, $forceAutoNewline) = @_;
  $str .= "<br />\n"                                                                                           if $AUTO_NEWLINE_ENABLED || $forceAutoNewline;
  $str .= "<script type='text/javascript'>\$('html').scrollTop( \$('html').prop('scrollHeight') );</script>\n" if $AUTO_SCROLL_ENABLED;
  return $str;
}
#---------------------------------------------------------------------------------------
sub printFooter {
  my ($obj) = @_;
  $obj->disableAutoNewline();
  $obj->disableAutoScroll();
  print "  </body>
</html>";
  $cgi->output();
}
#---------------------------------------------------------------------------------------
1;
