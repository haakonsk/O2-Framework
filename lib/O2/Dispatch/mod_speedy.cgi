#!/usr/bin/speedy -- -r100

use strict;

use O2::Cgi;
use O2::Dispatch;

BEGIN {
  *CORE::GLOBAL::exit = sub {
    die 'SpeedyCGI exit';
  };
}

$O2::Cgi::CGI = undef; # Create new CGI object on each request

# Make sure global variables don't get shared between requests:
# XXX Rewrite the module instead of doing this..
$O2::Data::_METADATA                    = undef;
%O2::Mgr::ObjectManager::CACHED_OBJECTS = ();

my $cgi = O2::Cgi->new(isSpeedyCgi => 1);
eval {
  O2::Dispatch->new()->dispatch(cgi => $cgi);
};
die $@ if $@ && $@ !~ m{ \A SpeedyCGI [ ] exit }xms;

$main::context->getDbh()->DESTROY(); # For now, disconnect db handle on every request.
