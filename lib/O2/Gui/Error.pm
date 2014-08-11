package O2::Gui::Error;

use strict;

use base 'O2::Gui';

use O2 qw($cgi);

#--------------------------------------------------------------------------------------------------
sub code500 {
  my ($obj) = @_;
  $cgi->_untieStdOut();
  require O2::Cgi::FatalsToBrowser;
  print O2::Cgi::FatalsToBrowser::html("Internal Server Error: $ENV{REDIRECT_ERROR_NOTES}");
}
#--------------------------------------------------------------------------------------------------
1;
