package O2::Javascript::Data;

use strict;

#-----------------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless {}, $pkg;
}
#-----------------------------------------------------------------------------------------
# returns javascript representation of a perl datastructure
sub dump {
  my ($obj, $item) = @_;
  return 'null' unless defined $item;
  return '[' . join (',', map { $obj->dump($_)                                   }      @{$item}) . ']' if ref $item eq 'ARRAY';
  return '{' . join (',', map { $obj->dump($_) . ':' . $obj->dump( $item->{$_} ) } keys %{$item}) . '}' if ref $item eq 'HASH';
  return 0 if !ref ($item) && $item eq '0';
  return $item if $item =~ m/^[1-9]\d*$/; # don't quote numbers (except those starting with '0', since they are interpreted as octal numbers)
  $item = $obj->escapeForSingleQuotedString($item);
  return "'$item'";
}
#-----------------------------------------------------------------------------------------
sub escapeForSingleQuotedString {
  my ($obj, $string) = @_;
  return $string unless $string;
  $string =~ s{ \\       }{\\\\}xmsg;
  $string =~ s{ \n       }{\\n}xmsg;
  $string =~ s{ \r       }{\\r}xmsg;
  $string =~ s{ \x{2028} }{\\\x{2028}}xmsg; # Line separator
  $string =~ s{ \x{2029} }{\\\x{2029}}xmsg; # Paragraph separator
  $string =~ s{ \'       }{\\\'}xmsg;
  
  $string =~ s{\[\#macro id=(\d+)\#\]}{[#macro id=$1 escapeForSingleQuotedString#]}msg;
  
  return $string;
}
#-----------------------------------------------------------------------------------------
# converts "javascript-xml" to a perl datastructure. Xml can be generated with dumpXml() in datadumper.js.
# "<array><item>element0</item><item><hash><item>name</item><item>Kurt</item></hash></item></array>"
# would return ['element0',{name=>'Kurt'}]
sub undumpXml {
  my ($obj, $xml) = @_;
  return $xml if index ($xml, '<') == -1; # string
  my ($tag, $block, $endStart) = $obj->_findBlock($xml, 0);
  return [] if $tag eq 'array' && $block eq ''; # fix to avoid <array></array> returning ['']
  return {} if $tag eq 'hash'  && $block eq ''; # fix to avoid <hash></hash> returning {''=>undef}
  return [ $obj->undumpXml($block, 0) ] if $tag eq 'array';
  return { $obj->undumpXml($block, 0) } if $tag eq 'hash';
  return undef if $tag eq 'null';

  if ($tag eq 'item') {
    my @array = ( $obj->undumpXml($block) ); # add first <item> content
    while ($endStart != -1) { # parse siblings
      ($tag, $block, $endStart) = $obj->_findBlock($xml, $endStart+1);
      push @array, $obj->undumpXml($block) unless $endStart == -1; # add unless we reach end of block
    }
    return @array;
  }
}
#-----------------------------------------------------------------------------------------
# finds matching close-tag (not necessarily efficiently...)
sub _findBlock {
  my ($obj, $xml, $startPos) = @_;

  $obj->_debug("_findBlock($xml,$startPos)");
  my $openStart = index  $xml, '<', $startPos;
  my $openEnd   = index  $xml, '>', $openStart; # end of openingtag
  my $startTag  = substr $xml, $openStart, $openEnd-$openStart+1;
  my ($tag, $attr, $selfClosing) = $startTag =~ m|<(\w+)(.*?)(/?)|s;
  return ($tag, undef, $openEnd) if $selfClosing;

  # look for endtags. count start/end
  my $endStart = $openStart;
  my $block;
  while ($endStart != -1) {
    $endStart = index  $xml, "</$tag>",  $endStart+1;
    $block    = substr $xml, $openEnd+1, $endStart-$openEnd-1;
    my (@openTags)   = $block =~ m|(<$tag>)|g;
    my (@closedTags) = $block =~ m|(</$tag>)|g;
    last if @openTags == @closedTags;
  }
  $obj->_debug("return ($tag, $block, $endStart)");
  return ($tag, $block, $endStart);
}
#-----------------------------------------------------------------------------------------
sub _debug {
  my ($obj, $msg) = @_;
#  print $msg, "\n";
#  print "<font color=#0000FF>$msg</font><br>"; 
}
#-----------------------------------------------------------------------------------------
1;
