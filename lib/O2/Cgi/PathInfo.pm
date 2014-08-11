package O2::Cgi::PathInfo;

use strict;

#--------------------------------------------------------------------------------------------
sub getPathInfo {
  my (%type) = @_;

  my $pathInfo = $ENV{PATH_INFO};
  
  if (!exists $type{type}) {
    if (wantarray) {
      my @arr = split '/', $pathInfo;
      shift @arr;
      return @arr;
    }
    return $pathInfo;
  }
  else {
    my @arr = split '/', $pathInfo;
    shift @arr;
    $type{delimiter} = exists $type{delimiter} ? $type{delimiter} : "=";
    my (%tmp, $item);
    foreach $item (@arr) {
      $item =~ m/(\w*)(?:$type{delimiter}(\w*))?/;
      $tmp{$1} = length ($2) ? $2 : '' if $1;
    }
    return %tmp;
  }
}
#--------------------------------------------------------------------------------------------
1;
