package O2::Template::Taglibs::Html::Slides;

use strict;

use base 'O2::Template::Taglibs::Html';

#-----------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    slides => 'postfix',
  );
  $obj->addJsFile(  file => 'util/urlMod'         );
  $obj->addJsFile(  file => 'windowUtil'          );
  $obj->addJsFile(  file => 'DOMUtil'             );
  $obj->addJsFile(  file => 'taglibs/html/slides' );
  $obj->addCssFile( file => 'taglibs/html/slides' );
  return $obj, %methods;
}
#-----------------------------------------------------------------------------
sub slides {
  my ($obj, %params) = @_;

  $obj->_normalizeIndentation( \$params{content} );

  my $html = '';

  my @slides = split /^ \s* ---- \n /xms, $params{content};
  foreach my $slideContent (@slides) {
    $params{header} = $obj->_getHeader(    \$slideContent ) ||    $params{header} || '';
    $params{footer} = $obj->_getFooter(    \$slideContent ) ||    $params{footer} || '';
    my $align       = $obj->_getAlignment( \$slideContent ) || lc $params{align}  || 'center';
    $obj->_parseEmphasizedText(   \$slideContent );
    $obj->_parseImages(           \$slideContent );
    $obj->_parsePreFormattedText( \$slideContent );
    $obj->_parseLinks(            \$slideContent );

    # Parse o2 tags and variables in the slides:
    $obj->{parser}->_parse( \$slideContent );

    $slideContent =~ s{ \n }{<br>\n}xmsg;

    $html .= "<div class='slide'>\n"
          .  "<div class='header'>$params{header}</div>\n"
          .  "<div class='slideMain ${align}Align'>\n$slideContent</div>\n"
          .  "<div class='footer'>$params{footer}</div>\n"
          .  "</div>\n";
  }
  $html = "<div class='slides' style='visibility: hidden;'>\n"
        . "$html\n"
        . "</div>\n";
  return $html;
}
#-----------------------------------------------------------------------------
sub _getHeader {
  my ($obj, $contentRef) = @_;
  return '' unless ${$contentRef} =~ m{ ^ \s* HEADER:: }xms;
  ${$contentRef} =~ s{ ^ \s* HEADER:: \s* (.*?) \s* \n }{}xms;
  return $1;
}
#-----------------------------------------------------------------------------
sub _getFooter {
  my ($obj, $contentRef) = @_;
  return '' unless ${$contentRef} =~ m{ ^ \s* FOOTER:: }xms;
  ${$contentRef} =~ s{ ^ \s* FOOTER:: (.*?) \n }{}xms;
  return $1;
}
#-----------------------------------------------------------------------------
sub _getAlignment {
  my ($obj, $contentRef) = @_;
  return '' unless ${$contentRef} =~ m{ ^ \s* ALIGN:: }xms;
  ${$contentRef} =~ s{ ^ \s* ALIGN:: (\w+) \n }{}xms;
  return lc $1;
}
#-----------------------------------------------------------------------------
sub _parseEmphasizedText {
  my ($obj, $contentRef) = @_;
  ${$contentRef} =~ s{ \[\[EM: (.*?) ]] }{<em>$1</em>}xmsg;
}
#-----------------------------------------------------------------------------
sub _parsePreFormattedText {
  my ($obj, $contentRef) = @_;
  ${$contentRef} =~ s{ \[\[PRE: \s* (.*?) \s* ]] }{<pre>$1</pre>}xmsg;
  ${$contentRef} =~ s{ (\S+ [^\n]+?) <pre> }{$1<pre class="inlinePre">}xmsg;
  while (${$contentRef} =~ m{ <pre> .*? \n .*? </pre> }xms) {
    ${$contentRef} =~ s{ (<pre> .*?) \n (.*? </pre>) }{$1<br>$2}xmsg;
  }
}
#-----------------------------------------------------------------------------
sub _parseLinks {
  my ($obj, $contentRef) = @_;
  ${$contentRef} =~ s{ \[\[ (.*?) ]] }{<a href="$1" target="_blank">$1</a>}xmsg;
}
#-----------------------------------------------------------------------------
sub _parseImages {
  my ($obj, $contentRef) = @_;
  ${$contentRef} =~ s{ \[\[image (.*?) ]] }{<img$1>}xmsg;
}
#-----------------------------------------------------------------------------
sub _normalizeIndentation {
  my ($obj, $contentRef) = @_;
  ${$contentRef} =~ s{ \A \n }{}xms;
  my $minIndentation = 100;
  my @lines = split /\n/, ${$contentRef};
  foreach my $line (@lines) {
    if ($line && $line =~ m{ \A (\s*) \S }xms) {
      my $indentation = length $1;
      $minIndentation = $indentation if $indentation < $minIndentation;
    }
  }
  foreach my $i (0 .. @lines-1) {
    next unless $lines[$i];
    for my $j (1 .. $minIndentation) {
      $lines[$i] =~ s{ \A \s }{}xms;
    }
  }
  ${$contentRef} = join("\n", @lines);
}
#-----------------------------------------------------------------------------
1;
