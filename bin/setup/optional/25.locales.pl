#!/usr/bin/perl

use strict;

use LWP::Simple;
use File::Temp;
use O2::Context;

my $cldrDir = "$ENV{O2ROOT}/var/resources/cldr";
die "$cldrDir not found" unless -d $cldrDir;


downloadLatestCldr();
compileLocales();


# pre-compile locales
sub compileLocales {
  my $context = O2::Context->new();
  require O2::Lang::LocaleManager;
  my $localeMgr = O2::Lang::LocaleManager->new(context=>$context);

  foreach my $localeCode ( getLocaleCodes() ) {
    print "Compile locale: $localeCode\n";
    $localeMgr->compileLocale($localeCode);
  }
}


# returns all locale codes found in cldr file names
sub getLocaleCodes {
  my $path = "$cldrDir/common/main";
  opendir(D, $path) or die ("'$path': $!");
  return sort grep {$_}  map {/^(\w\w_\w\w).xml$/} readdir(D);
}


# download and unzip cldr (localization data) from unicode.org
sub downloadLatestCldr {
  # download mainpage
  my $baseUrl = 'http://unicode.org/Public/cldr/';
  my $html = get($baseUrl);
  die "Could not download $baseUrl" unless $html;

  # find latest version
  my @versionDirs = $html =~ m|<a href="([\d./]+)">|g;
  my $dir = (sort @versionDirs)[-1]; # latest version
  die "Could not determine latest version" unless $dir;

  # download
  my $coreUrl = "$baseUrl$dir/core.zip";
  my $fh = File::Temp->new(SUFFIX => '.zip');
  my $path = $fh->filename();
  print "Download: $coreUrl (about 25Mb I guess)...\n";
  my $httpStatus = getstore($coreUrl, $path);
  die "Download got status $httpStatus\n" unless $httpStatus==200;

  # unzip file
  my $cmd = "unzip -o $path -d $cldrDir";
  print "$cmd\n";
  my $unzipStatus = system($cmd);
  die "Error unzipping $path (is unzip installed?) Error was: $!" unless $unzipStatus==0;
}
