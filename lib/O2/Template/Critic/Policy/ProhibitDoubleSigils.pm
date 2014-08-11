package O2::Template::Critic::Policy::ProhibitDoubleSigils;

use strict;
use Readonly;

Readonly::Scalar my $DESC => 'Double-sigil dereference';
Readonly::Scalar my $EXPL => $DESC;

use base 'O2::Template::Critic::Policy';

#-----------------------------------------------------------------------------
sub new {
  my ($package, %config) = @_;
  my $obj = bless {}, $package;
  return $obj;
}
#-----------------------------------------------------------------------------
sub getSupportedParameters {
  return ();
}
#-----------------------------------------------------------------------------
sub getDefaultSeverity {
  return 3;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::Variable );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  return $obj->violation($DESC, $EXPL, $element) if $element->getValue() =~ m{ \A [@%] \$ }xms;
  return;
}
#-----------------------------------------------------------------------------
1;
