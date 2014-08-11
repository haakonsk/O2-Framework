package O2::Template::Critic::Policy::ProhibitPixGif;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Found pix.gif or pixel.gif, use a css file instead to achieve the same effect';
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
  return 3;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::HtmlTag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  return if lc($element->getTagName()) ne 'img';
  my @attributes = $element->getAttributes();
  foreach my $attr (@attributes) {
    return $obj->violation($DESC, $EXPL, $element) if lc($attr->getAttributeKey()) eq 'src' && $attr->getAttributeValue() =~ m{ pix(?:el)? [.] gif \z }xmsi;
  }
  return;
}
#-----------------------------------------------------------------------------
1;
