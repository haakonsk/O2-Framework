use strict;
use warnings;

use O2::Util::ScriptEnvironment;
O2::Util::ScriptEnvironment->runOnlyOnce();

use O2 qw($context $db);
use O2::Script::Common;

my @scriptNames = $db->selectColumn('select scriptName from O2_SCRIPT_LOG');
SCRIPT:
foreach my $scriptName (@scriptNames) {
  next if $scriptName =~ m{ \A / }xms;
  
  my ($className) = $scriptName =~ m{ \A \d+ - (\w+) (?:-before)? [.] pl \z }xms or die "No match: $scriptName";
  foreach my $root ($context->getRootPaths()) {
    if (-e "$root/bin/setup/Classes/$className/$scriptName") {
      my $date = $db->fetch('select date from O2_SCRIPT_LOG where scriptName = ?', $scriptName);
      $db->do('update O2_SCRIPT_LOG set scriptName = ?, date = ? where scriptName = ?', "$root/bin/setup/Classes/$className/$scriptName", $date, $scriptName);
      next SCRIPT;
    }
  }
  
  # Didn't find script, let's search for it
  foreach my $root ($context->getRootPaths()) {
    my $file = qx{find $root/ | grep $scriptName\$};
    if ($file) {
      $file =~ s{ \s+ \z }{}xms; # Remove trailing white space
      my $date = $db->fetch('select date from O2_SCRIPT_LOG where scriptName = ?', $scriptName);
      $db->do('update O2_SCRIPT_LOG set scriptName = ?, date = ? where scriptName = ?', $file, $date, $scriptName);
    }
  }
}
