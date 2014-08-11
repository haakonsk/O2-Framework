package O2::Util::ScriptEnvironment;

# Utility to make it easy to write scripts
#
#  - set up environment variables

use strict;

use O2 qw($db);
use O2::Util::SetApacheEnv;
use O2::Util::Args::Simple;

use Exporter 'import';

#-----------------------------------------------------------------------------
sub runOnlyOnce {
  my $scriptPath = $0;
  my $scriptName = $scriptPath;
  $scriptName =~ s{^.*/}{};
  if ($scriptPath !~ m{ \A / }xms) { # Not an absolute path
    my $cwd = qx{pwd -L};            # -L: Don't resolve symlinks
    $cwd    =~ s{ \s+ \z }{}xms;     # Remove trailing white space
    $scriptPath = "$cwd/$scriptName";
  }
  
  my @entries = $db->fetchAll('select scriptName from O2_SCRIPT_LOG where scriptName = ?', $scriptPath);
  if (@entries && !$ARGV{-force}) {
    print "$scriptName has already been run, skipping\n" if $ARGV{-verbose} >= 3;
    exit;
  }
  
  $db->sql('insert into O2_SCRIPT_LOG (scriptName) values (?)', $scriptPath);
  if ($ARGV{-fakeIt}) { # During an install, we don't want to actually run these scripts - just log that they have run, so they won't be run in the future either.
    print "pretending to run $scriptName only once\n" if $ARGV{-verbose};
    exit;
  }
  print "running $scriptName only once\n" if $ARGV{-verbose};
}
#-----------------------------------------------------------------------------
1;
