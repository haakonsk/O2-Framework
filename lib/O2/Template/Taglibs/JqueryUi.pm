package O2::Template::Taglibs::JqueryUi;

use strict;

use base 'O2::Template::Taglibs::Jquery';

use constant DEBUG => 0;
use O2 qw($context $cgi $config);

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my $version  = delete $params{version};
  my $minified = $params{minified};
  if (!exists $params{minified} || $params{minified} eq 'maybe') {
    my $serverType = $config->get('o2.serverType');
    $minified = $serverType eq 'stage' || $serverType eq 'prod';
  }
  
  my ($obj, %methods) = $package->SUPER::register(%params);
  
  my $jqueryUiIsIncluded = $obj->_jqueryUiJsHasBeenIncluded();
  if (!$jqueryUiIsIncluded || $params{important}) {
    my $theme = delete $params{theme} || '';
    
    my $jqueryUiJsFile  = $obj->_getJsFile('jquery-ui', $version, $theme, $minified);
    my $jqueryJsFile    = $obj->_getJqueryJsFileForChosenJqueryUi();
    my $jqueryUiCssFile = $obj->_getJqueryUiCssFile($theme, $version, $minified);
    
    if (!$jqueryUiIsIncluded) {
      $obj->addCssFile( file => $jqueryUiCssFile );
      if (my $includedJqueryJsFile = $obj->_jqueryJsHasBeenIncluded()) {
        $obj->replaceJsFile( $includedJqueryJsFile, $jqueryJsFile ) if $includedJqueryJsFile ne $jqueryJsFile;
      }
      else {
        $obj->addJsFile( file => $jqueryJsFile ); # Must come before jquery-ui.js
      }
      $obj->addJsFile( file => $jqueryUiJsFile ); # This is jquery-ui.js
      
      my $includedJqueryFiles = {
        jqueryUiJs  => $jqueryUiJsFile,
        jqueryUiCss => $jqueryUiCssFile,
        jqueryJs    => $jqueryJsFile,
      };
      $obj->{parser}->setProperty('includedJqueryFiles', $includedJqueryFiles);
    }
    elsif ($params{important}) {
      my $includedJqueryFiles = $obj->{parser}->getProperty('includedJqueryFiles');
      $obj->replaceJsFile(  $includedJqueryFiles->{jqueryUiJs},  $jqueryUiJsFile  );
      $obj->replaceJsFile(  $includedJqueryFiles->{jqueryJs},    $jqueryJsFile    );
      $obj->replaceCssFile( $includedJqueryFiles->{jqueryUiCss}, $jqueryUiCssFile );
    }
  }
  
  $obj->_loadPlugins( $params{loadPlugins}, $minified ) if $params{loadPlugins};
  
  return ($obj, %methods);
}
#----------------------------------------------------
sub _jqueryUiJsHasBeenIncluded {
  my ($obj) = @_;
  my %jsFiles = %{ $obj->{parser}->getProperty('javascriptFiles') };
  my @jsFiles = keys %{ $jsFiles{pre} };
  foreach my $file (@jsFiles) {
    return 1 if $file =~ m{ jquery-ui-\d }xms;
  }
  return 0;
}
#----------------------------------------------------
sub _jqueryUiCssHasBeenIncluded {
  my ($obj) = @_;
  my @cssFiles = keys %{ $obj->{parser}->getProperty('seenCssFiles') || {} };
  foreach my $file (@cssFiles) {
    return 1 if $file =~ m{ jquery-ui-\d }xms;
  }
  return 0;
}
#----------------------------------------------------
sub _getJqueryUiCssFile {
  my ($obj, $theme, $version, $minified) = @_;
  $version ||= '';
  $theme   ||= 'smoothness';
  
  my $fileMgr = $context->getSingleton('O2::File');
  my $baseDir = $context->getFwPath() . "/var/www/js/jquery-ui";
  my @files = $fileMgr->scanDir($baseDir, "*$version*") or die "Didn't find jquery-ui version $version";
  my $dir = "$baseDir/" . $obj->_chooseHighestVersion(@files) . "/$theme/css/$theme";
  die "Didn't find theme: $theme" unless -d $dir;
  
  my ($file) = $fileMgr->scanDir($dir, "*min.css");
  $file =~ s{ [.]min[.]css }{.css}xms unless $minified;
  $file = "$dir/$file";
  $file =~ s{ \A .+? (/js/ .+ .css) \z }{$1}xms;
  return $file;
}
#----------------------------------------------------
sub _getJqueryJsFileForChosenJqueryUi {
  my ($obj) = @_;
  my $dir = $obj->{parser}->getVar('jquery-uiBaseDir');
  my @files = $context->getSingleton('O2::File')->scanDir($dir, 'jquery-*.js');
  my $file;
  foreach my $_file (@files) {
    if ($_file =~ m{ \A jquery-\d .* [.]js \z }xms) {
      $file = $_file;
      last;
    }
  }
  die "Didn't find jquery file for jquery-ui in directory '$dir'" unless $file;
  
  $dir =~ s{ \A .* (/var/www/js) }{/js}xms;
  return "$dir/$file";
}
#----------------------------------------------------
sub _loadPlugins {
  my ($obj, $plugins, $minified) = @_;
  my @plugins = split /\s*,\s*/, $plugins;
  foreach my $plugin (@plugins) {
    $obj->_loadPlugin($plugin, $minified);
  }
}
#----------------------------------------------------
sub _loadPlugin {
  my ($obj, $plugin, $minified) = @_;
  my @jsFiles = keys %{ $obj->{parser}->getProperty('javascriptFiles')->{pre} };
  my $jqueryUiJsFile;
  foreach my $file (@jsFiles) {
    if ($file =~ m{ jquery-ui-\d }xms && $file !~ m{ development-bundle }xms) {
      $jqueryUiJsFile = $file;
      last;
    }
  }
  $jqueryUiJsFile  =~ s{ (/js/ .+) /js .+ \z }{$1}xms;
  $jqueryUiJsFile .= "/development-bundle/ui/minified/jquery.ui.$plugin.min.js" if $minified;
  $jqueryUiJsFile .= "/development-bundle/ui/jquery.ui.$plugin.js"          unless $minified;
  
  my $wasReplaced = 0;
  foreach my $file (@jsFiles) {
    if ($file =~ m{ /development-bundle/ui .* jquery[.]ui[.]$plugin .* [.]js \z }xms) {
      $obj->replaceJsFile( $file => $jqueryUiJsFile );
      $wasReplaced = 1;
      last;
    }
  }
  if (!$wasReplaced) {
    $obj->addJsFile( file => $jqueryUiJsFile );
  }
}
#----------------------------------------------------
1;
