package O2::Script::Common;

# Common methods used by perl scripts

use strict;

use Time::HiRes;

use base 'Exporter';
our @EXPORT = qw(ask say getSite getInstallation);

use O2 qw($context);

$SIG{__DIE__} = sub {
  my ($msg) = @_;
  my $stackTrace = eval {
    $context->getConsole()->getStackTrace();
  };
  $msg .= "\n" if $msg !~ m{ \n \z }xms;
  die "$msg$stackTrace";
};

#-----------------------------------------------------------------------------
sub ask {
  my ($question, $mustAnswer) = @_;
  my $answer;
  do {
    print $question . ' ';
    $answer = <STDIN>;
    chomp $answer;
  } while ($mustAnswer && !$answer);
  return $answer;
}
#-----------------------------------------------------------------------------
sub say {
  my ($string) = @_;
  print "$string\n";
}
#-----------------------------------------------------------------------------
sub getSite {
  my $installation = getInstallation();
  foreach my $child ($installation->getChildren()) {
    return $child if $child->isa('O2CMS::Obj::Site');
  }
  warn "Didn't find site object";
  return;
}
#-----------------------------------------------------------------------------
sub getInstallation {
  my $objectId = $context->getDbh()->fetch("select min(objectId) from O2_OBJ_OBJECT where className = 'O2CMS::Obj::Installation' and status not like 'trashed%' and status != 'deleted'");
  die "getInstallation: Didn't find installation object" unless $objectId;
  return $context->getObjectById($objectId);
}
#-----------------------------------------------------------------------------
{
  my $startTime;

  sub showProgress {
    my ($current, $total) = @_;
    my $percentCompleted = 100 * $current / $total  +  0.005;
    $percentCompleted    = " $percentCompleted" if $percentCompleted < 10;
    $percentCompleted    = " $percentCompleted" if $percentCompleted < 100;
    $percentCompleted    = substr $percentCompleted, 0, 6;
    $percentCompleted   .= '0' if length ($percentCompleted) == 5;

    $startTime = Time::HiRes::gettimeofday() if $current == 1;
    my $numPercentCompleted  = 100 * $current / $total;
    my $numPercentRemaining  = 100 - $numPercentCompleted;
    my $_numSecondsRemaining = $numPercentCompleted  ?  ((Time::HiRes::gettimeofday() - $startTime) * $numPercentRemaining / $numPercentCompleted)  :  100 * 3600 - 1;
    my ($numHoursRemaining, $numMinutesRemaining, $numSecondsRemaining) = _getTime($_numSecondsRemaining);
    print "\e[60D" if $current > 1;
    printf "$percentCompleted%% completed      Estimated time remaining: % 3d:%02d:%02d", $numHoursRemaining, $numMinutesRemaining, $numSecondsRemaining;
    if ($current == $total) {
      my $dt = time - int ($startTime);
      my ($hours, $minutes, $seconds) = _getTime($dt);
      printf "\n  It took %s %s $seconds seconds\n", ($hours ? "$hours hours" : ''), ($hours || $minutes ? "$minutes minutes and" : '');
    }
  }
}
#-----------------------------------------------------------------------------
sub _getTime {
  my ($seconds) = @_;
  my $hours   = int ($seconds/3600);
  $seconds   -= 3600 * $hours;
  my $minutes = int ($seconds/60);
  $seconds   -= 60 * $minutes;
  return ($hours, $minutes, $seconds);
}
#-----------------------------------------------------------------------------
1;
