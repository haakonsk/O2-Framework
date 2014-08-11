package O2::Template::Taglibs::I18N;

use strict;

use O2 qw($context);
use O2::Lang::I18N;

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my $parser = $params{parser};

  my $obj = bless { parser => $parser }, $package;
  
  $obj->{i18n} ||= $context->getLang();
  
  my %methods = (
    setResourcePath => '',
    getString       => '',
  );
  return ($obj, %methods);
}
#----------------------------------------------------
# E.g. 
# <o2 getString>o2.appname.title</o2:getString>     <- if setResourcePath is not set
# <o2 getString>title</o2:getString>                <- if setResourcePath is set
# <o2 getString locale="nb_NO">title</o2:getString> <- overides whatever locale is set
#
sub getString {
  my ($obj, %params) = @_;
  
  my $keyId
   = index ($params{content},'.') < 0 && $obj->{resourcePath}
   ? "$obj->{resourcePath}.$params{content}"
   : $params{content}
   ;

  return $obj->{i18n}->getString($keyId, %params);
}
#----------------------------------------------------
# setResourcePath allows you to do this instead
#   <o2 setResourcePath>o2.appname</o2:setResourcePath>
#   <o2 getString >title</o2:getString>
# instead of having to write full resourcePath for each getString
# e.g
# <o2 getString>o2.appname.title</o2:getString>
sub setResourcePath {
  my ($obj, %params) = @_;
  $obj->{resourcePath} = $params{content};
  $obj->{parser}->setResourcePath( $params{content} );
  return '';
}
#----------------------------------------------------
1;
