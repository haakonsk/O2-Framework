package O2::Setup::Classes;

use strict;

use base 'O2::Setup';

use O2 qw($context);
use O2::Script::Common;

#---------------------------------------------------------------------
sub upgrade {
  my ($obj, $fakeIt) = @_;
  $obj->generateClassDocumentation();
  $obj->runUpgradeScripts('before', $fakeIt);

  $obj->updateDb();

  # Do the same for archive database:
  print "Switching to archive database handler\n" if $obj->verbose();
  $context->useArchiveDbh();
  $obj->updateDb();
  $context->usePreviousDbh();
  print "Switching back to normal database handler\n" if $obj->verbose();

  $obj->runUpgradeScripts('after', $fakeIt);
  return 1;
}
#---------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  return $obj->upgrade(1);
}
#---------------------------------------------------------------------
# Scripts will by default be run after the DB update. But some scripts, those that end with "-before.pl", will be run
# before the database is updated. The automatically generated scripts that rename database table fields are examples of
# scripts that must be run before updating the database.
sub runUpgradeScripts {
  my ($obj, $when, $fakeIt) = @_;
  my $verbose = $obj->verbose();
  
  my @scripts;
  foreach my $dir ($context->getRootPaths()) {
    $dir = "$dir/bin/setup/Classes";
    next unless -d $dir;
    
    my @_scripts = $context->getSingleton('O2::File')->scanDirRecursive($dir, '.pl$');
    @_scripts    = grep { $_ =~ m{ (?: / | \A) 0* \d+ - [^/]+ \z }xms } @_scripts;
    @_scripts    = map  { "$dir/$_"                                   } @_scripts;
    @_scripts    = sort {
      my ($aNum) = $a =~ m{ (?: / | \A) 0* (\d+) - [^/]+ \z }xms;
      my ($bNum) = $b =~ m{ (?: / | \A) 0* (\d+) - [^/]+ \z }xms;
      return $aNum <=> $bNum;
    } @_scripts;
    push @scripts, @_scripts;
  }
  
  foreach my $script (@scripts) {
    next if $script =~ m{ -before[.]pl \z }xms && $when ne 'before';
    next if $script !~ m{ -before[.]pl \z }xms && $when eq 'before';
    print "Running $script:\n" if $verbose >= 3;
    my $res = system "perl $script --verbose $verbose" . ($fakeIt ? ' --fakeIt 1' : '');
    if ($res != 0) {
      print "\nExiting due to errors...\n\n";
      exit;
    }
  }
}
#---------------------------------------------------------------------
sub updateDb {
  my ($obj) = @_;
  my $schemaMgr    = $context->getSingleton('O2::DB::Util::SchemaManager');
  my $introspector = $context->getSingleton('O2::Util::ObjectIntrospect');
  my %classes = $introspector->getAllObjectClasses();
  foreach my $className (keys %classes) {
    next if $className eq 'O2::Obj::Object';
    
    $introspector->setClass( $context->getUniversalMgr()->_guessManagerClassName($className) );
    if (!$introspector->hasNativeMethod('initModel')) {
      print "  Skipping $className. Hasn't implemented method initModel\n" if $obj->debug();
      next;
    }
    $schemaMgr->updateTableForClass($className, printChangesToStdOut => $obj->verbose(), okToDrop => 1);
  }
}
#---------------------------------------------------------------------
sub generateClassDocumentation {
  my ($obj) = @_;
  print "Generating class documentation\n" if $obj->verbose() >= 3;
  $context->getSingleton('O2::Util::ClassDocumentation')->generate();
}
#---------------------------------------------------------------------
1;
