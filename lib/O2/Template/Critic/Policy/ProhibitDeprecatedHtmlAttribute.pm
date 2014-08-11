package O2::Template::Critic::Policy::ProhibitDeprecatedHtmlAttribute;

use strict;
use Readonly;

use base 'O2::Template::Critic::Policy';

my %illegalAttribute = (
  align       => '',
  alink       => '',
  background  => '',
  bgcolor     => '',
  border      => 'except: table',
  clear       => '',
  color       => '',
  compact     => '',
  height      => 'except: iframe, img, object',
  hspace      => '',
  language    => '',
  link        => '',
  noshade     => '',
  nowrap      => '',
  size        => 'except: input, select',
  start       => '',
  text        => '',
  type        => 'li, ol, ul',
  value       => 'li',
  version     => '',
  vlink       => '',
  vspace      => '',
  width       => 'except: iframe, img, object, table, col, colgroup',
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
  return qw( Node::AttributeKey );
}
#-----------------------------------------------------------------------------
sub violates {
  my ($obj, $element, $root) = @_;
  my $tag = $element->getTag();
  return if ref($tag) eq 'O2::Template::Node::O2Tag';
  my $attributeKey = lc $element->getValue();
  if (defined $illegalAttribute{ $attributeKey }) {
    my $desc = "Found deprecated attribute '$attributeKey'";
    if (my $str = $illegalAttribute{ $attributeKey }) {
      if (my ($tags) = $str =~ m{ \A except: \s* (.+) \z }xms) {
        my @exceptionTags = split /,\s*/, $tags;
        $desc .= " which is legal only with the following tags: <" . join('>, <', @exceptionTags) . '>';
        foreach my $tagName (@exceptionTags) {
          return if lc($tag->getTagName()) eq $tagName; # Found an exception, so it was ok to use the attribute in this context
        }
      }
      else {
        my @tags = split /,\s*/, $str; # The tags that cannot have this attribute
        $desc .= " which is illegal with the following tags: <" . join('>, <', @tags) . '>';
        my $found = 0;
        foreach my $tagName (@tags) {
          if (lc($tag->getTagName()) eq $tagName) {
            $found = 1;
            last;
          }
        }
        return unless $found; # Didn't find a tag that couldn't have this attribute
      }
    }
    return $obj->violation($desc, $desc, $element) ;
  }
  return;
}
#-----------------------------------------------------------------------------
1;
