package O2::Template::Critic::Policy;

use strict;

#-----------------------------------------------------------------------------
sub new {
  my ($package) = @_;
  my $obj = bless {}, $package;
  return $obj;
}
#-----------------------------------------------------------------------------
sub violation {
  my ($obj, $description, $explanation, $element, $line, $column) = @_;
  require O2::Template::Critic::Violation;
  return O2::Template::Critic::Violation->new($description, $explanation, $element, $line, $column);
}
#-----------------------------------------------------------------------------
sub setSeverity {
  my ($obj, $severity) = @_;
  $obj->{severity} = $severity;
}
#-----------------------------------------------------------------------------
sub getSeverity {
  my ($obj) = @_;
  return $obj->{severity} || $obj->getDefaultSeverity();
}
#-----------------------------------------------------------------------------
sub _getUtil {
  my ($obj) = @_;
  if (!$obj->{util}) {
    require O2::Template::Util;
    $obj->{util} = O2::Template::Util->new();
  }
  return $obj->{util};
}
#-----------------------------------------------------------------------------
1;
