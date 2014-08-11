package O2::Template::Critic::Policy::ProhibitUnnecessaryBlanks;

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
  return 1;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::Root );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my @violations;
  my $content = $element->getValue();
  # No space before the first character in the file
  my $desc = 'Unnecessary whitespace at the beginning of the file';
  if ($content =~ m{ \A \s+ }xms) {
    push @violations, $obj->violation($desc, $desc, $element, 1, 1);
  }
  # No space directly before a newline (except if the line consists only of spaces)
  my @lines = split /\n/, $content;
  $desc = 'Unnecessary whitespace at the end of the line';
  my $lineNumber = 1;
  foreach my $line (@lines) {
    if (my ($lineWithoutFinalBlanks) = $line =~ m{ \A ( .* \S ) \s+ \z }xms) {
      push @violations, $obj->violation($desc, $desc, $element, $lineNumber, length $lineWithoutFinalBlanks);
    }
    $lineNumber++;
  }
  # Only a single newline after the final non-whitespace character
  $desc = 'Unnecessary whitespace at the end of the file';
  if (my ($stringBeforeFinalBlanks) = $content =~ m{ \A (.*) \n \s+ \z }xms) {
    $stringBeforeFinalBlanks =~ s{ [^\n] }{}xmsg;
    $lineNumber = length $stringBeforeFinalBlanks;
    push @violations, $obj->violation($desc, $desc, $element, scalar(@lines)+1, 1);
  }
  return \@violations;
}
#-----------------------------------------------------------------------------
1;
