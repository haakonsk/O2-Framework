package O2::Template::Critic::Policy::RequireCorrectClosingTag;

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
  return qw( Node::HtmlTag Node::O2Tag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $content = $element->getValue();
  if (my ($isO2Tag, $startTag, $endTag) = $content =~ m{ \A < ((?:o2\s+)?)  ([^\s/>]+)  .*  </  ([^>]+)  > \z }xms) {
    if (   !$isO2Tag && $startTag ne $endTag
        ||  $isO2Tag && ($endTag ne 'o2' && $endTag ne "o2:$startTag")) {
      my $desc = "Wrong end tag. Found '</$endTag>', expected '</" . ($isO2Tag ? 'o2:' : '') . "$startTag>'";
      my ($line, $column) = $element->getLocation();
      $line  += $obj->_getUtil()->countCharacterInString( "\n", $element->getValue() );
      $column = $obj->_getUtil()->countCharactersAfter(   "\n", $element->getValue() ) - length("</$endTag>") + 1;
      return $obj->violation($desc, $desc, $element, $line, $column);
    }
  }
}
#-----------------------------------------------------------------------------
1;
