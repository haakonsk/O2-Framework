package O2;

use strict;

use base 'Exporter';

our @EXPORT_OK = qw($context $o2 $cgi $db $config $session $CONTEXT $O2 $CGI $DB $CONFIG $SESSION);

our ($context, $o2, $cgi, $db, $config, $session); # Use lowercase
our ($CONTEXT, $O2, $CGI, $DB, $CONFIG, $SESSION); #  or uppercase

my %DEBUG_TYPE; # Key: caller-package

BEGIN {
  if (exists $ENV{MOD_PERL}) {
    require O2::Dispatch::ModPerlGlobals::Context;
    require O2::Dispatch::ModPerlGlobals::Cgi;
    require O2::Dispatch::ModPerlGlobals::Db;
    require O2::Dispatch::ModPerlGlobals::Config;
    require O2::Dispatch::ModPerlGlobals::Session;
    
    tie $context, 'O2::Dispatch::ModPerlGlobals::Context';
    tie $o2,      'O2::Dispatch::ModPerlGlobals::Context';
    tie $cgi,     'O2::Dispatch::ModPerlGlobals::Cgi';
    tie $db,      'O2::Dispatch::ModPerlGlobals::Db';
    tie $config,  'O2::Dispatch::ModPerlGlobals::Config';
    tie $session, 'O2::Dispatch::ModPerlGlobals::Session';
    tie $CONTEXT, 'O2::Dispatch::ModPerlGlobals::Context';
    tie $O2,      'O2::Dispatch::ModPerlGlobals::Context';
    tie $CGI,     'O2::Dispatch::ModPerlGlobals::Cgi';
    tie $DB,      'O2::Dispatch::ModPerlGlobals::Db';
    tie $CONFIG,  'O2::Dispatch::ModPerlGlobals::Config';
    tie $SESSION, 'O2::Dispatch::ModPerlGlobals::Session';
  }
}

#-----------------------------------------------------------------------------
sub import {
  my ($package, @symbolsToImport) = @_;
  my %symbolsToImport = map { lc ($_) => 1 } @symbolsToImport;
  
  if (!$O2::context) { # Probably a script, so let's not tie STDOUT when we create context:
    require O2::Cgi;
    require O2::Context;
    $O2::context = O2::Context->new( cgi => O2::Cgi->new(tieStdout => 'no') );
  }
  $context = $O2::context if $symbolsToImport{'$context'};
  $CONTEXT = $O2::context if $symbolsToImport{'$CONTEXT'};
  $o2      = $O2::context if $symbolsToImport{'$o2'};
  $O2      = $O2::context if $symbolsToImport{'$O2'};
  
  $context->setSession( $context->getSingleton('O2::Session') ) if $symbolsToImport{'$session'} && !$session && !$context->getSession();
  
  if (!$ENV{MOD_PERL}) {
    $cgi     = $CGI     = $context->getCgi()     if !$cgi     && $symbolsToImport{'$cgi'};
    $db      = $DB      = $context->getDbh()     if !$db      && $symbolsToImport{'$db'};
    $config  = $CONFIG  = $context->getConfig()  if !$config  && $symbolsToImport{'$config'};
    $session = $SESSION = $context->getSession() if !$session && $symbolsToImport{'$session'};
  }
  
  # Enable debugging:
  my ($callerPackage) = caller;
  my  $debugLevel = $main::debugLevel;
  my  $debugType;
  if (!$debugLevel) {
    # Check if DEBUG has been set (with "use constant") in the calling package (must be set before O2 is used):
    {
      no strict;
      eval "\$debugLevel = ${callerPackage}::DEBUG";
    }
    die $@ if $@;
    $debugLevel = 0 if $debugLevel =~ m{ DEBUG }xms; # If the constant doesn't exist in the calling package...
  }

  # Check if DEBUG_TYPE has been set (with "use constant") in the calling package (must be set before O2 is used):
  {
    no strict;
    eval "\$debugType = ${callerPackage}::DEBUG_TYPE";
  }
  die $@ if $@;

  # Log to database by default
  $debugType   = 'db' if $DEBUG_TYPE{$callerPackage} =~ m{ DEBUG_TYPE }xms; # If the constant doesn't exist in the calling package...
  $debugType ||= 'db';
  $DEBUG_TYPE{$callerPackage} = $debugType;

  {
    no strict 'refs';
    *{"${callerPackage}::debug"}
      = $debugLevel == 1 ? \&_debug1
      : $debugLevel == 2 ? \&_debug2
      : $debugLevel >= 3 ? \&_debug
      :                    sub {}
      ;
  }
  
  # Enable logging of info and warnings to O2_CONSOLE_LOG ("warn" still logs to the error-log file):
  {
    no strict 'refs';
    *{"${callerPackage}::loginfo"} = \&_logInfo;
    *{"${callerPackage}::warning"} = \&_logWarning;
  }
  
  O2->export_to_level(1, @_);
}
#-----------------------------------------------------------------------------
sub _debug1 {
  my ($msg, $level) = @_;
  return if $level && $level > 1;
  _debug($msg);
}
#-----------------------------------------------------------------------------
sub _debug2 {
  my ($msg, $level) = @_;
  return if $level && $level > 2;
  _debug($msg);
}
#-----------------------------------------------------------------------------
sub _debug3 {
  my ($msg, $level) = @_;
  _debug($msg);
}
#-----------------------------------------------------------------------------
sub _debug {
  my ($msg) = @_;
  my ($callerPackage) = caller;
  return warn $msg if $DEBUG_TYPE{$callerPackage} eq 'warn';

  eval {
    $O2::context->getConsole()->_debug($msg, callerLevel => 4);
  };
  warn "Couldn't log debug message <<$msg>>: $@" if $@;
}
#-----------------------------------------------------------------------------
sub _logWarning {
  my ($msg, %params) = @_;
  eval {
    $O2::context->getConsole()->_warning($msg, %params, callerLevel => 3);
  };
  warn "Couldn't log warning <<$msg>>: $@" if $@;
}
#-----------------------------------------------------------------------------
sub _logInfo {
  my ($msg, %params) = @_;
  eval {
    $O2::context->getConsole()->_message($msg, %params);
  };
  warn "Couldn't log info message <<$msg>>: $@" if $@;
}
#-----------------------------------------------------------------------------
1;
