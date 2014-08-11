package O2::Template::Taglibs::Html::RandomColor;

# Random Html Color generator

use strict;

use base 'O2::Template::Taglibs::Html';

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;

  my ($obj, %methods) = $package->SUPER::register(%params);
  
  # actually  cross platform color, ref: http://www.w3schools.com/html/html_colors.asp
  $obj->{webSafeColors} = [ 0, 51, 102, 153, 204, 255 ]; # In hex: 00, 33, 66, 99, cc, ff ;
  
  %methods = (
    %methods,
    'uniqueColor'
  );

  $obj->{colorCount} = 0;
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub uniqueColor {
  my ($obj, %params) = @_;
  
  $obj->{knownColor}->{''} = 1;

  my ($r, $g, $b);
  require O2::Util::Color;
  my $colorMgr = O2::Util::Color->new();

  while (1) {
    if ($params{webSafeColor}) {
      $r = $obj->{webSafeColors}->[ int rand @{ $obj->{webSafeColors} } ];
      $g = $obj->{webSafeColors}->[ int rand @{ $obj->{webSafeColors} } ];
      $b = $obj->{webSafeColors}->[ int rand @{ $obj->{webSafeColors} } ];
    }
    else {
      $r = int rand 255;
      $g = int rand 255;
      $b = int rand 255;
    }
    my $hexColor   = $colorMgr->rgbToHex( $r, $g, $b, $params{skipHash} );
    my $brightness = $colorMgr->getBrightness($hexColor);
    if (    exists $params{minBrightness} && $brightness < $params{minBrightness}
        ||  exists $params{maxBrightness} && $brightness > $params{maxBrightness}
        ||  exists $obj->{knownColor}->{"$r$g$b"}
        || (exists $params{illuminance} && ($r+$g+$b) > $params{illuminance})
       ) {
#      print "<li>Wrong brightness: $brightness. min: $params{minBrightness}, max: $params{maxBrightness}";
    }
#    elsif ($params{maxBrightness} != 1) {
#      print "<li>Brightness: $brightness";
#    }
    else {
      last;
    }
  }
#  print "<li>$r $g $b  ".($r+$g+$b)." $params{illuminance}  ". sprintf("%X", $r).sprintf("%X", $g).sprintf("%X", $b); 
  $obj->{colorCount}++;
  $obj->{knownColor}->{"$r$g$b"} = $obj->{colorCount};

# This looks strange, commenting it out...
#  if($params{webSafeColor} && $obj->{colorCount} >=216) {
#    $obj->{colorCount};
#  }

  $params{colorType} ||= 'hex';
  return "rgb($r, $g, $b)" if lc $params{colorType} eq 'rgb';
  return $colorMgr->rgbToHex( $r, $g, $b, $params{skipHash} );
}
#--------------------------------------------------------------------------------------------
1;
