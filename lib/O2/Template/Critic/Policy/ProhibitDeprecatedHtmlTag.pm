package O2::Template::Critic::Policy::ProhibitDeprecatedHtmlTag;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

my %deprecatedTags = (
  applet   => 'object',
  basefont => '',
  center   => '',
  dir      => 'ul',
  font     => '',
  isindex  => 'form',
  menu     => 'ul',
  s        => '',
  strike   => '',
  u        => '',
  xmp      => '',
);

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
  my $tagName = lc $element->getTagName();
  if (defined $deprecatedTags{$tagName}) {
    my $replacement = $deprecatedTags{$tagName};
    my $desc = "Found deprecated html tag <$tagName>";
    $desc   .= ", use <$replacement> instead" if $replacement;
    return $obj->violation($desc, $desc, $element);
  }
  return;
}
#-----------------------------------------------------------------------------
1;
