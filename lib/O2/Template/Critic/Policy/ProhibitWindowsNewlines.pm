package O2::Template::Critic::Policy::ProhibitWindowsNewlines;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

Readonly::Scalar my $DESC => 'Found return character (windows newline)';
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
  return 4;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::Root );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  if (my ($stringBeforeWindowsNewline) = $element->getValue() =~ m{ \A ([^\r]*) \r }xms) {
    my $currentLine = $stringBeforeWindowsNewline =~ m{ \n [^\n]* \z }xms;
    $stringBeforeWindowsNewline =~ s{ ([^\n]) }{}xmsg;
    my $line = length $stringBeforeWindowsNewline;
    return $obj->violation($DESC, $EXPL, $element, $line, length $currentLine);
  }
}
#-----------------------------------------------------------------------------
1;
