package O2::Template::Taglibs::Cache;

use strict;

use O2 qw($context $config);

#----------------------------------------------------
sub register {
  my ($package, %params) = @_;
    
  my $obj = bless {parser => $params{parser}}, $package;
  my %methods = (
    cache => 'postfix',
  );
  $obj->{cacheTagNum} = 0;
  return ($obj, %methods);
}
#----------------------------------------------------
sub cache {
  my ($obj, %params) = @_;

  $obj->{cacheTagNum}++;

  foreach (keys %params) {
    next if $_ eq 'content';
    $obj->{parser}->parseVars( \$params{$_} );
  }

  # Make sure O2CACHEROOT exists as a (pseudo) environment variable
  $context->setEnv( 'O2CACHEROOT', $context->getCustomerPath() . '/var/cache' ) unless $context->getEnv('O2CACHEROOT');

  $params{timeout} = 1800 unless $params{timeout} > 0;
  my $key = $params{key} or die "'key' parameter is required";
  $key    =~ s{ [^\w-] }{_}xmsg;

  my $fileMgr = $context->getSingleton('O2::File');
  my $path = $fileMgr->distributePath(
    rootDir  => $context->getEnv('O2CACHEROOT'),
    id       => $key,
    fileName => "$key.cache",
    mkDirs   => 1,
    levels   => 4,
  );
  
  # Is cache still fresh?
  if (time - [stat $path]->[9]  >  $params{timeout}) { # No
    $obj->{parser}->_parse( \$params{content} );
    $fileMgr->writeFile( $path, $params{content} );
    return $params{content};
  }
  else {                                               # Yes
    return $fileMgr->getFile($path);
  }
}
#----------------------------------------------------
1;
