#!/usr/bin/perl
use LWP::Simple;

my @urls = (
  'http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz',
  'http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz',
  );

foreach my $url (@urls) {
  my ($file) = $url =~ m|/([^/]+)$|;
  my $path = "$ENV{O2ROOT}/var/resources/geoIPDatabase/$file";
  
  print "Downloading $url...\n";
  my $httpStatus = getstore($url, $path);
  die "Error downloading $url" unless $httpStatus==200;
  
  my $cmd = "gunzip -f $path";
  print $cmd,"\n";
  system($cmd)==0 or die "Error running $cmd";
}
