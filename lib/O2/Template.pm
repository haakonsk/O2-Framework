package O2::Template;

use strict;

use O2 qw($context);

#--------------------------------------------------------------------------------------------
sub newFromFile {
  my ($package, $file, %params) = @_;
  return bless {
    file => $file,
  }, $package;
}
#--------------------------------------------------------------------------------------------
sub newFromString {
  my ($package, $string, %params) = @_;
  return bless {
    string => $string,
  }, $package;
}
#--------------------------------------------------------------------------------------------
sub parse {
  my ($obj, %params) = @_;

  my $content;
  if ($obj->{file}) {
    $content = $context->getSingleton('O2::File')->getFileRef( $obj->{file} );
    if (!$obj->getCwd()) {
      my $cwd = $obj->{file};
      $cwd    =~ s{([/\\])[^/\\]+$}{$1};
      $obj->setCwd($cwd);
    }
  }
  elsif ($obj->{string}) {
    $content = ref $obj->{string} eq 'SCALAR' ? $obj->{string} : \$obj->{string};
  }
  
  my $tagParser = $obj->getTagParser();
  while (my ($key, $value) = each %params) {
    $tagParser->pushVar($key, $value);
  }
  
  $tagParser->pushProperty( 'currentTemplate', $obj->getCurrentTemplate() ) if $obj->getCurrentTemplate();
  $tagParser->setProperty( 'locale', $params{locale} || $obj->getLocale() );
  $tagParser->parse($content);
  $tagParser->popProperty('currentTemplate');
  
  while (my ($key, $value) = each %params) {
    $tagParser->popVar($key, $value);
  }
  
  return $content;
}
#--------------------------------------------------------------------------------------------
sub getTagParser {
  my ($obj, %params) = @_;
  return $obj->{tagParser} if $obj->{tagParser};
  
  require O2::Template::TagParser;
  return $obj->{tagParser} = O2::Template::TagParser->new(
    cwd  => $obj->getCwd(),
    vars => \%params,
  );
}
#--------------------------------------------------------------------------------------------
sub getCwd {
  my ($obj) = @_;
  return $obj->{cwd};
}
#--------------------------------------------------------------------------------------------
sub setCwd {
  my ($obj, $cwd) = @_;
  $obj->{cwd} = $cwd;
}
#--------------------------------------------------------------------------------------------
sub setLocale {
  my ($obj, $locale) = @_;
  $obj->{locale} = $locale;
}
#--------------------------------------------------------------------------------------------
sub getLocale {
  my ($obj) = @_;
  return $obj->{locale};
}
#--------------------------------------------------------------------------------------------
sub setCurrentTemplate {
  my ($obj, $template) = @_;
  $obj->{currentTemplate} = $template;
}
#--------------------------------------------------------------------------------------------
sub getCurrentTemplate {
  my ($obj) = @_;
  return $obj->{currentTemplate};
}
#--------------------------------------------------------------------------------------------
1;
