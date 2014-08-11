package O2::Template::Taglibs::Chart::OpenFlashChart;

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context $cgi $session);

#-----------------------------------------------------------------------------
sub register {
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    ofcGraph => 'postfix',
  );
  return $obj, %methods;
}
#-----------------------------------------------------------------------------
sub ofcGraph {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params, 1);
  
  # Check if Chart::OFC is installed
  eval {
    require Chart::OFC;
  };
  die "Couldn't load Chart::OFC: $@" if $@;

  my $errorMsg = $obj->_validateParams(\%params);
  die $errorMsg if $errorMsg;

  $obj->{ofcGraphParams} = \%params;
  $obj->{ofcGraphParams}->{dataSets} = [];
  $obj->addJsFile( file => 'OpenFlashChart/1/swfobject' );
  # swfobject.embedSWF is described at http://code.google.com/p/swfobject/wiki/documentation

  $obj->{parser}->pushPostfixMethod('dataSet', $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('dataSet', $obj);

  my $id = $params{id};
  if (!$id) { # Generate unique id:
    use Digest::MD5('md5_hex');
    require Data::Dumper;
    $id = md5_hex( Data::Dumper::Dumper(\%params) );
  }
  $session->set("ofcGraphParams-$id", $obj->{ofcGraphParams});
  $session->save();
  my $chartDataUrl = $context->getSingleton('O2::Util::UrlMod')->urlMod(
    setDispatcherPath => 'o2',
    setClass          => 'Js-OpenFlashChart',
    setMethod         => 'getChartData',
    setParams         => "id-isBackend=$id-" . $cgi->getCurrentUrl() =~ m{ \A /o2cms/ }xms,
    # We can only set one url parameter, but need two, so we're doing a little hack here..
  );
  require O2::Image::Chart::OpenFlashChart::1::open_flash_chart;
  return O2::Image::Chart::OpenFlashChart::1::open_flash_chart::swf_object($params{width} || 640, $params{height} || 400, $chartDataUrl);
}
#-----------------------------------------------------------------------------
sub dataSet {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params);
  push @{ $obj->{ofcGraphParams}->{dataSets} }, \%params;
}
#-----------------------------------------------------------------------------
sub _setupParams {
  my ($obj, $params, $ignoreContent) = @_;
  foreach my $key (keys %{$params}) {
    next if $ignoreContent && $key eq 'content';
    if (($key eq 'xLabels' || $key eq 'content' || $key eq 'links') && $params->{$key} =~ m{ \A \$ \w+ \z }xms) {
      $params->{$key} = $obj->{parser}->findVar( $params->{$key} );
    }
    else {
      $obj->{parser}->parseVars( \$params->{$key} );
      if ($key eq 'content' && !ref $params->{content}) {
        $params->{content}   =   $params->{separator}   ?   [ split /\Q$params->{separator}\E/, $params->{content} ]   :   [ split /,\s*/, $params->{content} ];
      }
      if ($key eq 'xLabels' && !ref $params->{xLabels}) {
        $params->{xLabels}   =   $params->{xLabelSeparator}   ?   [ split /\Q$params->{xLabelSeparator}\E/, $params->{xLabels} ]   :   [ split /,\s*/, $params->{xLabels} ];
      }
      if ($key eq 'links' && !ref $params->{links}) {
        $params->{links} = [ split /,\s*/, $params->{links} ];
      }
    }
  }
  return if $ignoreContent;
  if ($obj->{ofcGraphParams}->{type} eq 'Scatter') {
    foreach my $i (0  ..  @{ $params->{content} } - 1) {
      if (!ref $params->{content}->[$i]) {
        $params->{content}->[$i] = [ $i, $params->{content}->[$i], $params->{circleSize} || $obj->{ofcGraphParams}->{circleSize} || 5 ];
      }
    }
  }
  return $params;
}
#-----------------------------------------------------------------------------
sub _validateParams {
  my ($obj, $params) = @_;
  if ( ($params->{bgColor2}  &&  !$params->{bgFadeAngle})   ||   ($params->{bgFadeAngle}  &&  !$params->{bgColor2}) ) {
    return "Can't use bgColor2 without bgFadeAngle or vice versa";
  }
  if ($params->{type} eq 'HighLowClose' || $params->{type} eq 'Candle') {
    return "type=$params->{type} not implemented";
  }
  return;
}
#-----------------------------------------------------------------------------
1;
