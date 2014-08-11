package O2::Template::Critic::Policy::RequireO2Tag;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

my %tags = (
  input  => 'input',
  form   => 'form',
  a      => ['link', 'popupWindow'],
  html   => 'header',
  select => 'select',
  option => 'option',
#  link  => 'addCssFile',
  script => 'addJsFile',
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
  return 1;
}
#-----------------------------------------------------------------------------
sub appliesTo {
  return qw( Node::HtmlTag );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  foreach my $htmlTag (keys %tags) {
    if (lc($element->getValue()) =~ m{ \A < $htmlTag \s+ }xms) {
      my $betterTag  =  '<o2 ' . (ref( $tags{$htmlTag} ) eq 'ARRAY'  ?  (join ' .. > or <o2 ', @{ $tags{$htmlTag} })  :  $tags{$htmlTag}) . ' .. >';
      my $desc = "Found <$htmlTag .. >. It may be better to use $betterTag instead";
      return $obj->violation($desc, $desc, $element);
    }
  }
  return;
}
#-----------------------------------------------------------------------------
1;
