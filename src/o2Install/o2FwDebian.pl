use strict;
use warnings;

my $user = qx(whoami);
chomp $user;
my $apacheUser = 'www-data';
my $currentDir = qx(pwd);
chomp $currentDir;

system <<"END";
  sudo apt-get -y install apache2;
  sudo a2enmod rewrite; # Enable mod_rewrite in Apache
  sudo a2enmod include; # Enable mod_include in Apache

  sudo apt-get -y install libperlmenu-perl;
  sudo apt-get -y install mysql-server;
  sudo apt-get -y install memcached;
  sudo apt-get -y install perlmagick; # Image::Magick
  sudo apt-get -y install unzip; # Needed to download/compile locales
  sudo apt-get -y install libjson-perl;
  sudo apt-get -y install libcache-memcached-fast-perl;
  sudo apt-get -y install libdatetime-perl;
  sudo apt-get -y install libhttp-date-perl;
  sudo apt-get -y install libwww-perl;
  sudo apt-get -y install libmime-lite-perl;
  sudo apt-get -y install libxml-simple-perl;
  sudo apt-get -y install libapache-admin-config-perl;
  sudo apt-get -y install libimage-exiftool-perl;
  sudo apt-get -y install libauthen-ntlm-perl;
  sudo apt-get -y install libtest-perl-critic-perl;
  sudo apt-get -y install libparse-recdescent-perl;
  sudo apt-get -y install libxml-xpath-perl;

  if [ ! \$(which cpanm) ]; then
    curl -L http://cpanmin.us | perl - --sudo App::cpanminus;
  fi;
  sudo cpanm --notest Chart::OFC;
  sudo cpanm Locale::Util;

  if [ ! -d /www ]; then
    sudo mkdir /www;
    sudo chown $user /www;
    sudo chgrp $apacheUser /www;
    sudo chmod 0775 /www;
  fi;
END

my $cmd
  = qx(which httpd)   ? 'httpd'
  : qx(which apache2) ? 'apache2'
  :                     ''
  ;
if ($cmd) {
  my $apacheInfo = qx($cmd -V);
  my ($root)     = $apacheInfo =~ m{ HTTPD_ROOT        ="(.*?)" }xms;
  my ($fileName) = $apacheInfo =~ m{ SERVER_CONFIG_FILE="(.*?)" }xms;
  my $filePath = "$root/$fileName";
  my $fileContent;
  open my $fh, '<', $filePath;
  {
    local $/ = undef;
    $fileContent = <$fh>;
  }
  close $fh;
  if ($fileContent !~ m{ o2Sites }xms) {
    $fileContent =~ s{# Include the virtual host configurations:}{# Include the virtual host configurations:\nInclude /www/apacheconf/o2Sites}ms;
    open $fh, '>', '/tmp/o2Fw.txt';
    print {$fh} $fileContent;
    system "sudo cp /tmp/o2Fw.txt $filePath";
    system 'rm /tmp/o2Fw.txt';
  }
}

system <<"END";
  export O2ROOT=$currentDir/O2-Framework;
  export PERL5LIB=$currentDir/O2-Framework/lib;
  export O2CUSTOMERROOT=;
  export DOCUMENT_ROOT=;
  export O2SITEROOT=;
  cd $currentDir/O2-Framework/bin/setup;
  perl setup.pl install fw -v 1

  sudo service memcached restart;
  sudo chgrp -R $apacheUser $ENV{O2CUSTOMERROOT}/..;
  sudo chgrp -R $apacheUser $ENV{O2CUSTOMERROOT}/../o2-fw/;
  sudo chmod -R g+w $ENV{O2CUSTOMERROOT}/..;
  sudo chmod -R g+w $ENV{O2CUSTOMERROOT}/../o2-fw/;
END
