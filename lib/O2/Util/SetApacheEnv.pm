package O2::Util::SetApacheEnv;

# Parse the Apache config file, get and set the environment variables
# defined with the 'SetEnv' directive in the Apache config file.

use strict;

use O2 qw($context);
use Apache::Admin::Config;
use O2::Util::Args::Simple;
my %ARGV = %O2::Util::SetApacheEnv::ARGV; # Hack, not sure why this is necessary.

our %APP_ENV_VARS;

#-----------------------------------------------------------------------------------------
sub init {
  my ($configFile) = @_;
  my $conf = Apache::Admin::Config->new($configFile) or die $Apache::Admin::Config::ERROR;

  # Selecting virtual host.
  return $conf->section('VirtualHost');
}
#-----------------------------------------------------------------------------------------
# Check that the host argument is found as a ServerName or ServerAlias directive in
# the given Apache config file.
sub checkConfig {
  my ($vhost, $host) = @_;
  # Selecting server name.        
  my $serverName = $vhost->directive('ServerName')->value();
  return 1 if $serverName eq $host;
  my $aliases = $vhost->directive('ServerAlias');
  foreach my $serverAlias ($vhost->directive('ServerAlias')) {
    return 1 if $serverAlias->value() eq $host;
  }
  die "Wrong Apache config file path given or wrong host" if $serverName ne $host;
}
#-----------------------------------------------------------------------------------------
# Set the environment variables.
sub setEnvVars {
  my ($vhost, $host) = @_;
  my %env_vars;
  foreach ($vhost->directive('SetEnv'))  {
    my @env_var = split / /, $_->value();
    my $firstVar = $env_var[0];
    my $lastVar  = $env_var[-1];
    $lastVar =~ s/^\"//; # Remove leading double quote.
    $lastVar =~ s/\"$//; # Remove trailing double quote.
    $env_vars{$firstVar} = $ENV{$firstVar} = $lastVar;
  }
  $env_vars{'DOCUMENT_ROOT'} = $ENV{'DOCUMENT_ROOT'} = $vhost->directive('DocumentRoot')->value();
  return \%env_vars;
}
#-----------------------------------------------------------------------------------------
sub printEnvVars {
  my ($env_vars) = @_;
  print "Number of SetEnv should be:  " . keys( %{$env_vars} ) . ".\n";
  foreach my $key (sort keys(%ENV)) {
    print "$key => $ENV{$key}\n" if $key =~ m{ \A (?: O2 | OSAS | PERL | HTTP ) }xms;
  }
}
#-----------------------------------------------------------------------------------------
sub main {
  my $host = $ARGV{-host} || $context->getHostname() or die "$0 Needs either a --host parameter or the O2CUSTOMERROOT environment variable must be set\n";
  
  my $apacheConfDir = $ENV{O2APACHECONFDIR} || '/www/apacheconf/o2Sites';
  my $configFile    = $ARGV{-configFile}    || "$apacheConfDir/$host.conf";
  if (!-e $configFile) {
    require O2::Context;
    ($configFile) = grep { $_ =~ m{ \Q$host\E }xms } $context->getSingleton('O2::File')->scanDir($apacheConfDir);
    $configFile = "$apacheConfDir/$configFile";
    die "Didn't find apache config file for $host in $apacheConfDir" if !$configFile || !-e $configFile;
  }

  my $vhost = init($configFile);            
  checkConfig($vhost, $host);
  %APP_ENV_VARS = %{ setEnvVars($vhost, $host) };
  foreach my $key (keys %APP_ENV_VARS) {
    if ($key =~ m{ \A O2 \w* ROOT \z }xms && $APP_ENV_VARS{$key}) {
      push @INC, $APP_ENV_VARS{$key} . '/lib';
    }
  }
}
#-----------------------------------------------------------------------------------------
main();
#-----------------------------------------------------------------------------------------
1;
