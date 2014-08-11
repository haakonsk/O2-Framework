package O2::Template::Critic::Policy::RequireForeachWithIn;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Use the "in" type of <o2 foreach> (see doc)';
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
  return qw( Node::O2Tag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $tagName = $element->getTagName();
  return if $tagName ne 'foreach';
  my ($loop) = $element->getValue() =~ m{ \A <o2 \s+ foreach \s+ (\" [^\"]+ \" | \' [^\']+ \') }xms;
  return $obj->violation($DESC, $EXPL, $element) unless $loop;
  if ($loop !~ m{ \s+ in \s+ }xms) {
    return $obj->violation($DESC, $EXPL, $element);
  }
  return;
}
#-----------------------------------------------------------------------------
1;
