package O2::Template::Critic::Policy::ProhibitHardTabs;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Hard tabs used';
Readonly::Scalar my $EXPL => 'A tab character was found in the template';

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
  return 4;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::Root );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my @violations;
  my @lines = split /\n/, $element->getValue();
  my $lineNumber = 1;
  foreach my $line (@lines) {
    if (my ($stringBeforeTab) = $line =~ m{ \A (.*) \t }xms) {
      push @violations, $obj->violation($DESC, $EXPL, $element, $lineNumber, length $stringBeforeTab);
    }
    $lineNumber++;
  }
  return \@violations;
}
#-----------------------------------------------------------------------------
1;
