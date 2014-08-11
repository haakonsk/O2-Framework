package O2::Lang::I18NManager;

# This is not a I18N Manager in the way normal O2 Managers are.
# This manager is just for administrations of I18N files on disk.

use strict;

use O2 qw($context);

#------------------------------------------------------------------
sub new {
  my ($package, %init) = @_;
  return bless \%init, $package;
}
#-------------------------------------------------------------------
sub getResourceFile {
  my ($obj, $file) = @_;
  die "No such resource file: '$file'" unless -f $file;
  
  my $resource;
  eval {
    $resource = eval $context->getSingleton('O2::File')->getFile($file);
  };
  die "Could not load resource file '$file': $@" if $@;
  return $resource;
}
#-------------------------------------------------------------------
sub getResourceHash {
  my ($obj, $resourcePath) = @_;
  $resourcePath =~ s{ [.] }{/}xmsg;
  
  my $session    = $context->getSession();
  my $isBackend  = ref ($session) =~ m{ Backend }xms ? 1 : 0;
  my $localeCode = $isBackend ? $session->get('user')->{locale} : $session->get('locale');
  $localeCode  ||= $context->getLocaleCode();
  my $language   = substr $localeCode, 0, 2;
  my $hashRef    = {};
  
  foreach my $dir ($context->getRootPaths()) {
    foreach my $file ("$dir/var/resources/$localeCode/$resourcePath.conf", "$dir/var/resources/$language/$resourcePath.conf") {
      next unless -e $file;
      
      my $plds = eval $context->getSingleton('O2::File')->getFile($file);
      foreach my $key (keys %{$plds}) {
        $hashRef->{$key} = $plds->{$key};
      }
    }
  }
  
  return %{$hashRef};
}
#-------------------------------------------------------------------
sub saveResourceFile {
  my ($obj, $fileName, $content) = @_;
  my $version = $obj->createVersion($fileName);
  $context->getSingleton('O2::File')->writeFileWithFileEncoding($fileName, undef, $content);
  return $version;
}
#-------------------------------------------------------------------
sub createVersion {
  my ($obj, $filePath) = @_;
  
  my @path = split /\//, $filePath;
  my $file = pop @path;
  my $path = join '/', @path;
  my $revPath = "$path/.revisions";
  my $revId = 1;
  
  my $fileMgr = $context->getSingleton('O2::File');
  
  if (!-d $revPath) {
    $fileMgr->mkPath($revPath);
  }
  else {
    # Find current revision ID
    my @files = $fileMgr->scanDir($revPath);
    foreach my $rFile (@files) {
      next if $rFile !~ m/^$file\.r(\d+)$/;
      $revId = $1 if $1 > $revId;
    }
    $revId++;
  }
  $fileMgr->cpFile($filePath,"$revPath/$file.r$revId");
  return $revId;
}
#-------------------------------------------------------------------
1;
