#!/usr/bin/env perl
#
# This script is built with the intent of being able to;
#
# - install a completely new installation (for a customer)
# - upgrade an existing installation
# - backup an existing installation
# - remove an existing installation
# 
# It is also a way to move data, directory-structures etc. from dev to test to stage to production
# 
# So far, a sort of tracer bullet approach has been used - meaning that this is a
# "working prototype" where things are not finished, nor perfect, but the intent to make
# it possible to complete the total picture over time.
# 
# Right now, all this script does is take a few parameters (or ask for them) and based 
# upon the action it can run all the perl-setup-classes.
#
# The perl-setup-classes needs to adhere to the interface defined in O2CMS::Setup. See O2CMS::Setup::CMS for an
# example of how you might go about creating your own setup
# 
# Please do not hack this script, try to keep things clean and tidy
#
# Also, please follow these guidelines;
#
# - Don't ask/require information about something if you don't absolutely need to (make sane defaults
#   and if you must - rewrite getSaneDefaults to be able to pull info from ENV or a file or similar)
#
# - Don't print anything uneccesary (-v, --verbose for more INFORMATION and --debug for DEBUG)
#
# - Make sure that everything can run in a completely non-human way (so that we can use automated builds)
#
#
# Todo:
#   - Factor out in utility-classes the common tasks like creating configs, directories and databases
#     - Either O2CMS::Setup::Utilities or just put them in O2CMS::Setup ?
#   - Further refactor O2CMS::Setup::CMS to make it cleaner (it now relies too much on old code)
#   - Make more setup-classes
#     - For the stuff in "bin/setup/optional" 
#     - Seperate out shop, yr etc.
#   - Add a more generic/platform-independent solution to getSaneDefaults (possible strategies:
#     - ENV?
#     - Config-script to ask/try to figure out defaults/details on a new platform? Eg. bin/setup/config.pl
#   - Add t/O2CMS::Setup.t-test for O2CMS::Setup
#   - Add possibility to review/change defaults pr. command line (eg. by supplying --custom or similar)
#   - Make O2CMS::Setup::debug/verbose do the actual printing
#   - Add a possibility to have a test-action? At least make it possible to not run tests on an install
#   - downgrade-option?
#--------------------------------------------------------------------------------------------------
use strict;
use warnings;

#---------------------------------------------------------------------

$| = 1;

# Use absolute paths, so that we can still find O2 modules even if symlinks to o2-fw, o2-cms etc are deleted.
BEGIN {
  $Curses::OldCurses = 1;
  
  my $cwd = qx{pwd};
  chomp $cwd;
  if (!$ENV{O2ROOT} && $cwd =~ m{ /bin/setup /? \z }xms) {
    ($ENV{O2ROOT}) = $cwd =~ m{ \A (.+) /bin/setup /? \z }xms;
  }
  elsif (!$ENV{O2ROOT}) {
    die 'Environment variable O2ROOT needs to be set, or you can run the script from the directory bin/setup under the O2ROOT';
  }
  if (!$ENV{O2CMSROOT}) {
    $ENV{O2CMSROOT} = $ENV{O2ROOT};
    $ENV{O2CMSROOT} =~ s{o2-fw}{o2-cms}xms;
    die "O2ROOT did not contain 'o2-fw'" if $ENV{O2ROOT} eq $ENV{O2CMSROOT};
  }
  my %_INC = map { $_ => 1 } @INC;
  push @INC, "$ENV{O2ROOT}/lib"    unless $_INC{ $ENV{O2ROOT}    };
  push @INC, "$ENV{O2CMSROOT}/lib" unless $_INC{ $ENV{O2CMSROOT} };
  
  require Cwd;
  for my $i (0 .. $#INC) {
    my $symlinkPath  = $INC[$i];
    my $absolutePath = Cwd::abs_path($symlinkPath);
    if ($absolutePath && $symlinkPath ne $absolutePath) {
      $INC[$i] = $absolutePath;
      $ENV{PERL5LIB} =~ s{ \Q$symlinkPath\E }{$absolutePath}xms if $ENV{PERL5LIB};
    }
  }
}

use O2 qw($context);
use O2::Util::Commandline;
use O2::Script::Common;
use Curses;
use perlmenu;

#---------------------------------------------------------------------

my $config = $context->getConfig();

my $CMDLINE = O2::Util::Commandline->new();
$CMDLINE->cls();

my @ALLOWEDACTIONS = qw/install upgrade backup remove restore help/;
my $isFwSetup;

{ # Scope $action and $class so we don't accidentally 'bleed' them out

  my $dirToRestoreFrom;
  my @originalArgv = @ARGV;
  my $action = shift @ARGV;
  my $class  = shift @ARGV;
  my $defaultClass = $context->cmsIsEnabled() ? 'O2CMS::Setup::CMS' : 'O2::Setup::FW';
  if (!$action || $action =~ m{ \A - }xms) { # No action
    $action  = 'upgrade';
    $class = $defaultClass;
  }
  elsif (!$class || $class =~ m{ \A - }xms) { # No class
    $class = $defaultClass;
  }
  if ($action eq 'restore') {
    $dirToRestoreFrom = $class;
    $class            = $defaultClass;
  }
  $class = 'O2CMS::Setup::CMS' if lc $class eq 'cms';
  $class = 'O2::Setup::FW'     if lc $class eq 'fw';
  $isFwSetup = $class eq 'O2::Setup::FW';
  
  if (!validateActionAndClass($action, $class)) {
    help();
    exit;
  }
  
  @ARGV = @originalArgv;
  require O2::Util::Args::Simple;
  import  O2::Util::Args::Simple;
  $ARGV{v} ||= $ARGV{-verbose} || 0;
  $ARGV{v} ||= 3 if $ARGV{-debug};
  
  if ($action eq 'restore') {
    installCustomerRoot();
    no strict 'refs';
    help() unless -d $dirToRestoreFrom;
    restore($dirToRestoreFrom);
  }
  elsif ($action eq 'help') {
    help();
  }
  else {
    installCustomerRoot();
    no strict 'refs';
    $action->($class);
  }
}
#---------------------------------------------------------------------
sub help {
  $CMDLINE->heading("O2 Setup - Help");
  $CMDLINE->say("Usage: $0 " . join ('|', @ALLOWEDACTIONS) . " SetupClass [--customer CUSTOMER] [--host HOSTNAME] [-v|--verbose|--debug] [--nobackup|--backup] [--forceremove] [--customerRoot PATH] [configVariables]\n");
  $CMDLINE->say("restore is a little different:");
  $CMDLINE->say(" $0 restore backupDir [--customer CUSTOMER] [--host HOSTNAME] [-v|--verbose]");
  $CMDLINE->say("backupDir is the directory where the backup files have been stored\n");
  $CMDLINE->say("specify customerRoot if you want to avoid being asked about it\n");
  $CMDLINE->say("configVariables can be one or more of the config variables that are listed during install. If any of these are specified for install, you won't be asked about them");
  $CMDLINE->say("F ex --mysqlRootPass qwerty --groupOwner www\n");
  exit;
}
#---------------------------------------------------------------------
sub remove {
  my ($class) = @_;
  my $customer = getCustomerName();
  
  $CMDLINE->heading("O2 Setup - remove '$class' from an existing installation");
  if ($ARGV{-forceremove} || $CMDLINE->confirm("Are you sure you want to completely remove '$class' from the '$customer'-installation? This action is NOT REVERSIBLE!", 'n')) {
    my $reallyWantsToRemove = 0;
    if ($ARGV{-backup} || $ARGV{-nobackup} || $CMDLINE->confirm("Do you want to make a backup before proceeding?", 'y')) {
      backup($class, 1) unless $ARGV{-nobackup};
      $reallyWantsToRemove = 1;
    }
    elsif ($ARGV{-forceremove} || $CMDLINE->confirm("You have chosen not to backup '$class' on '$customer'-installation. Are you really sure you want to proceed? This action is NOT REVERSIBLE!", 'n')) {
      $reallyWantsToRemove = 1;
    }
    if ($reallyWantsToRemove) {
      $config->get('o2.database.dataSource'); # Make sure it's cached, so we can get this value even after the config file has been deleted.
      runActionOnClass( customer => $customer, action => 'remove', class => $class );
    }
  }
  exit;
}
#---------------------------------------------------------------------
sub backup {
  my ($class, $dontExit) = @_;
  $CMDLINE->heading("O2 Setup - make backup of '$class' on an existing installation");
  runActionOnClass( action => 'backup', class => $class );
  exit unless $dontExit;
}
#---------------------------------------------------------------------
sub restore {
  my ($dirToRestoreFrom) = @_;
  $CMDLINE->heading("O2 Setup - restore from directory $dirToRestoreFrom");
  my $fileMgr = $context->getSingleton('O2::File');
  my @files = $fileMgr->scanDir($dirToRestoreFrom, "^$ARGV{-host}");

  # First, restore file system
  foreach my $file (@files) {
    if ($file =~ m{ [.]tar[.]gz \z }xms && $CMDLINE->confirm("Restore file system ($ENV{O2CUSTOMERROOT})?")) {
      next if -d $ENV{O2CUSTOMERROOT} && !$CMDLINE->confirm("$ENV{O2CUSTOMERROOT} exists. Overwrite?");
      
      my $command = "rm -rf $ENV{O2CUSTOMERROOT}; cd /; tar -xzf $dirToRestoreFrom/$file";
      print "Restoring customer file system: $command\n" if $ARGV{v};
      system $command;
      $config->clearCache();
    }
  }
  
  # Then, restore other things
  foreach my $file (@files) {
    if ($file =~ m{ [.]sql[.]gz \z }xms && $CMDLINE->confirm('Restore database?')) {
      my $dbConf = $config->get('o2.database');
      $context->getSingleton('O2::Setup::Database')->createDatabase( $dbConf->{dataSource}, getCustomerName(), $dbConf->{password}, $dbConf->{collation} );
      my $command = "cat $dirToRestoreFrom/$file | gunzip | mysql -u root -p $dbConf->{dataSource}";
      print "Restoring database: $command\n" if $ARGV{v};
      system $command;
    }
    elsif ($file =~ m{ [.]conf \z }xms && $CMDLINE->confirm('Restore apacheconf?')) {
      my $apacheConfDir = $config->get('setup.apacheConfDir');
      my $fromFile = "$dirToRestoreFrom/$file";
      my $toFile   = "$apacheConfDir/$file";
      print "Restoring apacheconf: Copying $fromFile to $toFile\n" if $ARGV{v};
      $fileMgr->cpFile($fromFile, $toFile);
    }
  }
  exit;
}
#---------------------------------------------------------------------
sub upgrade {
  my ($class) = @_;
  $CMDLINE->heading("O2 Setup - upgrade '$class' on an existing installation");
  
  if ($ARGV{-backup} || $CMDLINE->confirm("It is highly recommended that you make a backup before proceeding. Do you want to make a backup?", 'y')) {
    backup($class, 1);
  }
  runActionOnClass( action => 'upgrade', class => $class );
  exit;
}
#---------------------------------------------------------------------
sub install {
  my ($class) = @_;
  $CMDLINE->heading("O2 Setup - install '$class' on a new installation");
  
  my %serverNames = (
    dev   => 'development',
    test  => 'test',
    stage => 'stage',
    www   => 'production',
  );
  
  menu_init(1, 'Choose servers', 1, "Choosing more than one server will allow you to set different config values for the servers you choose. \nIt makes sense to do this on a development server.");
  menu_item( $serverNames{dev},   'dev'   );
  menu_item( $serverNames{test},  'test'  );
  menu_item( $serverNames{stage}, 'stage' );
  menu_item( $serverNames{www},   'www'   );
  my $servers = menu_display_mult();
  die 'Need to choose at least one server' if $servers eq '%NONE%';
  my @servers = split /,/, $servers;
  
  my $thisServer;
  if (@servers > 1) {
    menu_init(1, 'Which server is this?');
    foreach my $server (@servers) {
      menu_item( $serverNames{$server}, $server );
    }
    $thisServer = menu_display();
  }
  elsif (@servers == 1) {
    $thisServer = $servers[0];
  }
  my $isDevServer = $thisServer ne 'test' && $thisServer ne 'stage' && $thisServer ne 'www' && $thisServer ne 'prod';
  if (!$isDevServer) {
    die "You should copy $ENV{O2CUSTOMERROOT} from your dev server before running setup.pl, preferably using a revision control system like GIT or SVN (Subversion).\n" unless -d $ENV{O2CUSTOMERROOT};
  }
  qx(cd $ENV{O2CUSTOMERROOT}/etc/conf; rm serverId; ln -s $thisServer serverId) if -d "$ENV{O2CUSTOMERROOT}/etc/conf";
  
  my %hostnames;
  my $customer = getCustomerName();
  my $defaultDomain = "$customer.com";
  $config->clearCache();
  if (my $hostname = $config->get('o2.hostname')) {
    $defaultDomain = $hostname;
    $defaultDomain =~ s{ \A \w+ [.] }{}xms;
  }
  foreach my $server (@servers) {
    my $hostname = $CMDLINE->ask("Hostname for server '$serverNames{$server}'", "$server.$defaultDomain");
    $hostnames{$server} = $hostname;
    if ($hostname !~ m{ \A \w+ [.] \Q$defaultDomain\E \z }xms) {
      ($defaultDomain) = $hostname =~ m{ \A \w+ [.] (.+) \z }xms;
    }
  }
  
  my $defaultCustomersDir = $ENV{O2CUSTOMERROOT};
  $defaultCustomersDir    =~ s{ / \Q$customer\E .* }{}xms;
  my %setup = %{ $config->get('setup') || {} };
  my %conf = (
    o2FwRoot            => { text => 'O2 Framework root path',                                          value => $ENV{O2ROOT}              },
    o2CmsRoot           => { text => 'O2 CMS root path',                                                value => $ENV{O2CMSROOT} || ''     },
    mysqlRootUser       => { text => 'Username of privileged database user',                            value => 'root'                    },
    mysqlRootPass       => { text => 'Password of privileged database user',                            value => ''                        },
    groupOwner          => { text => 'Created files should have the following group name',              value => 'www-data'                },
    locales             => { text => 'Locale code(s) (Default locale code first, separate with comma)', value => 'en_US'                   },
    customersRoot       => { text => 'Customers directory',                                             value => $defaultCustomersDir      },
    smtp                => { text => 'SMTP server name',                                                value => 'localhost'               },
    smtpSenderName      => { text => 'Sender address of outgoing e-mail',                               value => ucfirst $customer         },
    smtpSenderMail      => { text => 'Sender name of outgoing e-mail',                                  value => 'post@' . $defaultDomain  },
    tmpDir              => { text => 'Directory for temporary files',                                   value => '/tmp'                    },
    dbCollation         => { text => 'Database collation',                                              value => 'utf8_danish_ci'          },
    apacheLogDir        => { text => 'Apache log directory',                                            value => '/www/httplogs'           },
    apacheConfDir       => { text => 'Apache conf directory',                                           value => '/www/apacheconf/o2Sites' },
    o2cmsPassword       => { text => 'o2cms admin password',                                            value => ''                        },
    systemModelPassword => { text => 'System-Model admin password',                                     value => ''                        },
    useModPerl          => { text => 'Enable mod_perl?',                                                value => 'No',                     },
  );
  if (%setup) {
    foreach my $key (sort keys %conf) {
      $conf{$key}->{value} = $setup{$key};
    }
  }
  if ($isFwSetup) {
    delete $conf{o2CmsRoot};
    delete $conf{o2cmsPassword};
  }
  
  foreach my $server (@servers) {
    my $hostname = $hostnames{$server};
    $conf{hostname} = { text => 'Hostname',  value => $hostname };
    $conf{serverId} = { text => 'Server ID', value => $server   };
    $conf{dbCollation}->{value} ||= $config->get('o2.database.collation');
    
    my $configEntriesToChange;
    while (1) {
      menu_init(1, 'Configure ' . uc ($server) . " ($hostname)", 1, 'Select items you would like to change (if any)');
      foreach my $key (sort keys %conf) {
        my $value = $conf{$key}->{value} || '';
        $value  ||= '<Will use same password as for o2cms>'        if $key eq 'systemModelPassword' &&  exists $conf{o2cmsPassword} &&  $conf{o2cmsPassword}->{value};
        $value  ||= '<Password will be auto-generated>'            if $key eq 'systemModelPassword' &&  exists $conf{o2cmsPassword} && !$conf{o2cmsPassword}->{value};
        $value  ||= '<Will use same password as for System-Model>' if $key eq 'o2cmsPassword'       &&  $conf{systemModelPassword}->{value};
        $value  ||= '<Password will be auto-generated>'            if $key eq 'o2cmsPassword'       && !$conf{systemModelPassword}->{value};
        if ($key eq 'useModPerl') {
          $value = 'Yes' if ($value =~ m{ \A y (?:es)? \z }xmsi || $value eq '1');
          $value = 'No'  if  $value ne 'Yes';
          $conf{useModPerl}->{value} = $value eq 'Yes';
        }
        menu_item(
          sprintf ( "%-63s : $value", $conf{$key}->{text} ),
          $key,
        );
      }
      $configEntriesToChange = menu_display_mult();
      last if $configEntriesToChange eq '%NONE%';
      
      my @configEntriesToChange = split /,/, $configEntriesToChange;
      foreach my $key (@configEntriesToChange) {
        $conf{$key}->{value} = $CMDLINE->ask( $conf{$key}->{text}, $conf{$key}->{value} );
      }
    }
    my %setupConf = map { $_ => $conf{$_}->{value} } keys %conf;
    $setupConf{customer} = $customer;
    $context->getSingleton($class)->setSetupConf(\%setupConf);
    
    if ($isDevServer) { # Save setup.conf:
      my $confFileContent = "{\n";
      foreach (sort keys %conf) {
        $confFileContent .= sprintf "  %-19s => '%s',\n", $_, $conf{$_}->{value} if $_ ne 'mysqlRootPass' && $_ ne 'dbCollation';
      }
      $confFileContent .= "};\n";
      
      my $fileMgr = $context->getSingleton('O2::File');
      my $dir = $context->getCustomerPath() . '/etc/conf/setup-configs';
      $fileMgr->mkPath($dir) unless -d $dir;
      $fileMgr->writeFile("$dir/setup.$conf{serverId}->{value}.conf", $confFileContent);
    }
  }
  
  runActionOnClass(
    host      => $hostnames{$thisServer},
    action    => 'install',
    class     => $class,
    serverId  => $thisServer,
    hostnames => \%hostnames,
  );
  
  if (!$isDevServer) {
    runActionOnClass( # Upgrade
      action => 'upgrade',
      class  => $class,
    );
  }
  
  exit;
}
#---------------------------------------------------------------------
sub getCustomerName {
  my $customer = $ARGV{-customer} || '';
  return $customer if $customer;
  
  my $defaultCustomer = $context->getCustomerPath() || '';
  $defaultCustomer    =~ s{ \A .* / ([\w-]+) /o2 \z }{$1}xms;
  while ($customer !~ m/^[a-zA-Z0-9_\-\.]{2,}$/) {
    $customer = $CMDLINE->ask('Customer/installation name? (eg. /www/cust/CUSTOMER/, only a-Z, 0-9, -, and _ allowed)', $defaultCustomer);
  }
  return $ARGV{-customer} = $customer;
}
#---------------------------------------------------------------------
sub runActionOnClass {
  my %params = @_;
  my $serverId = $params{serverId} || eval { $config->getServerId() };
  my $customer = getCustomerName();
  my $host     = $params{host} || $config->get("servers.$serverId");
  
  my $setupConf = getSetupConf( customer => $customer, host => $host, serverId => $params{serverId}, class => $params{class} );
  
  # These are just extra precautions
  die 'No action found'    unless $params{action};
  die 'No class found'     unless $params{class};
  die 'No customer found'  unless $customer;
  die 'No hostname found'  unless $host;
  die 'No setupConf found' unless $setupConf;
  
  runClass( # Run the class with the chosen action
    %params,
    setupClass => delete $params{class},
    setupConf  => $setupConf,
  );
  
  my $url = "http://$host";
  $url   .= '/o2cms' if $context->cmsIsEnabled();
  my $msg = $params{action} eq 'install' ? "All set, ready to go. Point your browser to $url" : "$params{action} done";
  $CMDLINE->blank();
  $CMDLINE->say($msg);
  $CMDLINE->blank();
}
#---------------------------------------------------------------------
sub runClass { # This method might be run recursivly due to the getPrequisities
  my (%params) = @_;
  
  return if $params{setupConf}->{runnedClasses}->{ $params{setupClass} };
  
  $CMDLINE->say("Running $params{setupClass}") if $ARGV{v} >= 2;
  
  my $setupPart = $context->getSingleton( $params{setupClass} );
  my $action    = $params{action};
  
  die "Could not instantiate $params{setupClass}: $@"             unless ref $setupPart;
  die "$params{setupClass} does not have a valid baseclass"       unless $setupPart->isa('O2::Setup'); # This MIGHT be a little bit too tight
  die "$params{setupClass} does not know hot to handle '$action'" unless $setupPart->can($action);
  
  $setupPart->setSetupConf( $params{setupConf} );
  
  my @dependencies = $setupPart->getDependencies($action);
  foreach my $dependency (@dependencies) {
    if ( !$params{setupConf}->{runnedClasses}->{$dependency} ) { # Only bother with classes that haven't yet been run
      $CMDLINE->say("  $params{setupClass} requires $dependency") if $ARGV{v} >= 3;
      registerAndCheckDependency( $params{setupClass} => $dependency ); # Check for circular referencing
      runClass(
        %params,
        setupClass => $dependency,
        action     => $action,
      );
    }
  }
  
  $setupPart->$action(%params) or die "Could not run setup properly for $params{setupClass} (did not return true value)";
  $params{setupConf}->{runnedClasses}->{ $params{setupClass} } = 1;
}
#---------------------------------------------------------------------
{
  my %dependencies;
  sub registerAndCheckDependency {
    my ($setupClass, $dependency) = @_;
    die "$setupClass has created a circular reference when dependency $dependency which also dependend upon $setupClass\n" if $dependencies{$dependency}->{$setupClass};
    $dependencies{$setupClass}->{$dependency} = 1;
  }
}

#---------------------------------------------------------------------
sub installCustomerRoot {
  return if $ENV{O2CUSTOMERROOT}; # Already installed
  
  if ($ARGV{-customerRoot}) {
    $ENV{O2CUSTOMERROOT} = $ARGV{-customerRoot};
  }
  else {
    $ENV{O2CUSTOMERROOT} = $CMDLINE->ask("Customer root", $ENV{O2CUSTOMERROOT} || '/www/cust/' . getCustomerName() . '/o2');
    $config->loadConfDirs();
  }
}
#---------------------------------------------------------------------
sub getSetupConf {
  my (%params) = @_;
  $params{host} ||= '';
  
  my $class = $params{class};
  my $setupConf;
  $setupConf = $context->getSingleton($class)->getSetupConf( $params{host} ) if $class;
  if ($setupConf) {
    $setupConf->{customer} = $params{customer};
    $setupConf->{context}  = $context;
    $setupConf->{args}     = \%ARGV;
    $setupConf->{tmpDir}  .= "/$setupConf->{hostname}_" . $context->getDateFormatter()->dateFormat(time, 'yyyyMMdd_HH_mm_ss') if $setupConf->{hostname} !~ m{ \Q$setupConf->{hostname}\E }xms;
    setupEnvironment($setupConf);
    return $setupConf;
  }
  
  my ($domain) = $params{host} =~ m/([0-9a-zA-Z_-]+\.[0-9a-zA-Z_-]+)$/;
  $domain ||= '';
  
  $config->loadConfDirs();
  
  my $customerSetupConf = eval { $config->get('setup') };
  if (!$customerSetupConf) {
    my $filePath = "$ENV{O2CUSTOMERROOT}/etc/conf/setup-configs/setup.$params{serverId}.conf";
    my $fileContent = $context->getSingleton('O2::File')->getFile($filePath) or die "File $filePath is empty";
    eval "\$customerSetupConf = $fileContent;";
    die $@ if $@;
  }
  my %conf = (
    o2FwRoot            => $ENV{O2ROOT},
    o2CmsRoot           => $ENV{O2CMSROOT} || '',
    mysqlRootUser       => 'root',
    mysqlRootPass       => '',
    groupOwner          => 'www-data',
    locales             => 'en_US',
    customersRoot       => '/www/cust',
    smtp                => 'localhost',
    smtpSenderName      => ucfirst $params{customer},
    smtpSenderMail      => 'post@' . $domain,
    tmpDir              => '/tmp',
    dbCollation         => 'utf8_danish_ci',
    apacheLogDir        => '/www/httplogs',
    apacheConfDir       => '/www/apacheconf/o2Sites',
    o2cmsPassword       => '',
    systemModelPassword => '',
    useModPerl          => 'No',
    %{$customerSetupConf},
    hostname            => $params{host},
    serverId            => $params{serverId},
  );
  if ($isFwSetup) {
    delete $conf{o2CmsRoot};
    delete $conf{o2cmsPassword};
  }
  foreach (keys %conf) {
    if (exists $ARGV{"-$_"}) {
      $conf{$_} = $ARGV{"-$_"};
    }
  }
  $conf{customer} = $params{customer};
  $conf{context}  = $context;
  $conf{args}     = \%ARGV;
  $conf{tmpDir}  .= "/$conf{hostname}_" . $context->getDateFormatter()->dateFormat(time, 'yyyyMMdd_HH_mm_ss') if $conf{hostname} !~ m{ \Q$conf{hostname}\E }xms;

  setupEnvironment(\%conf);

  return \%conf;
}
#---------------------------------------------------------------------
sub setupEnvironment {
  my ($setupConf) = @_;
  eval "use lib '$setupConf->{o2CmsRoot}/lib'" if $setupConf->{o2CmsRoot};
  $ENV{O2CUSTOMERROOT} = join '/', $setupConf->{customersRoot}, $setupConf->{customer}, 'o2';
  $ENV{PERL5LIB}       = "$ENV{O2CUSTOMERROOT}/lib";
  $ENV{PERL5LIB}      .= ":$setupConf->{o2CmsRoot}/lib" if $setupConf->{o2CmsRoot};
  $ENV{PERL5LIB}      .= ":$ENV{O2ROOT}/lib";
  $ENV{HTTP_HOST}      = $setupConf->{hostname};

  if ($ARGV{v} >= 3) {
    require Data::Dumper;
    print Data::Dumper::Dumper($setupConf);
  }

  # Set the locale AFTER we dump it if debug ^. (I guess the reason for that is that a dump of the locale would be extremely long)
  $setupConf->{context}->setLocaleCode( $setupConf->{locale} );
}
#---------------------------------------------------------------------
sub validateActionAndClass {
  my ($action, $class) = @_;
  return 0 if !$action || !$class;

  my $isValidAction = 0;
  foreach my $allowedAction (@ALLOWEDACTIONS) {
    if ($action eq $allowedAction) {
      $isValidAction = 1;
      last;
    }
  }
  eval "require $class;";
  die "Could not locate setup-class '$class': $@\n" if $@;
  return $isValidAction;
}
#---------------------------------------------------------------------
