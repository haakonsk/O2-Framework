package O2::Template::Taglibs::Chart::FusionChart;

# Flash Charts ref: http://www.fusioncharts.com/free/
#  doc: http://www.fusioncharts.com/free/docs/?gMenuItemId=19
#  gallery: http://www.fusioncharts.com/free/Gallery.asp?gMenuItemId=3
#  O2 example: http://dev.mre.no/o2/Test/fusionCharts

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context $config);

#-----------------------------------------------------------------------------
sub register {
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    fusionChart => 'postfix',
  );
  $obj->{_chartTypes} = {
    Line             => 'single',
    Column3D         => 'single',
    Pie2D            => 'single',
    Pie3D            => 'single',
    MSLine           => 'multiple',
    Bar2D            => 'single',
    Doughnut2D       => 'single',
    Area2D           => 'single',
    StackedArea2D    => 'multiple',
    StackedColumn2D  => 'multiple',
    MSColumn2DLineDY => 'multiple',
    Funnel           => 'single',
#    Gantt            => ''
#    Candlestick      => 'multiple',
  };
  
  return ($obj, %methods);
}
#-----------------------------------------------------------------------------
sub fusionChart {
  my ($obj, %params) = @_;

  my $chartId   = delete $params{id} || 'fusionChart_' . $obj->_getRandomId();
  my $chartType = delete $params{type};
  $obj->{chartType} = $chartType;
  my $chartWidth  = delete $params{width}  || 600;
  my $chartHeight = delete $params{height} || 400;
  
  $obj->{chartData} = {};
  $obj->{parser}->pushPostfixMethod('categories' => $obj);
  $obj->{parser}->pushPostfixMethod('trendLines' => $obj);
  
  if ($obj->{_chartTypes}->{ $obj->{chartType} }  eq  'single') {
    $obj->{parser}->pushPostfixMethod('set' => $obj);
  }
  else {
    $obj->{parser}->pushPostfixMethod('dataSet' => $obj);
    $obj->{parser}->pushPostfixMethod('dataset' => $obj);
  }
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('categories' => $obj);
  $obj->{parser}->popMethod('trendLines' => $obj);
  if ($obj->{_chartTypes}->{ $obj->{chartType} }  eq  'single') {
    $obj->{parser}->popMethod('set' => $obj);
  }
  else {
    $obj->{parser}->popMethod('dataSet' => $obj);
    $obj->{parser}->popMethod('dataset' => $obj);
  }
  
  delete $params{content};
  
  foreach (keys %params) {
    $obj->{parser}->parseVars( \$params{$_} );
  }
  
  $obj->{chartData}->{attributes} = \%params;
  
  $obj->addJsFile(file => '/flash/FusionChartsFree/FusionCharts.js');
  
  my $xmlUrl = $obj->_toXml($chartId);
  print "<li>$chartId: <a href='$xmlUrl'>$xmlUrl</a>" if $params{debug};
  my $jsCode = '';
  
  if ($chartWidth eq 'auto') {
    $jsCode = qq{
      var offsetWidth = document.getElementById('$chartId').offsetWidth;
      var height = offsetWidth;
    };
  }
  else {
    $jsCode = "var height = $chartWidth";
  }
  my $jsDef = qq{
    <script type="text/javascript">
      $jsCode
      var chart = new FusionCharts("/flash/FusionChartsFree/FCF_$chartType.swf", "$chartId", height, "$chartHeight");
      chart.setDataURL("$xmlUrl");
      chart.render("$chartId");
    </script>
  };
  
  return qq{<div id="$chartId">$jsDef</div>};
}
#-----------------------------------------------------------------------------
sub categories {
  my ($obj, %params) = @_;
  $obj->{parser}->pushPostfixMethod('category' => $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('category' => $obj);
}
#-----------------------------------------------------------------------------
sub category {
  my ($obj, %params) = @_;
  delete $params{content};
  $obj->{parser}->_parse( \$params{name} );
  my $cat = { name => $params{name} };
  $cat->{showName} = $params{showName} ? 1 : 0 if exists $params{showName};
  push @{ $obj->{chartData}->{categories} }, $cat;
}
#-----------------------------------------------------------------------------
sub dataset {
  my ($obj, @params) = @_;
  return $obj->dataSet(@params);
}
#-----------------------------------------------------------------------------
sub dataSet {
  my ($obj, %params) = @_;
  
  $obj->{_currentDataSet} = [];
  
  $obj->{parser}->pushPostfixMethod('set' => $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('set' => $obj);
  
  delete $params{content};
  foreach (keys %params) {
    $obj->{parser}->_parse( \$params{$_} );
  }
  
  if (!exists $params{color}) {
    my $colorObj = $context->getSingleton('O2::Util::Color');
    $params{color} = $colorObj->getUniqueColor(webSafeColor => 1);
  }
  
  push @{ $obj->{chartData}->{dataSets} }, {
    %params,
    values  => $obj->{_currentDataSet} ,
  };
}
#-----------------------------------------------------------------------------
sub set {
  my ($obj, %params) = @_;
  delete $params{content};
  foreach (keys %params) {
    $obj->{parser}->_parse( \$params{$_} );
  }
  if ($obj->{_chartTypes}->{ $obj->{chartType} }  eq  'single') {
    push @{ $obj->{chartData}->{dataSet} }, \%params; 
  }
  else {
    push @{ $obj->{_currentDataSet} }, \%params;
  }
}
#-----------------------------------------------------------------------------
sub trendLines {
  my ($obj, %params) = @_;
  $obj->{parser}->pushPostfixMethod('line' => $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('line' => $obj);
}
#-----------------------------------------------------------------------------
sub line {
  my ($obj, %params) = @_;
  delete $params{content};
  foreach (keys %params) {
    $obj->{parser}->_parse( \$params{$_} );
  }
  push @{ $obj->{chartData}->{trendLines} }, \%params; 
}
#-----------------------------------------------------------------------------
sub _toXml {
  my ($obj, $chartId) = @_;
  
  my $xml = "";
  if ($obj->{_chartTypes}->{ $obj->{chartType} }  eq  'single') {
    $xml .= $obj->_buildSetTag();
  }
  else {
    $xml .= $obj->_buildCategoryTag(); # xLabels
    $xml .= ($xml ? "\n" : '') . $obj->_buildDataSetTag();
  }
  $xml .= $obj->_buildTrendLines();
  $xml  = $obj->_buildTag( 'graph', $obj->{chartData}->{attributes}, $xml );
  
  my $path = $config->get('file.basePath') . '/fusionCharts';
  my $url  = $config->get('file.baseUrl')  . '/fusionCharts';
  
  my $fileMgr = $context->getSingleton('O2::File');
  $fileMgr->mkPath($path) unless -d $path; # create the xml path
  
  my $epochNow = time;
  # XXX This is not optimal. We need a system to store new files and a system to delete after ttl has expired ala SimpleCache.
  my @files = $fileMgr->scanDir($path, '.xml');
  foreach my $f (@files) {
    my @d = split /_/, $f;
    my $createTime = $d[0];
    unlink "$path/$f" if $createTime ne 'static' && $createTime < $epochNow-60 && -e "$path/$f"; # 1 min ttl
  }
  
  my $file = $epochNow . '_fusionchart_' . $chartId . '_' . $$ . '.xml';
  
  $fileMgr->writeFile("$path/$file", $xml);
  return "$url/$file";
}
#-----------------------------------------------------------------------------
sub _buildTag {
  my ($obj, $tagName, $attributes, $data) = @_;
  my $attribs = join ' ',  map { qq{$_="$attributes->{$_}"} }  keys %{$attributes};
  return "<$tagName $attribs" . ($data ? '' : '/') . ">\n" . ($data ? "$data\n</$tagName>" : '');
}
#-----------------------------------------------------------------------------
sub _buildCategoryTag {
  my ($obj) = @_;
  my $xml = '';
  foreach my $cat (@{ $obj->{chartData}->{categories} }) {
    $xml .= $obj->_buildTag('category', $cat);
  }
  return $obj->_buildTag('categories', {}, $xml);
}
#-----------------------------------------------------------------------------
sub _buildSetTag {
  my ($obj) = @_;
  my $xml = '';
  foreach my $set (@{ $obj->{chartData}->{dataSet} }) {
    $xml .= $obj->_buildTag('set', $set);
  }
  return $xml;
}
#-----------------------------------------------------------------------------
sub _buildDataSetTag {
  my ($obj) = @_;
  my $xml = '';
  
  foreach my $set (@{ $obj->{chartData}->{dataSets} }) {
    my $setXml;
    foreach my $setValue (@{ $set->{values} }) {
      $setXml .= $obj->_buildTag('set', $setValue);
    }
    delete $set->{values};
    $xml .= $obj->_buildTag('dataset', $set, $setXml) . "\n";
  }
  
  return $xml;
}
#-----------------------------------------------------------------------------
sub _buildTrendLines {
  my ($obj) = @_;
  return unless $obj->{chartData}->{trendLines};
  my $xml = '';
  foreach my $line (@{ $obj->{chartData}->{trendLines} }) {
    $xml .= $obj->_buildTag('line', $line);
  }
  return $obj->_buildTag('trendLines', {}, $xml);
}
#-----------------------------------------------------------------------------
1;
