package O2::Template::Critic::Policy::RequireTagnameInO2EndTag;

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
  return 2;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::O2Tag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  if ($element->getValue() =~ m{ </o2> \z }xms) {
    my @children = $element->getChildren();
    my $tagName = $children[1]->getValue();
    my $desc = "Missing tagname in end tag. Found '</o2>', expected '</o2:$tagName>'";
    if ($element->getValue() =~ m{ \n }xms) {
      my ($line, $column) = $element->getLocation();
      $line  += $obj->_getUtil()->countCharacterInString( "\n", $element->getValue() );
      $column = $obj->_getUtil()->countCharactersAfter(   "\n", $element->getValue() ) - length('</o2>') + 1;
      return $obj->violation($desc, $desc, $element, $line, $column);
    }
    return $obj->violation($desc, $desc, $element);
  }
}
#-----------------------------------------------------------------------------
1;
