use strict;
use warnings;

use Cwd qw(abs_path);

use O2 qw($context);

my $fileMgr = $context->getSingleton('O2::File');
foreach my $root (reverse $context->getRootPaths()) {
  syncSymlinksUnder("$root/var/www") if $root ne $context->getCustomerPath();
}
removeDeadSymlinks();

sub syncSymlinksUnder {
  my ($dir) = @_;
  return unless -d $dir;
  
  my @files = $fileMgr->scanDirRecursive($dir, '[.]\w+$');
  @files    = grep { $_ !~ m{ [.]svn \z }xms } @files;
  
  foreach my $file (@files) {
    my $fullPath = "$dir/$file";
    my $customerPath = $context->getCustomerPath() . "/var/www/$file";
    my ($currentCustomerDir) = $customerPath =~ m{ \A (.*) / }xms;
    $fileMgr->mkPath($currentCustomerDir) unless -d $currentCustomerDir;
    next if -e $customerPath && !-l $customerPath;                    # It's not a symlink, don't touch!
    next if -l $customerPath && abs_path($customerPath) eq $fullPath; # Symlink is correct
    
    unlink $customerPath if -l $customerPath; # Down here any symlink will be incorrect
    
    symlink $fullPath, $customerPath or die "Couldn't create symlink ($customerPath -> $fullPath): $!"; # Create symlink
  }
}

sub removeDeadSymlinks {
  my $dir = $context->getCustomerPath() . '/var/www';
  my @files = $fileMgr->scanDirRecursive($dir, '[.]\w+$');
  @files    = grep { $_ !~ m{ [.]svn \z }xms } @files;
  
  foreach my $file (@files) {
    my $fullPath = "$dir/$file";
    unlink $fullPath if -l $fullPath && !-e $fullPath;
  }
}
