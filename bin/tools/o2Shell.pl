#!/usr/bin/perl

use strict;

# use lib is run at compile time, so that's why we must find o2Root in a BEGIN block
my $o2Root;
BEGIN {
  my $workingDirectory = `pwd`;
  $workingDirectory    =~ s{ \s+ \Z }{}xms;
  my $fullPath = $0 =~ m{ \A / }xms ? $0 : "$workingDirectory/$0";
  $fullPath    =~ s{ /\./ }{/}xmsg;
  ($o2Root) = $fullPath =~ m{ \A (.+) /bin/ }xms;
}

use lib "$o2Root/lib";

use O2::File;
my $fileMgr = O2::File->new();
my $temporaryFile = $ARGV[0];
my $customer = $ARGV[1];
my $apacheConfDir = $ENV{O2APACHECONFDIR} || '/www/apacheconf/o2Sites';
my @files = $fileMgr->scanDir($apacheConfDir, "*$customer*.conf\$");
my $apacheConf = $files[0];
if (@files > 1) {
  use O2::Script::Common;
  my $alternatives = '';
  my $i = 0;
  foreach my $file (@files) {
    $alternatives .= ' ' . ++$i . ". $file\n";
  }
  my $index;
  do {
    $index = ask "Which apache config file?\n${alternatives}Please type in the number before the correct file, or 0 to abort:";
  }
  while (int $index  ne  $index   ||   $index > $i   ||   $index < 0);
  exit if $index == 0;
  $apacheConf = $files[ $index-1 ];
}

my $hostName = $apacheConf;
$hostName    =~ s{ [.]conf \z }{}xms;

# Arguments to O2::Util::SetApacheEnv:
$ARGV[1] = $hostName;
$ARGV[0] = '--host';
require O2::Util::SetApacheEnv;

my $fileContent = '';
foreach my $key (keys %O2::Util::SetApacheEnv::APP_ENV_VARS) {
  $fileContent .= "$key=$O2::Util::SetApacheEnv::APP_ENV_VARS{$key}\n";
}
$fileMgr->writeFile($temporaryFile, $fileContent);
