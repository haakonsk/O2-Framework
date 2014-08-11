package O2::Template::TreeParser;

use strict;

use O2 qw($context);

#-----------------------------------------------------------------------------
sub new {
  my ($package) = @_;
  my $obj = bless {
    _lineNumber  => 1,
    _currentLine => '',
  }, $package;
  my $grammar = $context->getSingleton('O2::File')->getFile("o2://lib/O2/Template/o2mlGrammar.txt");
  require Parse::RecDescent;

#  $::RD_TRACE = 1; # Uncomment to see how the parsing proceeds
  $::RD_AUTOACTION = q {
    my @items = @item;
    shift @items;
    bless \@items, $item[0];
  }; # So the RecDescent Parser creates a tree for us

  my $parser = Parse::RecDescent->new($grammar);
  $obj->{parser} = $parser;
  return $obj;
}
#-----------------------------------------------------------------------------
sub transformTree {
  my ($obj, $node) = @_;
  my $o2Node = $obj->_createO2Node($node);
  return $obj->_transformTree($node, $o2Node);
}
#-----------------------------------------------------------------------------
sub _transformTree {
  my ($obj, $node, $o2Node) = @_;
  $obj->_updateLocation($node, $o2Node);
  foreach my $elm ( @{$node} ) {
    if (ref ($elm) eq 'ARRAY') {
      foreach my $subElm ( @{$elm} ) {
        $o2Node->addChild( $obj->_transformTree($subElm, $obj->_createO2Node($subElm)) ) if ref $subElm;
      }
    }
    elsif (ref $elm) {
      $o2Node->addChild( $obj->_transformTree($elm, $obj->_createO2Node($elm)) );
    }
  }
  return $o2Node;
}
#-----------------------------------------------------------------------------
sub _templateToTree {
  my ($obj, $templatePath) = @_;
  my $templateContent = $context->getSingleton('O2::File')->getFile($templatePath, keepFileEncodingLine => 1);
  $templateContent    = $obj->_commentOutJsAndCss($templateContent);

  my $tree;
  my $timeout = 60; # Don't let the script run forever!
  my $t0 = time;
  eval {
    local $SIG{ALRM} = sub { die 'alarm' };
    alarm $timeout; # Set alarm
    $tree = $obj->getParser()->root($templateContent);
    alarm 0; # Cancel alarm
  };
  my $errorMsg = $@;
  if ($errorMsg || !$tree) {
    my $dt = time - $t0;
    require O2::Util::SendMail;
    my $mailer = O2::Util::SendMail->new();
    $mailer->send(
      from    => 'haakonsk@redpill-linpro.com',
      to      => 'haakonsk@redpill-linpro.com',
      subject => "Template parse error: $templatePath",
      body    => "$dt seconds\n\n$templateContent",
    );
  }
  if ($errorMsg =~ m{ alarm }xms) {
    die "Couldn't parse template $templatePath. Timed out after $timeout seconds. Maybe there's an end tag without a corresponding opening tag?";
  }
  die $errorMsg if $errorMsg;
  die "Unable to parse template $templatePath." unless $tree;
  
#  use Data::Dumper; print Dumper($tree);
  shift @{$tree};
  return $tree;
}
#-----------------------------------------------------------------------------
# The parser should more or less ignore css/javascript. To accomplish that, we add html
# comment tags around the css or javascript if it's not there already:
# XXX Count number of open o2 tags, so we don't insert closing html comment too early.
sub _commentOutJsAndCss {
  my ($obj, $str) = @_;
  my @lines = split /\n/, $str;
  my $expectingEndTag = 0;
  my $indent;
  for (my $i = 0; $i < @lines; $i++) {
    my $line = $lines[$i];
    if (!$expectingEndTag
        && (($indent) = $line =~ m{ \A (\s*) < (script | style | o2[ ]addJs | o2[ ]addCss) (?: [ >]) }xms)
        && $line !~ m{ <!-- }xms
        && $line !~ m{ </   }xms) { # Found an end tag on the same line as the start tag
      my $originalI = $i;
      while ($lines[++$i] =~ m{ \A \s* \z }xms) {} # Skip blank lines
      if ($lines[$i] !~ m{ \A (\s*)   (?: // \s* )?  <!-- }xms) {
        # Insert html comment after opening tag
        $i = $originalI;
        $lines[$i] .= '<!--';
        $expectingEndTag = 1;
      }
    }
    elsif ($expectingEndTag && (($indent) = $line =~ m{ \A (\s*) </ (script | style | o2:addJs | o2:addCss | o2 | o2::addJs | o2::addCss) > }xms)) {
      my $originalI = $i;
      if ($lines[--$i] =~ m{ \A \s* \z }xms) {} # Skip blank lines (backward)
      if ($lines[$i] !~ m{ \A (\s*)   (?: // \s* )?   --> }xms) {
        # Insert html comment end
        my ($indent) = $lines[$i] =~ m{ \A (\s*) }xms;
        $lines[$i+1] = "$indent-->$lines[$i+1]";
        $expectingEndTag = 0;
        $i = $originalI;
      }
    }
    elsif ($expectingEndTag) {
      $lines[$i] =~ s{ --> }{- - >}xmsg; # Don't let the comment close too early
    }
  }
  $str = join "\n", @lines;
#  print $str;
  return $str;
}
#-----------------------------------------------------------------------------
sub templateToNodeTree {
  my ($obj, $templatePath) = @_;
  $obj->{tokens} = undef; # Reset cache
  $obj->{_lineNumber} = 1;
  my $tree = $obj->_templateToTree($templatePath);
  my $nodeTree = $obj->transformTree($tree);
  return $nodeTree;
}
#-----------------------------------------------------------------------------
# Update line number and currentLine.
# XXX Doesn't work as good as I had hoped. Gotta find another way.
sub _updateLocation {
  my ($obj, $node, $o2Node) = @_;
  $o2Node->setLocation($obj->{_lineNumber}, length $obj->{_currentLine});
  my $content = '';
  foreach my $i (0 .. @{$node}-1) {
    $content .= $node->[$i] unless ref $node->[$i];
  }
  my $numNewlines = $context->getSingleton('O2::Template::Util')->countCharacterInString( "\n", $content );
  $obj->{_lineNumber} += $numNewlines;
  if ($numNewlines > 0) {
    $obj->{_currentLine} .= $content;
  }
  else {
    $obj->{_currentLine} = $content;
    $obj->{_currentLine} =~ s{ \A .* \n ([^\n]*) \z }{$1}xms;
  }
  return;
}
#-----------------------------------------------------------------------------
sub _createO2Node {
  my ($obj, $node) = @_;
  my $className = 'O2::Template::Node::' . ucfirst ref $node;
  my $content = join '', $obj->_getTokens($node);
  my $o2Node;
  eval {
    eval "require $className;";
    $o2Node = $className->new($content);
  };
  if ($@) {
    require O2::Template::Node::Anonymous;
    $o2Node = O2::Template::Node::Anonymous->new();
    $o2Node->setGrammarRuleName(ref $node);
  }
  return $o2Node;
}
#-----------------------------------------------------------------------------
sub _hasAnonymousChildren {
  my ($obj, $node) = @_;
  foreach my $child ($node->getChildren()) {
    return 1 if ref ($child) eq 'O2::Template::Node::Anonymous';
  }
  return 0;
}
#-----------------------------------------------------------------------------
sub getTokens {
  my ($obj, $tree) = @_;
  $obj->{tokens} = undef;
  return $obj->_getTokens($tree);
}
#-----------------------------------------------------------------------------
sub _getTokens {
  my ($obj, $tree) = @_;
  my $treeId = scalar $tree;
  return @{ $obj->{tokens}->{$treeId} }  if $obj->{tokens}->{$treeId}; # Retrieve from cache
  
  my @tokens;
  foreach my $element ( @{$tree} ) {
    if (ref $element eq '_alternation_1_of_production_1_of_rule_htmlComment') {
      # Hack for html comments, because the rule for it uses (negative) lookahead:
      for my $i (0 .. @{$element}-1) {
        my $elm = $element->[$i];
        delete $element->[$i] if !ref ($elm) && $elm eq '->' && $i >= 1 && $element->[$i-1] eq  '-';
      }
      push @tokens, $obj->_getTokens($element);
    }
    elsif (ref $element) {
      push @tokens, $obj->_getTokens($element);
    }
    else {
      push @tokens, $element;
    }
  }
  $obj->{tokens}->{$treeId} = \@tokens; # Store in cache
  return @tokens;
}
#-----------------------------------------------------------------------------
sub treeToString {
  my ($obj, $tree) = @_;
  die 'Strange error' if scalar @{$tree} != 1;
  return $obj->_subTreeToString($tree);
}
#-----------------------------------------------------------------------------
sub _subTreeToString {
  my ($obj, $tree) = @_;
  my @tokens = $obj->getTokens($tree);
  return join '', @tokens;
}
#-----------------------------------------------------------------------------
sub getParser {
  my ($obj) = @_;
  return $obj->{parser};
}
#-----------------------------------------------------------------------------
1;
