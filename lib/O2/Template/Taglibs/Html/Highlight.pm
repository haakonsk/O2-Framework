package O2::Template::Taglibs::Html::Highlight;

use strict;

use base 'O2::Template::Taglibs::Html';

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my %methods = (
    code => 'postfix',
  );
  my $obj = bless { parser => $params{parser} }, $package;
  $obj->addCssFile( file => 'highlight' );
  return ($obj, %methods);
}
#----------------------------------------------------
sub code {
  my ($obj, %params) = @_;

  # Try to get the indentation right
  $params{content} =~ s{ \s+ \z }{}xms;
  my @lines = split /\n/, $params{content};
  my $firstLine = shift @lines;

  my $minNumberOfBlanksFirst = 1000;
  foreach my $line (@lines) {
    next if $line =~ m{ \A \s* \z }xms;
    $line =~ m{ \A (\s*) \S }xms;
    my $blanks = $1;
    my $numBlanksFirst = length $blanks;
    if ($numBlanksFirst < $minNumberOfBlanksFirst) {
      $minNumberOfBlanksFirst = $numBlanksFirst;
    }
  }
  for (my $i = 0; $i < @lines; $i++) {
    $lines[$i] = substr $lines[$i], $minNumberOfBlanksFirst if $minNumberOfBlanksFirst < length $lines[$i];
  }
  unshift @lines, $firstLine;
  my $content = join "\n", @lines;

  require O2::Util::ExternalModule;
  my $highlighter;
  $params{lang} ||= '';
  if ($params{lang} =~ m{ \A (?: o2ml | html ) \z }xmsi) {
    O2::Util::ExternalModule->require('Syntax::Highlight::HTML');
    $highlighter = Syntax::Highlight::HTML->new();
    $content = $highlighter->parse($content);
    $content = $obj->_removePreTag($content);
    $obj->addCssFile( file => 'highlight/html' );
  }
  elsif ($params{lang} =~ m{ \A perl \z }xmsi) {
    O2::Util::ExternalModule->require('Syntax::Highlight::Engine::Simple::Perl');
    $highlighter = Syntax::Highlight::Engine::Simple::Perl->new();
    $content = $highlighter->doStr(
      str       => $content,
      tab_width => 2,
    );
    $obj->addCssFile( file => 'highlight/perl' );
  }
  elsif ($params{lang} =~ m{ \A css \z }xmsi) {
    O2::Util::ExternalModule->require('Syntax::Highlight::CSS');
    $highlighter = Syntax::Highlight::CSS->new();
    eval {
      $content = $highlighter->parse($content);
    };
    die "Error with <o2 code>: $@" if $@;
    $content = $obj->_removePreTag($content);
    $obj->addCssFile( file => 'highlight/css' );
  }
  $obj->_escapeDollars( \$content );
  $content =~ s{ \A \n+ }{}xms;
  $content =~ s{ \\n }{<br>}xmsg;
  return "<code class='highlight $params{lang}' " . $obj->_packTagAttribs(%params) . ">$content</code>";
}
#----------------------------------------------------
# Remove the surrounding pre tag that was added during highlighter->parse
sub _removePreTag {
  my ($obj, $str) = @_;
  $str =~ s{ \A  <pre [^>]*? > \n? }{}xms;
  $str =~ s{     </pre> \n? \z     }{}xms;
  return $str;
}
#----------------------------------------------------
1;
