package O2::Template::Critic::Policy::ProhibitActionAttributeInO2Form;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Found action attribute in form tag - use urlMod attributes instead (if possible)';
Readonly::Scalar my $EXPL => $DESC;

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
  return 1;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::O2Tag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $tagName = lc $element->getTagName();
  return if $tagName ne 'form';
  foreach my $child ($element->getChildren()) {
    if (ref($child) eq 'O2::Template::Node::Attribute' && lc($child->getAttributeKey()) eq 'action') {
      return $obj->violation($DESC, $EXPL, $element);
    }
  }
  return;
}
#-----------------------------------------------------------------------------
1;
