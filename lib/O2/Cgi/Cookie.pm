package O2::Cgi::Cookie;

use strict;

use constant DEBUG => 0;
use O2;

#--------------------------------------------------------------------------------------------
sub getCookie {
  my $cookieName = $O2::Cgi::CGI->urlDecode(shift);
  return undef unless $ENV{HTTP_COOKIE};
  
  my $HTTP_COOKIE = $ENV{HTTP_COOKIE};
  debug "Reading cookie: $HTTP_COOKIE";
  
  $HTTP_COOKIE =~ s/=\s*;/=0;/;
  my @cookies = split /;\s+/, $HTTP_COOKIE;
  my %decodedCookies;
  foreach my $cookie (@cookies) {
    my ($key, $value) = $cookie =~ m{ ([^=]+) = (.*) }xms;
    my $decodedKey = $O2::Cgi::CGI->urlDecode($key);
    $decodedCookies{$decodedKey} = $O2::Cgi::CGI->urlDecode($value);
  }

  return %decodedCookies unless $cookieName;
  return $decodedCookies{$cookieName};
}
#--------------------------------------------------------------------------------------------
sub deleteCookie {
  my %cookie;
  if (@_ == 1) {
    $cookie{name} = shift;
  }
  else {
    %cookie = @_;
  }
  $cookie{expires} = time - 86400;
  $cookie{value}   = '';
  
  return &setCookie(%cookie);
}
#--------------------------------------------------------------------------------------------
sub setCookie {
  my %cookie;
  if (@_ == 2) {
    $cookie{name}  = shift;
    $cookie{value} = shift;
  }
  else {
    %cookie = @_;
    die "No name supplied for setCookie" unless $cookie{name};
  }
  $cookie{name}  = $O2::Cgi::CGI->urlEncode( $cookie{name}  );
  $cookie{value} = $O2::Cgi::CGI->urlEncode( $cookie{value} );
  
  my $path = defined $cookie{path} ? $cookie{path} : '/';
  my $cookie = "$cookie{name}=$cookie{value};";
  $cookie .= " expires=" . &_getTime( $cookie{expires} ) . ";" if exists $cookie{expires};
  $cookie .= " domain=$cookie{domain};"                        if exists $cookie{domain};
  $cookie .= " path=$path;";
  
  return 'Set-Cookie', $cookie;
}
#--------------------------------------------------------------------------------------------
sub _getTime {
  my ($time) = @_;
  my @time  = gmtime $time;
  my @days  = qw(Sun Mon Tue Wed Thu Fri Sat);
  my @month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  return
      $days[ $time[6] ] . ", $time[3]-" . $month[ $time[4] ] . "-" . ($time[5]+1900) . " "
    . sprintf "%02d:%02d:%02d GMT", $time[2], $time[1], $time[0];
}
#--------------------------------------------------------------------------------------------
1;
