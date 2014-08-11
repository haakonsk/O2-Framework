package O2::Template::Node::Root;

use strict;

use base 'O2::Template::Node';

#-----------------------------------------------------------------------------
sub getParent {
  my ($obj) = @_;
  die "Can't call getParent on root node!";
}
#-----------------------------------------------------------------------------

1;
