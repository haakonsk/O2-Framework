package O2::Dispatch::mod_perl;

# Written for mod_perl2, which requires apache2

use strict;

use O2::Cgi;

# Log to correct file, which is the value of the ErrorLog Directive from the Apache configuration
# (See http://perl.apache.org/docs/2.0/api/Apache2/Log.html#Virtual_Hosts):
$SIG{__WARN__} = sub {
  my ($msg) = @_;
  my $ip = $ENV{HTTP_X_FORWARDED_FOR} || $ENV{REMOTE_ADDR} || '';
  $msg   =~ s{ \s+ \z }{}xms;
  $msg ||= "Something's wrong";
  $msg   = "[client $ip] $msg";
  if (!$ip) {
    my ($file, $line) = (caller 0)[1,2];
    return if $file eq '-e' && $line == 0; # This warning might come from Apache. "Impossible" to debug. Ignoring it.
  }
  Apache2::ServerRec::warn($msg);
  
  # The following line can be used instead of Apache2::ServerRec::warn. Gives you warnings with stack trace.
  # Warnings will go to the central apache error log, unfortunately.
#  require Carp; Carp::cluck($msg);
};

*CORE::GLOBAL::exit = sub {
  die 'MOD_PERL exit';
};

#------------------------------------------------------------------------------------------------------------
sub handler {
  my ($request) = @_;
  local $SIG{__DIE__} = \&O2::Cgi::_gracefulDie;
  
  require O2::Dispatch;
  my $dispatch = O2::Dispatch->new();
  
  $O2::Cgi::CGI = undef; # Create new CGI object on each request
  my $cgi = O2::Cgi->new( modPerlRequest => $request );
  $ENV{O2REQUESTID} ||= rand;
  
  require O2;
  my $db = $O2::context->getDbh();
  $request->push_handlers( PerlCleanupHandler => sub {
    # DESTROY calls disconnect, which might be ignored if we're using Apache::DBI (in the Apache configuration):
    $db->DESTROY();
  });
  
  # Make sure global variables don't get shared between requests:
  # XXX Rewrite the module instead of doing this..
  $O2::Data::_METADATA                    = undef;
  %O2::Mgr::ObjectManager::CACHED_OBJECTS = ();
  
  eval { # The error will be handled by O2::Cgi::_gracefulDie
    $dispatch->dispatch(
      context => $O2::context || (),
      cgi     => $cgi,
    );
  };
  
  require O2::Cgi::Statuscodes;
  return O2::Cgi::Statuscodes::getStatus( $cgi->getStatus() );
}
#------------------------------------------------------------------------------------------------------------
1;
