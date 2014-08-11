package O2::Script::Detached;

use strict;

use O2 qw($context $db);

#-------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  return bless \%params, $package;
}
#-------------------------------------------------------------------------------
sub run {
  my ($obj, $command, %params) = @_;
  $command =~ s{ " }{ \\" }xmsg;
  warn "runDetached: $command";
  
  if ($params{exclusive} && (my $pid = $obj->isRunning($command))) {
    return $pid;
  }
  warn "Creating new process";
  
  my $max       = $params{max}       || 0;
  my $exclusive = $params{exclusive} || 0;
  my $randomId = $context->getSingleton('O2::Util::Password')->generatePassword();
  system qq{perl $ENV{O2ROOT}/bin/includes/detach.pl "$command" $randomId $max $exclusive};
  my $pid = $db->fetch('select pid from O2_BACKGROUND_PROCESS where randomId = ?', $randomId);
  warn "pid is $pid";
  
  return $pid;
}
#-------------------------------------------------------------------------------
sub setCounter {
  my ($obj, $pid, $counter) = @_;
  $db->sql("update O2_BACKGROUND_PROCESS set counter   = ? where pid = ?", $counter, $pid || $$);
  $db->sql("update O2_BACKGROUND_PROCESS set startTime = ? where pid = ?", time,     $pid || $$) if $counter == 1;
}
#-------------------------------------------------------------------------------
sub isRunning {
  my ($obj, $command) = @_;
  my @processes = split /\n/, qx(ps aux | grep "/bin/includes/detach.pl $command");
  return 0 unless @processes;
  
  foreach my $process (@processes) {
    next if $process =~ m{ps aux}ms;
    
    my ($pid) = $process =~ m{ \w+ \s+ (\d+) }xms;
    return $pid;
  }
  return 0;
}
#-------------------------------------------------------------------------------
sub getPid {
  my ($obj) = @_;
  my @callers = $context->getConsole()->getStackTraceArray();
  my ($methodName) = $callers[-2]->{subroutine} =~ m{ :: (\w+) \z }xms;
  return $db->fetch("select pid from O2_BACKGROUND_PROCESS where command like ? order by startTime desc limit 1", '%' . $methodName . '%');
}
#-------------------------------------------------------------------------------
sub getCounter {
  my ($obj, $pid) = @_;
  return $db->fetch("select counter from O2_BACKGROUND_PROCESS where pid = ?", $pid || $$);
}
#-------------------------------------------------------------------------------
sub getStartTime {
  my ($obj, $pid) = @_;
  return $db->fetch("select startTime from O2_BACKGROUND_PROCESS where pid = ?", $pid || $$);
}
#-------------------------------------------------------------------------------
sub cleanup {
  my ($obj, $pid) = @_;
  $db->sql('delete from O2_BACKGROUND_PROCESS where pid = ?', $pid || $$);
}
#-------------------------------------------------------------------------------
1;
