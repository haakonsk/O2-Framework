package O2::Template::Taglibs::O2Doc::Tutorial;

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context $cgi);

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my %methods = (
    docSection    => 'postfix',
    docCode       => 'postfix',
    docCodeResult => '',
    docExample    => '',
    docHint       => '',
    docNote       => '',
    docLink       => '',
    docList       => 'postfix',
    docListItem   => '',
  );
  
  my $obj = bless { parser => $params{parser} }, $package;
  $obj->{docSectionNumber}   = 0;
  $obj->{html}               = '';
  $obj->{exampleCounter}     = 0;
  $obj->{codeExampleCounter} = 0;
  $obj->addCssFile(file => 'o2mlDocStyle');
  return $obj, %methods;
}
#----------------------------------------------------
sub docSection {
  my ($obj, %params) = @_;

  $obj->{docSectionNumber}++;

  my $html = '';
  if ($params{title}) {
    $html = "<h$obj->{docSectionNumber}>$params{title}</h$obj->{docSectionNumber}>\n";
  }

  $html .= "<p>";
  $html .= ${ $obj->{parser}->_parse(\$params{content}) };
  $obj->_escapeDollars( \$html );
  $html .= "</p>";

  $obj->{docSectionNumber}--;
  return $html;
}
#----------------------------------------------------
sub docCode {
  my ($obj, %params) = @_;
  $obj->{codeExampleCounter}++;
  $obj->{code} = $params{content};
  my $highlightTaglib = $obj->{parser}->getTaglibByName('Html::Highlight');
  return $highlightTaglib->code(%params);
}
#----------------------------------------------------
sub docCodeResult {
  my ($obj, %params) = @_;
  $params{seeGeneratedHtml}            = '' unless exists $params{seeGeneratedHtml};
  $params{seeGeneratedHtmlAsDisplayed} = '' unless exists $params{seeGeneratedHtmlAsDisplayed};

  return if !$params{seeGeneratedHtml} eq "0" && !$params{seeGeneratedHtmlAsDisplayed} eq "0";

  my $i = $obj->{codeExampleCounter};
  $obj->{code} =~ s{ \\n }{}xmsg;
  $obj->{code} = "<o2 use $params{useModule} />" . $obj->{code} if $params{useModule};

  my $resultHtml = ${ $obj->{parser}->_parse(\$obj->{code}) };
  $resultHtml =~ s{ <!-- .*? --> }{}xmsg;
  $resultHtml =~ s{ \$ }{\\\$}xmsg;

  require HTML::Entities;
  my $resultHtmlEntities = HTML::Entities::encode_entities($resultHtml);
  $resultHtmlEntities =~ s{ \A \n+ }{}xms;
  $resultHtmlEntities =~ s{ \n\n   }{\n}xmsg;
  $resultHtmlEntities =~ s{ \n     }{\<br\>\n}xmsg;

  my $html = '';
  if ($params{seeGeneratedHtml} ne "0") {
    $html .= "
<div id='codeResultHtml$i'
     class='codeExample codeExampleHtml'
     onclick='this.style.display = \"none\";'>
  <div>$resultHtmlEntities</div>
  <div style='position: relative; visibility: hidden;'>Click to close</div>
  <div style='position: absolute; bottom: 2px; right: 2px; white-space: nowrap;'>Click to close</div>
</div>";
  }
  if ($params{seeGeneratedHtmlAsDisplayed} ne "0") {
    $html .= "
<div id='codeResult$i'
     class='codeExample'>
  <div>$resultHtml</div>
  <div style='position: relative; visibility: hidden;'>Click to close</div>
  <div style='position: absolute; bottom: 2px; right: 2px; white-space: nowrap;'><a href='#' onclick='this.parentNode.parentNode.style.display = \"none\"; return false;'>Click here to close</a></div>
</div>";
  }
  $html .= "<p>";
  if ($params{seeGeneratedHtml} ne "0") {
    $html .= "<a href='#' onclick='document.getElementById(\"codeResultHtml$i\").style.display = \"block\"; return false;'>See generated HTML</a>";
  }
  if ($params{seeGeneratedHtml} ne "0" && $params{seeGeneratedHtmlAsDisplayed} ne "0") {
    $html .= " | ";
  }
  if ($params{seeGeneratedHtmlAsDisplayed} ne "0") {
    $html .= "<a href='#' onclick='document.getElementById(\"codeResult$i\").style.display = \"block\"; return false;'>See how the generated HTML is displayed on a web page</a>";
  }
  $html .= "</p>";

  return $html;
}
#----------------------------------------------------
sub docLink {
  my ($obj, %params) = @_;
  my ($type, $id, $content) = @params{ qw(type id content) };

  my ($url, $linkText, $class);
  if ($type eq 'tag') {
    $class = 'tag';
    ($url, $linkText) = $context->getSingleton('O2::Util::UrlMod')->getDispatcherPath() eq 'o2cms' ? $obj->_getBackendTagLink($id) : $obj->_getFrontendTagLink($id);
    $linkText = $content if $content;
  }
  elsif ($type eq 'object') {
    $class = 'package';
    $url = $context->getSingleton('O2::Util::UrlMod')->urlMod(
      setClass => 'System-Model',
      setMethod => 'init',
      setParams => "package=$id",
    );
    $linkText = $content || $id;
  }
  elsif ($type eq 'external') {
    $url      = $params{href};
    $linkText = $params{title};
    $class    = 'external';
  }
  return "<a class='$class' href='$url'>$linkText</a>";
}
#----------------------------------------------------
sub _getBackendTagLink {
  my ($obj, $tag) = @_;
  my $urlMod = $context->getSingleton('O2::Util::UrlMod');
  my ($url, $linkText);
  if ($tag =~ m{ \A (.+) - ([^-]+) \z }xms) {
    my $module = $1;
    $tag       = $2;
    $module   =~ s{-}{/}xms;
    $linkText = $tag;
    $url = $urlMod->urlMod(
      setParams => 'path=' . $context->getFwPath() . "/var/doc/tutorials/taglib/$module/$tag.html",
    );
  }
  else {
    $linkText = $tag;
    $url = $urlMod->urlMod();
    $url =~ s/\/[a-zA-Z0-9]+\.html$//;
    $url .= "/$tag.html";
  }
  return ($url, $linkText);
}
#----------------------------------------------------
sub _getFrontendTagLink {
  my ($obj, $tag) = @_;
  my @parts = split /-|::/, $tag;
  $tag = $tag !~ m{ - \z }xms ? pop @parts : '';
  my $module   = join ('-', @parts) || $cgi->getParam('module');
  my $linkText = $tag || $module;
  my $params   = "tag=$tag";
  $params      = "module=$module&amp;$params" if $module;
  my $url = $context->getSingleton('O2::Util::UrlMod')->urlMod(
    setDispatcherPath => 'o2',
    setClass          => 'System-Documentation-Taglibs',
    setMethod         => 'showDocumentation',
    setParams         => $params,
  );
  return ($url, $linkText);
}
#----------------------------------------------------
sub docExample {
  my ($obj, %params) = @_;

  $obj->{exampleCounter}++;
  $obj->{codeExampleCounter}++;

  my $html = ${ $obj->{parser}->_parse(\$params{content}) };

  return "<h3>Example $obj->{exampleCounter}</h3>" . $html;
}
#----------------------------------------------------
sub docList {
  my ($obj, %params) = @_;
  $obj->{isAttributeList} = $params{class} && $params{class} eq 'attributes';
  
  my $html  = "<ul " . $obj->_packTagAttribs(%params) . ">\n";
  $html    .= ${ $obj->{parser}->_parse(\$params{content}) };
  $html    .= "\n</ul>";
  return $html;
}
#----------------------------------------------------
sub docListItem {
  my ($obj, %params) = @_;
  if ($obj->{isAttributeList}) {
    my $class = delete $params{class} || '';
    my ($firstWord, $restOfContents) = $params{content} =~ m{ \A (.+?) ( \s [-\[] .*)? \z }xms;
    return "<li class=\"$class\"><span class='attrName'>$firstWord</span>" . ($restOfContents || '') . '</li>';
  }
  return "<li " . $obj->_packTagAttribs(%params) . ">$params{content}</li>";
}
#----------------------------------------------------
sub docNote {
  my ($obj, %params) = @_;
  return "<p class='note'><span class='text_note'>Note!</span>$params{content}</p>";
}
#----------------------------------------------------
sub docHint {
  my ($obj, %params) = @_;
  return "<p class='hint'><span class='text_hint'>Hint!</span> $params{content}</p>";
}
#----------------------------------------------------
1;
