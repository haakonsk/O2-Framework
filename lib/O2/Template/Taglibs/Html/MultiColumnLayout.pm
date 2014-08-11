package O2::Template::Taglibs::Html::MultiColumnLayout;

use strict;

use base 'O2::Template::Taglibs::Html';

#-----------------------------------------------------------------------------
sub register {
  my ($package, %params) = @_;
  
  my ($obj, %methods) = $package->SUPER::register(%params);
  
  require O2::Util::Math;
  $obj->{math} = O2::Util::Math->new();
  
  $obj->addCssFile( file => 'taglibs/multiColumnLayout' );
  $obj->addJsFile(  file => 'taglibs/multiColumnLayout' );
  
  $obj->addJs(
    where   => 'onLoad',
    content => 'o2.multiColumnLayout.adjustAllColumnWidths();',
  );
  
  %methods = (
    %methods,
    multiColumnLayout => 'postfix',
  );
  
  return ($obj, %methods);
}
#-----------------------------------------------------------------------------
sub multiColumnLayout {
  my ($obj, %params) = @_;
  
  $obj->{colNum}  = 1;
  $obj->{columns} = [];
  
  my $html = '';
  
  # Parse the content
  $obj->{parser}->pushMethod('column', $obj);
  $html .= ${  $obj->{parser}->_parse( \$params{content} )  };
  $obj->{parser}->popMethod('column', $obj);
  
  my @widths = $obj->_calculateWidths();
  my $id = $params{id} || 'multiColumnLayout_' . $obj->_getRandomId();
  $html .= "<div class='clearFix'></div>";
  
  # Format style attribute
  my $style = delete $params{style} || '';
  if (my $width = $params{width}) {
    $style .= '; ' if $style && $style !~ m{ ; \s* \z }xms;
    $style .= "width: $width";
    $style .= 'px' if $width =~ m{ \A \d+ \z }xms;
  }
  $style = "style='$style'" if $style;
  
  return "<div class='multiColumnLayout' id='$id' widths='" . join (',', @widths) .  "' $style " . $obj->_packTagAttribs(%params) . ">\n$html</div>\n";
}
#-----------------------------------------------------------------------------
sub column {
  my ($obj, %params) = @_;
  my $colNum = $obj->{colNum}++;
  my $class = $params{class} ? "$params{class} multiColumn multiColumn$colNum" : "multiColumn multiColumn$colNum";
  
  push @{ $obj->{columns} }, {
    width => $params{width},
  };
  
  return "<div class='$class' " . $obj->_packTagAttribs(%params) . ">$params{content}</div>\n";
}
#-----------------------------------------------------------------------------
sub _calculateWidths {
  my ($obj) = @_;
  
  # Find the default width (in percent) of columns without specified width
  my @widths = map  { $_->{width} }  @{ $obj->{columns} };
  my $numColumnsWithoutSpecifiedWidth =   0;
  my $remainingPercents               = 100;
  foreach my $width (@widths) {
    $numColumnsWithoutSpecifiedWidth++ if !$width || lc ($width) eq 'auto';
    {
      no warnings;
      $remainingPercents -= int $width if $width && $width =~ m{ % \z }xms;
    }
  }
  my $defaultWidth = 0;
  $defaultWidth = ($obj->{math}->floor(  10 * $remainingPercents / $numColumnsWithoutSpecifiedWidth  ) / 10)  .  '%' if $numColumnsWithoutSpecifiedWidth;
  
  # Update the column widths where necessary
  foreach my $column (@{ $obj->{columns} }) {
    if (!$column->{width}  ||  lc ( $column->{width} ) eq 'auto') {
      $column->{width} = $defaultWidth;
    }
    elsif ($column->{width} =~ m{ \A \d+ \z }xms) {
      $column->{width} = "$column->{width}px";
    }
  }
  
  # Return an array containing the updated widths of the columns. ($obj->{columns} has also been modified.)
  return map  { $_->{width} }  @{ $obj->{columns} };
}
#-----------------------------------------------------------------------------
1;
