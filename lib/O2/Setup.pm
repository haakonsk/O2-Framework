package O2::Setup;

# Abstract base class for handling install/upgrade/remove/backup => setup of O2 and it's components

use strict;

use O2 qw($context $config);

#---------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  die "O2::Setup is an abstract class - you need to inhert and implement it your self" if $pkg eq 'O2::Setup';
  return bless {}, $pkg;
}
#---------------------------------------------------------------------
sub getSetupConf {
  my ($obj, $hostname) = @_;
  $hostname ||= $config->get('o2.hostname') || $config->get('setup.hostname') || $context->getHostname() || $ENV{HTTP_HOST};
  die "Couldn't figure out hostname" unless $hostname;
  return $context->{setupConf}->{$hostname} or die "setupConf for $hostname hasn't been stored";
}
#---------------------------------------------------------------------
sub setSetupConf {
  my ($obj, $conf) = @_;
  my $hostname = $conf->{hostname};
  $conf->{apacheLogDir}  ||= '/www/httplogs';
  $conf->{apacheConfDir} ||= '/www/apacheConf/o2Sites';
  $context->{setupConf}->{$hostname} = $conf;
}
#---------------------------------------------------------------------
sub debug { # XXX Rewrite to actually print debug-info
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  return $setupConf->{args}->{debug} || 0;
}
#---------------------------------------------------------------------
sub verbose { # XXX Rewrite to actually print verbose-info
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  return $setupConf->{args}->{v} || $obj->debug() || 0;
}
#---------------------------------------------------------------------
sub getDependencies { # Return which classes this class is dependent of
  return;
}
#---------------------------------------------------------------------
sub install { # Note; Install should be able to handle upgrades as well, unless you override the upgrade method
  return 1;
}
#---------------------------------------------------------------------
sub upgrade {
  return 1;
}
#---------------------------------------------------------------------
sub remove {
  return 1;
}
#---------------------------------------------------------------------
sub backup {
  return 1;
}
#---------------------------------------------------------------------
sub confirmExecute {
  my ($obj, $command, $msg) = @_;
  return unless $obj->_getCommandLine()->confirm("$msg\n  $command\nPlease confirm", 'y');
  return system $command;
}
#---------------------------------------------------------------------
sub confirmExecuteSql {
  my ($obj, $sql, $command, $msg) = @_;
  return unless $obj->_getCommandLine()->confirm("$msg\n  $sql\nPlease confirm", 'y');
  return system $command;
}
#---------------------------------------------------------------------
sub _getCommandLine {
  my ($obj) = @_;
  return $obj->{commandLine} if $obj->{commandLine};
  require O2::Util::Commandline;
  return $obj->{commandLine} = O2::Util::Commandline->new();
}
#---------------------------------------------------------------------
1;
