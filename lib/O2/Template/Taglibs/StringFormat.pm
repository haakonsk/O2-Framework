package O2::Template::Taglibs::StringFormat;

use strict;

#------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    wordCut           => 'singularParam', # <o2 wordCut "30 ...">$title</o2:wordCut>
    stringCut         => 'singularParam', # <o2 stringCut "30...">$title</o2:stringCut>
    trim              => '', # <o2 trim maxLength="30" trail="...">test</o2:trim>
    uc                => '', # <o2 uc>uppercase this</o2:uc>
    lc                => '', # <o2 lc>LOWERCASE THIS</o2:lc>
    ucfirst           => '', # <o2 ucfirst>uppercase first letter</o2:ucfirst>
    lcfirst           => '', # <o2 lcfirst>uppercase first letter</o2:lcfirst>
    titlecase         => '', # <o2 titlecase>make titlecasing</o2:titlecase>
    substitute        => '', # <o2 substitute from="'" to="\'">jkdjkdj'</o2:substitute>
    substring         => '', # see doc at method
    stripTags         => 'postfix', # <o2 stripTags>$string</o2:stripTags>
    removeWhitespaces => '', # <o2 removeWhitespaces>$string</o2:removeWhitespaces>
    #trimWidth         => '', # <o2 trimWidth length="10">testtesttest</o2:trimWidth> - will become testtestte st allowing browser to break the line at will
  );
  return ($obj, %methods);
}
#----------------------------------------------------
sub uc {
  my ($obj, %params)=@_;
  return $params{content} unless $params{content};
  $params{content} =~ tr/æøå/ÆØÅ/;
  return uc $params{content};
}
#----------------------------------------------------
sub lc {
  my ($obj, %params)=@_;
  return $params{content} unless $params{content};
  $params{content} =~ tr/ÆØÅ/æøå/;
  return lc $params{content};
}
#----------------------------------------------------
sub ucfirst {
  my ($obj, %params)=@_;
  return $params{content} unless $params{content};
  $params{content} =~ s/^æ/Æ/;
  $params{content} =~ s/^ø/Ø/;
  $params{content} =~ s/^å/Å/;
  return ucfirst $params{content};
}
#----------------------------------------------------
sub lcfirst {
  my ($obj, %params) = @_;
  return $params{content} unless $params{content};
  $params{content} =~ s/^æ/Æ/;
  $params{content} =~ s/^ø/Ø/;
  $params{content} =~ s/^å/Å/;
  return lcfirst $params{content};
}
#----------------------------------------------------
sub titlecase {
  my ($obj, %params)=@_;
  return $params{content} unless $params{content};
  $params{content} =~ s/([\w\-\_æøåÆØÅ]+)/$obj->ucfirst(content => $1)/eg;
  return $params{content};
}
#----------------------------------------------------
# e.g <o2 trim maxLength="2" trail="...">test</o2:trim> becomes te...
sub trim {
  my ($obj, %params) = @_;
  my $maxLength = $params{maxLength};

  # Characters that are part of a tag must not be counted.
  my $content = $params{content};
  my @openedTags;
  while ($content =~ s{ \A  ([^<]*)  (< [\w/] [^>]* >) }{$1}xms  &&  length($1) < $params{maxLength}) {
    my $tag = $2;
    $maxLength += length($tag);
    if ($tag !~ m{ \A </ }xms) {
      my ($tagName) = $tag =~ m{ \A < (\w [^ >]*) }xms;
      push @openedTags, $tagName; # Keep track of which tags were opened, so we can close them later.
    }
    else { # This tag isn't open anymore, so we don't need to close it later.
      my ($tagName) = $tag =~ m{ \A </ (\w [^>]*) }xms;
      for my $i (@openedTags-1 .. 0) {
        my $_tag = $openedTags[$i];
        delete $openedTags[$i] if $_tag eq $tagName;
      }
    }
  }

  if ( $maxLength && length($params{content}) > $maxLength) {
    my $contentWithoutTags = $obj->stripTags( content => $params{content} );
    my $trimmed = substr($params{content},0,$maxLength);#.$params{trail};
    # We should close all opened tags:
    foreach my $tag (reverse @openedTags) {
      $trimmed .= "</$tag>" if $tag;
    }
    $trimmed .= $params{trail};
    if ($params{toolTip}) {
      return '<span title="'.$contentWithoutTags.'">'.$trimmed.'</span>';
    }
    return $trimmed;
  }
  return $params{content};
}
#----------------------------------------------------
sub substitute {
  my ($obj, %params) = @_;
  $params{content} =~ s{ \Q$params{from}\E }{$params{to}}xmsg     if $params{literalMatch};
  $params{content} =~ s{   $params{from}   }{$params{to}}xmsg unless $params{literalMatch};
  return $params{content};
}
#----------------------------------------------------
sub substring {
  my ($obj,%params) = @_;
  if (exists($params{from}) && $params{length} && $params{replacement}) {
    substr $params{content}, $params{from}, $params{length}, $params{replacement};
  }
  elsif ( exists($params{from}) && $params{length}) {
    $params{content} = substr $params{content}, $params{from}, $params{length};
  }
  elsif ($params{length}) {
    $params{content} = substr $params{content}, $params{length};
  }
  return $params{content};
}
#----------------------------------------------------
sub stripTags {
  my ($obj, %params) = @_;
  
  # If stripTags is called on a variable, we don't want to encode entities in the variable's value
  # because then there won't be any tags to strip, which makes no sense.
  my $originalCharactersToEncode;
  my $parser = $obj->{parser};
  $params{content} =~ s{ \A \s*    }{}xms;
  $params{content} =~ s{    \s* \z }{}xms;
  my ($matchedVariable) = $parser->matchVariable( $params{content} );
  if ($matchedVariable eq $params{content}) {
    $originalCharactersToEncode = $parser->getProperty('charactersToEncode');
    $parser->setProperty('charactersToEncode', []);
  }
  
  require O2::Util::String;
  my $stringModule = O2::Util::String->new();
  $parser->_parse( \$params{content} );
  my $string = $stringModule->stripTags( $params{content} );
  
  $parser->setProperty('charactersToEncode', $originalCharactersToEncode); # Restore original value
  return $string;
}
#----------------------------------------------------
sub removeWhitespaces {
  my ($obj, %params) = @_;
  $params{ content } =~ s/\n|\r|\s//g;
  $params{ content } =~ s/\\n/\n/g;
  $params{ content } =~ s/\\s/ /g;
  return $params{content};
}
#----------------------------------------------------
sub wordCut {
  my ($obj, %params) = @_;
  return $obj->stringCut(boundaries => 'yes', %params);
}
#----------------------------------------------------
sub stringCut {
  my ($obj, %params) = @_;
  $params{param} =~ m/^(\d+)(.+)/;
  my ($maxLength, $post) = ($1, $2);

  die "Error in expression '$params{param}'" unless $maxLength;

  return $params{content} unless length($params{content}) > $maxLength;

  my $boundaries = $params{boundaries} ? '\b' : '';

  $params{content} =~ m/^(.{0,$maxLength})$boundaries/s;
  my $return = $1;
  $return =~ s/\s$// if $boundaries;
  return "$return$post";
}
#----------------------------------------------------
1;
