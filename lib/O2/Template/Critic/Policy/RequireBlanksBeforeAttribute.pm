package O2::Template::Critic::Policy::RequireBlanksBeforeAttribute;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Found attribute not preceded by white space';
Readonly::Scalar my $EXPL => $DESC;

#-----------------------------------------------------------------------------
sub new {
  my ($package, %config) = @_;
  return bless {}, $package;
}
#-----------------------------------------------------------------------------
sub getSupportedParameters {
  return ();
}
#-----------------------------------------------------------------------------
sub getDefaultSeverity {
  return 4;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::Attribute );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  if (!$element->getPreviousSibling()->isa('O2::Template::Node::Blanks')) {
    return $obj->violation($DESC, $EXPL, $element);
  }
  return;
}
#-----------------------------------------------------------------------------
1;
