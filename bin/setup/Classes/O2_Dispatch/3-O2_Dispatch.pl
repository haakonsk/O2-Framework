use strict;
use warnings;

# Translate O2::Frontend::Dispatch to O2::Dispatch in all index.cgi files

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2 qw($context $config);
use O2::Script::Common;

my $fileMgr = $context->getSingleton('O2::File');

my $dir = $context->getEnv('O2CUSTOMERROOT');
$dir    =~ s{ /o2 /? \z }{}xms;

my @files = map  { $_ =~ s{ \s+ \z }{}xms; $_ } qx{find $dir -name index.cgi};
foreach my $file (@files) {
  my $content = $fileMgr->getFile($file);
  next if $content !~ m{ O2::Frontend::Dispatch }xms;
  
  $content =~ s{ O2::Frontend::Dispatch }{O2::Dispatch}xmsg;
  $content =~ s{\$dispatch->dispatch\(isPublisherRequest=>1, url=>\$url\);}{\$dispatch->dispatch(cgi=>\$cgi, isPublisherRequest=>1, url=>\$url);}msg;
  $fileMgr->writeFile($file, $content);
}
