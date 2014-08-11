package O2::Template::Taglibs::Jquery;

use strict;

use base 'O2::Template::Taglibs::Html';

use constant DEBUG => 0;
use O2 qw($context $cgi $config);

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my $minified = $params{minified};
  if (!exists $params{minified} || $params{minified} eq 'maybe') {
    my $serverType = $config->get('o2.serverType');
    $minified = $serverType eq 'stage' || $serverType eq 'prod';
  }
  
  my ($obj, %methods) = $package->SUPER::register(%params);
  
  my $jqueryIsIncluded = $obj->_jqueryJsHasBeenIncluded();
  if (!$obj->isa('O2::Template::Taglibs::JqueryUi') && (!$jqueryIsIncluded || $params{important})) {
    my $jsFile = $obj->_getJsFile( 'jquery', $params{version}, undef, $minified );
    if (!$jqueryIsIncluded) {
      $obj->addJsFile( file => $jsFile );
      $obj->{parser}->setProperty( 'includedJqueryFiles', { jqueryJs => $jsFile } );
    }
    elsif ($params{important}) {
      my $includedJqueryFiles = $obj->{parser}->getProperty('includedJqueryFiles');
      $obj->replaceJsFile( $includedJqueryFiles->{jqueryJs}, $jsFile );
    }
  }
  
  return ($obj, %methods);
}
#----------------------------------------------------
sub _jqueryJsHasBeenIncluded {
  my ($obj) = @_;
  my %jsFiles = %{ $obj->{parser}->getProperty('javascriptFiles') };
  my @jsFiles = keys %{ $jsFiles{pre} };
  foreach my $file (@jsFiles) {
    return $file if $file =~ m{ jquery-\d }xms || $file =~ m{ jquery (?: [.]min )?  [.]js \z }xms;
  }
  return 0;
}
#----------------------------------------------------
sub _getJsFile {
  my ($obj, $jquery, $version, $theme, $minified) = @_;
  $theme    ||= 'smoothness';
  $version  ||= '';
  $minified ||= 0;
  my $fileMgr = $context->getSingleton('O2::File');
  my $baseDir = $context->getFwPath() . "/var/www/js/$jquery";
  my @files = $fileMgr->scanDir($baseDir, "*$version*") or die "Didn't find $jquery version $version";
  my $dir = "$baseDir/" . $obj->_chooseHighestVersion(@files);
  
  my $file;
  
  $baseDir = $obj->isa('O2::Template::Taglibs::JqueryUi') ? "$dir/$theme/js" : $dir;
  $obj->{parser}->setVar("${jquery}BaseDir", $baseDir);
  if ($version) {
    my $pattern = "*$version*" . ($minified ? '.min' : '') . '.js$';
    my @files = $fileMgr->scanDir($baseDir, $pattern);
    @files    = grep { $_ !~ m{ [.]min[.]js }xms } @files unless $minified;
    $file = $files[0];
    die "Didn't find file in $baseDir" unless $file;
  }
  else {
    my @files = $fileMgr->scanDir($baseDir, "$jquery-*.js\$");
    @files    = grep { $_ !~ m{ jquery-ui   }xms } @files     if $jquery eq 'jquery';
    @files    = grep { $_ =~ m{ [.]min[.]js }xms } @files     if $minified;
    @files    = grep { $_ !~ m{ [.]min[.]js }xms } @files unless $minified;
    $file = $files[0];
  }
  $file = "$baseDir/$file";
  
  $file =~ s{ \A .+? (/js/ .+ .js) \z }{$1}xms;
  return $file;
}
#----------------------------------------------------
sub _chooseHighestVersion {
  my ($obj, @files) = @_;
  if (@files > 1) {
    my @highestVersion = qw(0 0 0);
    foreach my $_file (@files) {
      next if $_file =~ m{ \A [.] }xms;
      
      my @version = $_file =~ m{ (\d+) [.] (\d+) [.] (\d+) }xms;
      next unless @version;
      
      if ( ($version[0]  > $highestVersion[0])
        || ($version[0] == $highestVersion[0] && $version[1]  > $highestVersion[1])
        || ($version[0] == $highestVersion[0] && $version[1] == $highestVersion[1] && $version[2] > $highestVersion[2])) {
        @highestVersion = @version;
      }
    }
    my $highestVersion = join '.', @highestVersion;
    foreach my $_file (@files) {
      return $_file if $_file =~ m{ \Q$highestVersion\E }xms;
    }
  }
  elsif (@files == 1) {
    return $files[0];
  }
}
#----------------------------------------------------
1;
