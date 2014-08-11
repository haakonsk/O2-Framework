package O2::Util::Color;

use strict;

#--------------------------------------------------------------------------------------------
sub new {
  my ($package) = @_;
  my $obj = bless {}, $package;
  $obj->{webSafeColors} = [0, 51, 102, 153, 204, 255];
  return $obj;
}
#--------------------------------------------------------------------------------------------
sub getBrightness {
  my ($obj, $hexColor) = @_;

  my ($red, $green, $blue) = $obj->hexToRgb($hexColor);
  require O2::Util::ExternalModule;
  O2::Util::ExternalModule->require('Color::Similarity::HCL');
  my ($hue, $chrome, $luminance) = Color::Similarity::HCL::rgb2hcl($red, $green, $blue);
  return $luminance/135;
}
#--------------------------------------------------------------------------------------------
sub getColorDistance {
  my ($obj, $hexColor1, $hexColor2) = @_;
  require O2::Util::ExternalModule;
  O2::Util::ExternalModule->require('Color::Similarity::HCL');
  my ($red1, $green1, $blue1) = $obj->hexToRgb($hexColor1);
  my ($red2, $green2, $blue2) = $obj->hexToRgb($hexColor2);
  return Color::Similarity::HCL::distance( [$red1, $green1, $blue1],  [$red2, $green2, $blue2] );
}
#--------------------------------------------------------------------------------------------
sub rgbToHex {
  my ($obj, $red, $green, $blue, $skipHash) = @_;
  my @hexs = (
    sprintf ( "%x", $red   ),
    sprintf ( "%x", $green ),
    sprintf ( "%x", $blue  ),
  );
  for (my $i = 0; $i < @hexs; $i++) {
    $hexs[$i] = "0$hexs[$i]" if length $hexs[$i] < 2;
  }
  return ($skipHash ? '' : '#') . join '', @hexs;
}
#--------------------------------------------------------------------------------------------
sub hexToRgb {
  my ($obj, $hexColor) = @_;
  $hexColor =~ m{ \A \# ([0-f]) ([0-f]) ([0-f]) ([0-f]) ([0-f]) ([0-f]) \z }xmsi;
  my $red   = 16*hex($1) + hex($2);
  my $green = 16*hex($3) + hex($4);
  my $blue  = 16*hex($5) + hex($6);
  return ($red, $green, $blue);
}
#--------------------------------------------------------------------------------------------
sub getRandomColor {
  my ($obj, %params) = @_;
  my ($r, $g, $b, $hexColor);
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
    $hexColor      = $obj->rgbToHex($r, $g, $b);
    my $brightness = $obj->getBrightness($hexColor);
    if (   (exists $params{minBrightness} && $brightness < $params{minBrightness})
        || (exists $params{maxBrightness} && $brightness > $params{maxBrightness})
        || (exists $params{illuminance}   && ($r+$g+$b)  > $params{illuminance})
        || ($obj->{previousRandomColor}   && $obj->getColorDistance($hexColor, $obj->{previousRandomColor}) < 500) # The current color mustn't look too much like the previous
       ) {
      # The color isn't good enough.
    }
    else {
      last; # The color is accepted, break out of the loop.
    }
  }
  $obj->{previousRandomColor} = $hexColor;
  return ($r, $g, $b) if $params{colorType} eq 'rgb';
  return $obj->rgbToHex($r, $g, $b);
}
#--------------------------------------------------------------------------------------------
sub getUniqueColor {
  my ($obj, %params) = @_;
  $obj->{knownColors} = {};

  my ($r,$g,$b);
  while (1) {
    ($r, $g, $b) = $obj->getRandomColor(%params, colorType => 'rgb');
    last unless exists $obj->{knownColors}->{"$r$g$b"};
  }
  $obj->{knownColors}->{"$r$g$b"} = 1;

  return "rgb($r, $g, $b)" if lc $params{colorType} eq 'rgb'; # rgb
  return $obj->rgbToHex($r, $g, $b, $params{skipHash});  # hex (default)
}
#--------------------------------------------------------------------------------------------
sub forgetUniqueColors {
  my ($obj) = @_;
  $obj->{knownColors} = [];
}
#--------------------------------------------------------------------------------------------
1;
