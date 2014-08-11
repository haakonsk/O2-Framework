package O2::Template::Taglibs::Html::Flexigrid;

use strict;

# The reason we have to make flexiTd available everywhere, not just inside <o2 flexigrid> is
# that flexiTd can be in an include template without <o2 flexigrid>

use base 'O2::Template::Taglibs::Html';

#------------------------------------------------------------------
sub register {
  my ($package, %params) = @_;
  my ($obj, %methods) = $package->SUPER::register(%params);
  %methods = (
    %methods,
    flexigrid => 'postfix',
    flexiTh   => '',
    flexiTd   => '',
  );
  return ($obj, %methods);
}
#------------------------------------------------------------------
sub flexigrid {
  my ($obj, %params) = @_;
  
  $params{class} ||= '';
  $params{class}  .= ' flexigrid';
  
  $obj->addJsFile(  file => 'jquery'                   );
  $obj->addJsFile(  file => 'jquery-migrate'           ); # Our version of flexigrid not quite compatible with newer versions of jquery
  $obj->addJsFile(  file => 'taglibs/html/flexigrid'   );
  $obj->addJsFile(  file => 'taglibs/html/o2Flexigrid' );
  $obj->addCssFile( file => 'taglibs/html/flexigrid'   );
  $obj->addCssFile( file => 'taglibs/html/o2Flexigrid' );
  $obj->addJs(
    where   => 'onLoad',
    content => 'o2.flexigrid.init();',
  );
  
  $obj->{cellCount} = 0;
  $obj->{numCells}  = 0;
  
  my $parser = $obj->{parser};
  my $content = delete $params{content};
  $obj->{parser}->_parse(\$content);
  
  return '<table ' . $obj->_packTagAttribs(%params) . ">$content</table>";
}
#------------------------------------------------------------------
sub flexiTh {
  my ($obj, %params) = @_;
  $obj->{abbrs} ||= [];
  my $i = @{ $obj->{abbrs} } + 1;
  $params{abbr} ||= "column$i";
  push @{ $obj->{abbrs} }, $params{abbr};
  return '<th ' . $obj->_packTagAttribs(%params) . ">$params{content}</th>";
}
#------------------------------------------------------------------
sub flexiTd {
  my ($obj, %params) = @_;
  if ($obj->{abbrs}) {
    my $columnNum   = $obj->{cellCount}++  %  @{ $obj->{abbrs} };
    $params{abbr} ||= $obj->{abbrs}->[$columnNum];
  }
  return '<td ' . $obj->_packTagAttribs(%params) . ">$params{content}</td>";
}
#------------------------------------------------------------------
1;
