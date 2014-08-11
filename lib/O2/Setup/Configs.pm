package O2::Setup::Configs;

use strict;

use base 'O2::Setup';

use O2 qw($context $config);

#---------------------------------------------------------------------
sub install {
  my ($obj, %params) = @_;
  my $serverId = eval { $config->getServerId() };
  return 1 if $serverId eq 'test' || $serverId eq 'stage' || $serverId eq 'www' || $serverId eq 'prod';
  
  foreach my $serverId (keys %{ $params{hostnames} }) {
    my $hostname = $params{hostnames}->{$serverId};
    $obj->createO2DotConf($serverId, $hostname);
  }
  $obj->createDispatchDotConf();
  $obj->createVersionDotConf();
  $obj->createServerIdSymlink( %params );
  $obj->createServersDotConf(  %params );
  $config->clearCache();
  
  return 1;
}
#---------------------------------------------------------------------
sub createO2DotConf {
  my ($obj, $serverId, $hostname) = @_;
  my $setupConf = $obj->getSetupConf($hostname);
  $obj->{dbpassword} ||= $config->get('o2.database.password') || $setupConf->{dbpassword} || $context->getSingleton('O2::Util::Password')->generatePassword(8);
  $setupConf->{dbpassword} = $obj->{dbpassword};
  my @locales = split /\s*,\s*/, $setupConf->{locales};
  my $defaultLocale = $locales[0];
  my $locales = join ' ', @locales;
  
  my $customerPath = "$setupConf->{customersRoot}/$setupConf->{customer}";
  my $hostname     = $setupConf->{hostname};
  
  my $content = <<END;
{
  defaultLocale    => '$defaultLocale',
  fallbackLocale   => '$defaultLocale',
  language         => '$defaultLocale',
  locales          => [qw($locales)],
  hostname         => '$hostname',
  documentRoot     => '$customerPath/$setupConf->{hostname}',
  customerRootPath => '$customerPath/o2',
  customerRoot     => '%%o2.customerRootPath%%',
  smtp             => '$setupConf->{smtp}',
  smtpName         => '$setupConf->{smtpSenderName}',
  smtpSender       => '$setupConf->{smtpSenderMail}',
  database => {
    dataSource => 'o2_$setupConf->{customer}',
    collation  => '$setupConf->{dbCollation}',
    username   => '$setupConf->{customer}',
    password   => '$setupConf->{dbpassword}',
  },
  session => {
    path => '%%o2.customerRootPath%%/var/sessions',
  },
  encryptPasswords => 'yes',
  encodeEntities   => 1,
};
END
  my $filePath = $context->getCustomerPath() . "/etc/conf/o2-configs/o2.$serverId.conf";
  print "  $filePath created\n" if $context->getSingleton('O2::Util::Commandline')->writeFileWithConfirm($filePath, $content) && $obj->verbose();
}
#-----------------------------------------------------------------------------
sub createDispatchDotConf {
  my ($obj) = @_;

  my $setupConf = $obj->getSetupConf();

  my $customerPath = join '/', $setupConf->{customersRoot}, $setupConf->{customer};

  my $customerPackagePrefix = ucfirst $setupConf->{customer};
  my $content = <<END;
{
  guiModuleUrlPrefix       => '/o2/',
  customerPackagePrefix    => '$customerPackagePrefix',
  guiModulePackagePrefixes => ['${customerPackagePrefix}::Gui::'],
};
END
  my $filePath = "$customerPath/o2/etc/conf/dispatcher.conf";
  $context->getSingleton('O2::Util::Commandline')->writeFileWithConfirm($filePath, $content);
  print "  $filePath created\n" if $obj->verbose();
}
#---------------------------------------------------------------------
sub createVersionDotConf {
  my ($obj) = @_;
  my $setupConf = $obj->getSetupConf();
  my $customerPath = "$setupConf->{customersRoot}/$setupConf->{customer}";
  
  my $content = <<END;
{
  version => 1,
};
END
  my $filePath = "$customerPath/o2/etc/conf/version.conf";
  $context->getSingleton('O2::Util::Commandline')->writeFileWithConfirm($filePath, $content);
  print "  $filePath created\n" if $obj->verbose();
}
#---------------------------------------------------------------------
sub createServerIdSymlink {
  my ($obj, %params) = @_;
  my $setupConf = $obj->getSetupConf();
  my $hostname = $setupConf->{hostname};
  my $customerPath = join '/', $setupConf->{customersRoot}, $setupConf->{customer};
  qx(cd $customerPath/o2/etc/conf; ln -s $params{serverId} serverId);
}
#---------------------------------------------------------------------
sub createServersDotConf {
  my ($obj, %params) = @_;
  my $content = "{\n";
  while (my ($serverId, $hostname) = each %{ $params{hostnames} }) {
    $content .= "  $serverId => '$hostname',\n";
  }
  $content .= "};\n";
  
  my $setupConf = $obj->getSetupConf();
  my $customerPath = join '/', $setupConf->{customersRoot}, $setupConf->{customer};
  $context->getSingleton('O2::Util::Commandline')->writeFileWithConfirm("$customerPath/o2/etc/conf/servers.conf", $content);
}
#---------------------------------------------------------------------
1;
