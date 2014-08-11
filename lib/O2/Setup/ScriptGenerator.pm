package O2::Setup::ScriptGenerator;

use strict;

use O2 qw($context);

#-----------------------------------------------------------------------------
sub newSetupScriptForClass {
  my ($pkg, $className, %params) = @_;
  my $obj = bless {
    className      => $className,
    directory      => $params{directory} || 'Classes',
    beforeDbUpdate => $params{beforeDbUpdate},
  }, $pkg;
  $obj->{code} = "use strict;

use O2 qw(\$context \$db);
";
  if ($params{runOnlyOnce}) {
    $obj->{code} .= "
use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();
";
  }
  $obj->{code} .= "\n";
  return $obj;
}
#-----------------------------------------------------------------------------
sub addCodeLine {
  my ($obj, $code) = @_;
  $obj->{code} .= "$code\n";
}
#-----------------------------------------------------------------------------
sub getCode {
  my ($obj) = @_;
  return $obj->{code};
}
#-----------------------------------------------------------------------------
sub writeScriptFile {
  my ($obj) = @_;
  $context->getSingleton('O2::File')->writeFile( $obj->getFilePath(), $obj->getCode() );
  chmod oct (775), $obj->getFilePath();
}
#-----------------------------------------------------------------------------
# Must be called after writeScriptFile
sub run {
  my ($obj) = @_;
  system sprintf 'perl %s --force', $obj->getFilePath();
}
#-----------------------------------------------------------------------------
sub getFilePath {
  my ($obj) = @_;
  return $obj->{filePath} if $obj->{filePath};
  my $pathifiedClassName = $obj->getClassName();
  $pathifiedClassName    =~ s{ :: }{_}xmsg;
  my $baseDir
    = $obj->getClassName() =~ m{ \A O2:: }xms
    ? $context->getEnv('O2ROOT')         . "/bin/setup/$obj->{directory}"
    : $context->getEnv('O2CUSTOMERROOT') . "/bin/setup/$obj->{directory}"
    ;
  my $dir = "$baseDir/$pathifiedClassName";
  $context->getSingleton('O2::File')->mkPath($dir, oct 775) unless -d $dir;
  my $scriptId = $obj->_getNextScriptNumber($baseDir);
  return $obj->{filePath} = sprintf "$dir/$scriptId-$pathifiedClassName%s.pl", $obj->{beforeDbUpdate} ? '-before' : '';
}
#-----------------------------------------------------------------------------
sub _getNextScriptNumber {
  my ($obj, $dir) = @_;
  my $fileMgr = $context->getSingleton('O2::File');
  my $num = 0;
  foreach my $fileName ($fileMgr->scanDirRecursive($dir, '.pl$')) {
    my ($i) = $fileName =~ m{ / 0* (\d+) - }xms;
    $num = $i if $i > $num;
  }
  return $num+1;
}
#-----------------------------------------------------------------------------
sub getClassName {
  my ($obj) = @_;
  return $obj->{className};
}
#-----------------------------------------------------------------------------
1;
