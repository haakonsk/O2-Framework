package O2::Template::Critic::Policy::ProhibitUnopenedClosingTag;

use strict;
use Readonly;

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
  return 5;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::UnopenedEndTag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $value = $element->getValue();
  $value    =~ s{ \A \s+ }{}xms;
  my $desc = "Found closing tag ($value), but no associated opening tag";
  return $obj->violation($desc, $desc, $element);
}
#-----------------------------------------------------------------------------
1;
