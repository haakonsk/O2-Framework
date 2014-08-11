package O2::Template::Node::Anonymous;

use strict;

use base 'O2::Template::Node';

#-----------------------------------------------------------------------------
sub setGrammarRuleName {
  my ($obj, $rule) = @_;
  $obj->{grammarRuleName} = $rule;
}
#-----------------------------------------------------------------------------
sub getGrammarRuleName {
  my ($obj) = @_;
  return $obj->{grammarRuleName};
}
#-----------------------------------------------------------------------------

1;
