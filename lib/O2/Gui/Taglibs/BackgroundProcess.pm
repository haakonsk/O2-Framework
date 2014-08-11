package O2::Gui::Taglibs::BackgroundProcess;

use strict;

use base 'O2::Gui';

use O2 qw($context);

#----------------------------------------------------
sub startProcess {
  my ($obj) = @_;
  my %params = $obj->getParams();
  
  my $pid = $context->getSingleton('O2::Script::Detached')->run(
    $params{command},
    exclusive => $params{exclusive} || 0,
    max       => $params{max}       || 0,
  );
  return {
    pid             => $pid,
    maxCounter      => $params{max},
    showProgressBar => $params{showProgressBar},
    onStart         => $params{onStart},
    onEnd           => $params{onEnd},
  };
}
#----------------------------------------------------
sub getProgressCounter {
  my ($obj) = @_;
  my $pid = $obj->getParam('pid');
  my $detached = $context->getSingleton('O2::Script::Detached');
  my $counter = $detached->getCounter($pid);
  my $seconds = $counter > 0  ?  time - $detached->getStartTime($pid)  :  0;

  if (!qx(ps aux | grep "\\b$pid\\b")) { # Process not running
    return {
      counter => 1_000_000_000,
      seconds => $seconds,
    };
  }
  
  return {
    counter => $counter,
    seconds => $seconds,
  };
}
#----------------------------------------------------
sub cleanup {
  my ($obj) = @_;
  $context->getSingleton('O2::Script::Detached')->cleanup( $obj->getParam('pid') );
  return 1;
}
#----------------------------------------------------
1;
