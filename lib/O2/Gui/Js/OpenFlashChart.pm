package O2::Gui::Js::OpenFlashChart;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi);

#-----------------------------------------------------------------------------
sub getChartData {
  my ($obj) = @_;
  my ($id, $isBackend) = split /-/, $obj->getParam('id-isBackend');
  my $session = $isBackend ? $context->getBackendSession() : $context->getSession();
  my $params = $session->get("ofcGraphParams-$id");
  use Chart::OFC;
  my $chartTypePackage = $obj->_typeToChartTypePackage( $params->{type} );

  require O2::Util::Math;
  $obj->{math} = O2::Util::Math->new();

  my @dataSets;
  my ($minYValue, $maxYValue) = (10_000_000, -10_000_000);
  foreach my $dataSet (@{ $params->{dataSets} }) {
    my $package = $dataSet->{type} ? $obj->_typeToChartTypePackage( $dataSet->{type} ) : $chartTypePackage;
    my $dataSetParams = $obj->_getDataSetParams($package, $dataSet, $params);
    my $max = $obj->_getYMax($dataSetParams->{values}, $params->{type});
    $maxYValue = $max if $max > $maxYValue;
    my $min = $obj->_getYMin($dataSetParams->{values}, $params->{type});
    $minYValue = $min if $min < $minYValue;
    push @dataSets, $package->new( %{$dataSetParams} );
  }
  my %chartParams = (
    title    => $params->{title} || '',
    datasets => \@dataSets,
    x_axis   => $obj->_createXAxis($params),
    y_axis   => $obj->_createYAxis($params, $params->{yMin} || $minYValue, $params->{yMax} || $maxYValue),
  );
  $chartParams{inner_bg_color}      = $params->{bgColor}     if $params->{bgColor};
  $chartParams{inner_bg_color2}     = $params->{bgColor2}    if $params->{bgColor2};
  $chartParams{inner_bg_fade_angle} = $params->{bgFadeAngle} if $params->{bgFadeAngle};
  $chartParams{title_style}         = $params->{titleStyle}  if $params->{titleStyle};
  $chartParams{tool_tip}            = $params->{toolTip}     if $params->{toolTip};
  my $chart = Chart::OFC::Grid->new(%chartParams);
  $cgi->setContentType('text/javascript');
  return print $chart->as_ofc_data();
}
#-----------------------------------------------------------------------------
# Translates O2's type (eg "lines") to Open Flash Chart's type ("Line"). This is to be compatible with gdGraph, making it
# easy to switch from gdGraph to ofcGraph.
sub _typeToChartTypePackage {
  my ($obj, $type) = @_;
  $type ||= '';
  my %translation = (
    ''          => 'Bar', # Default
    bars        => 'Bar',
    lines       => 'Line',
    bars3d      => '3DBar',
    points      => 'Scatter',
    linespoints => 'LineWithDots',
    area        => 'Area',
  );
  return "Chart::OFC::Dataset::$translation{$type}" if $translation{$type};
  return "Chart::OFC::Dataset::$type"; # If no translation exists, we assume the specified type is valid for Open Flash Chart.
}
#-----------------------------------------------------------------------------
sub _createXAxis {
  my ($obj, $params) = @_;
  my %xAxisParams = ( axis_label => $params->{xLabel} || '' );
  $xAxisParams{labels} = $params->{xLabels} if ref $params->{xLabels} && @{ $params->{xLabels} };
  return Chart::OFC::XAxis->new(%xAxisParams);
}
#-----------------------------------------------------------------------------
sub _createYAxis {
  my ($obj, $params, $minYValue, $maxYValue) = @_;
  my $stepSize = $params->{yStepSize} || $obj->_getYStepSize($maxYValue - $minYValue);
  $stepSize    = 1 if $stepSize < 1; # This is a restriction from Open Flash Chart or its Perl API
  my $calculatedMin = $obj->{math}->nearest($stepSize, $minYValue - $stepSize/2);
  $minYValue   =   $params->{yMin}   ?   $params->{yMin}   :   ($calculatedMin < 0 ? $calculatedMin : 0);
  $maxYValue   =   $params->{yMax}   ?   $params->{yMax}   :   $obj->{math}->nearest($stepSize, $maxYValue + $stepSize/2);
  return Chart::OFC::YAxis->new(
    axis_label  => $params->{yLabel} || '',
    max         => $maxYValue,
    min         => $minYValue,
    label_steps => $stepSize,
  );
}
#-----------------------------------------------------------------------------
sub _getYStepSize {
  my ($obj, $range) = @_;
  my $x = 0.4 * $range;
  my $exp = -1;
  if ($x > 1) {
    while ($x > 1) {
      $x /= 10;
      $exp++;
    }
  }
  elsif ($x < 1) {
    while ($x < 1) {
      $x *= 10;
      $exp--;
    }
  }
  my $stepSize = 10**$exp;
  while ($range/$stepSize > 12) {
    $stepSize *= 2;
  }
  while ($range/$stepSize < 4) {
    $stepSize /= 2;
  }
  return $stepSize;
}
#-----------------------------------------------------------------------------
sub _makeNumeric {
  my ($obj, $values) = @_;
  for my $i (0  ..  @{$values} - 1) {
    if (ref $values->[$i]) {
      for my $j (0  ..  @{ $values->[$i] } - 1) {
        $values->[$i]->[$j] += 0;
      }
    }
    else {
      $values->[$i] += 0;
    }
  }
  return $values;
}
#-----------------------------------------------------------------------------
sub _getYMax {
  my ($obj, $values, $type) = @_;
  my $max = -10_000_000;
  for my $value (@{$values}) {
    if (ref $value) {
      $max = $value->[1] > $max ? $value->[1] : $max;
    }
    else {
      $max = $value if $value > $max;
    }
  }
  return $max;
}
#-----------------------------------------------------------------------------
sub _getYMin {
  my ($obj, $values, $type) = @_;
  my $min = 10_000_000;
  for my $value (@{$values}) {
    if (ref $value) {
      $min = $value->[1] < $min ? $value->[1] : $min;
    }
    else {
      $min = $value if $value < $min;
    }
  }
  return $min;
}
#-----------------------------------------------------------------------------
sub _getDefaultColor {
  my ($obj) = @_;
  $obj->{colors} = ['#000000', '#990000', '#009999', '#009900', '#006666', '#666666', '#000099', '#660066'] if !$obj->{colors} || !@{ $obj->{colors} };
  return shift @{ $obj->{colors} };
}
#-----------------------------------------------------------------------------
sub _getDataSetParams {
  my ($obj, $package, $dataSet, $params) = @_;
  my %dataSetParams;
  $dataSetParams{label}     = $dataSet->{description} if $dataSet->{description};
  $dataSetParams{text_size} = $dataSet->{textSize}    if $dataSet->{textSize};
  $dataSetParams{links}     = $dataSet->{links}       if $dataSet->{links};

  $dataSetParams{values} = $obj->_makeNumeric( $dataSet->{content} );
  my $color = $dataSet->{color} || $params->{graphColor} || $obj->_getDefaultColor();
  if ($obj->_isBar($package) || $package =~ m{ ::Area \z }xms) {
    $dataSetParams{fill_color} = $color;
  }
  if ($obj->_isLine($package)) {
    $dataSetParams{color} = $color;
    $dataSetParams{width} = $dataSet->{width} || $params->{lineWidth} if $dataSet->{width} || $params->{lineWidth};
  }
  if ($package =~ m{ ::LineWithDots \z }xms) {
    my $solidDots = !defined $params->{solidDots}  ||  ($params->{solidDots} && $params->{solidDots} ne '0');
    $solidDots    = $dataSet->{solidDots} && $dataSet->{solidDots} ne '0' if defined $dataSet->{solidDots};
    $dataSetParams{solid_dots} = $solidDots;
  }
  if ($obj->_isBar($package) || $obj->_isHighLowClose($package) || $package =~ m{ ::Area \z }xms) {
    $dataSetParams{opacity} = $dataSet->{opacity} || $params->{opacity} if $dataSet->{opacity} || $params->{opacity};
  }
  if ($package =~ m{ :: (?: Area | LineWithDots ) \z }xms) {
    $dataSetParams{dot_size} = $dataSet->{dotSize} || $params->{dotSize} if $dataSet->{dotSize} || $params->{dotSize};
  }
  if ($obj->_isOutlinedBar($package)) {
    $dataSetParams{outline_color} = $dataSet->{outlineColor} || $params->{outlineColor} if $dataSet->{outlineColor} || $params->{outlineColor};
  }
  if ($package =~ m{ ::SketchBar \z }xms) {
    $dataSetParams{randomness} = $dataSet->{randomness} || $params->{randomness} if $dataSet->{randomness} || $params->{randomness};
  }
  return \%dataSetParams;
}
#-----------------------------------------------------------------------------
sub _isBar {
  my ($obj, $package) = @_;
  return $package =~ m{ :: (?: Bar | 3DBar | OutlinedBar | GlassBar | FadeBar | SketchBar ) \z }xms;
}
#-----------------------------------------------------------------------------
sub _isLine {
  my ($obj, $package) = @_;
  return $package =~ m{ :: (?: Line | LineWithDots | Scatter | Area | Candle | HighLowClose ) \z }xms;
}
#-----------------------------------------------------------------------------
sub _isHighLowClose {
  my ($obj, $package) = @_;
  return $package =~ m{ :: (?: HighLowClose | Candle ) \z }xms;
}
#-----------------------------------------------------------------------------
sub _isOutlinedBar {
  my ($obj, $package) = @_;
  return $package =~ m{ :: (?: OutlinedBar | GlassBar | SketchBar ) \z }xms;
}
#-----------------------------------------------------------------------------
1;
