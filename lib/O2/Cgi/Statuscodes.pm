package O2::Cgi::Statuscodes;

use strict;

# For now, this only includes stuff for Apache. If we ever want to have something for IIS/PerEx, this
# is the place to do it.
use Apache2::Const;

#--------------------------------------------------------------------------------------------
sub getStatus {
  my ($statusCode) = @_;
  my %statuses;
  if ($ENV{MOD_PERL} =~ m{^mod_perl/2[.\d]+$} || $ENV{MOD_PERL_API_VERSION} eq '2') {
    no strict 'subs';
    %statuses = (
      ok         => Apache2::Const::OK,
      error      => Apache2::Const::SERVER_ERROR,
      redirected => Apache2::Const::REDIRECT,
      notFound   => Apache2::Const::NOT_FOUND,
    );
  }
  else {
    require Apache::Constants;
    Apache::Constants->import( qw(OK SERVER_ERROR AUTH_REQUIRED NOT_FOUND REDIRECT NOT_IMPLEMENTED) );
    no strict 'subs';
    %statuses = (
      ok         => OK,
      error      => SERVER_ERROR,
      redirected => REDIRECT,
      notFound   => NOT_FOUND,
    );
  }
  
  return exists $statuses{$statusCode} ? $statuses{$statusCode} : 'NOT_IMPLEMENTED';
}
#--------------------------------------------------------------------------------------------
1;
