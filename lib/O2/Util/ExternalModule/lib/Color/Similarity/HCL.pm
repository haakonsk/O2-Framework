package Color::Similarity::HCL;

=head1 NAME

Color::Similarity::HCL - compute color similarity using the HCL color space

=head1 SYNOPSIS

  use Color::Similarity::HCL qw(distance rgb2hcl distance_hcl);
  # the greater the distance, more different the colors
  my $distance = distance( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

=head1 DESCRIPTION

Computes color similarity using the color space and distance metric
defined in the paper:

A New Perceptually Uniform Color Space with Associated Color
Similarity Measure for ContentBased Image and Video Retrieval

M. Sarifuddin <m.sarifuddin@uqo.ca> - Rokia Missaoui <rokia.missaoui@uqo.ca>
DE<eacute>partement d'informatique et d'ingE<eacute>nierie,
UniversitE<eacute> du QuE<eacute>bec en Outaouais
C.P. 1250, Succ. B Gatineau
QuE<eacute>ebec Canada, J8X 3X7

=cut

use strict;
use base qw(Exporter);

our $VERSION = '0.02';
our @EXPORT_OK = qw(rgb2hcl distance distance_hcl);

use List::Util qw(max min);
use Math::Trig;

use constant Y0     => 100;
use constant gamma  => 3;
use constant Al     => 1.4456;
use constant Ah_inc => 0.16;

=head1 FUNCTIONS

=head2 distance

  my $distance = distance( [ $r1, $g1, $b1 ], [ $r2, $g2, $b2 ] );

Converts the colors to the HCL space and computes their distance.

=cut

sub distance {
    my( $t1, $t2 ) = @_;

    return distance_hcl( [ rgb2hcl( @$t1 ) ], [ rgb2hcl( @$t2 ) ] );
}

=head2 rgb2hcl

  my( $h, $c, $l ) = rgb2hcl( $r, $g, $b );

Converts between RGB and HCL color spaces.

=cut

sub rgb2hcl {
    my( $r, $g, $b ) = @_;

    my( $min, $max ) = ( min( $r, $g, $b ), max( $r, $g, $b ) );
    return ( 0, 0, 0 ) if $max == 0; # special-case black
    my $alpha = ( $min / $max ) / Y0;
    my $Q = exp( $alpha * gamma );

    my( $rg, $gb, $br ) = ( $r - $g, $g - $b, $b - $r );
    my $L = ( $Q * $max + ( 1 - $Q ) * $min ) / 2;
    my $C = $Q * ( abs( $rg ) + abs( $gb ) + abs( $br ) ) / 3;
    my $H = rad2deg( atan2( $gb, $rg ) );

    # The paper uses 180, not 90, but using 180 gives
    # red the same HCL value as green...
#   Alternative A
#    $H = 90 + $H         if $rg <  0 && $gb >= 0;
#    $H = $H - 90         if $rg <  0 && $gb <  0;
#   Alternative B
    $H = 2 * $H / 3      if $rg >= 0 && $gb >= 0;
    $H = 4 * $H / 3      if $rg >= 0 && $gb <  0;
    $H = 90 + 4 * $H / 3 if $rg <  0 && $gb >= 0;
    $H = 3 * $H / 4 - 90 if $rg <  0 && $gb <  0;

    return ( $H, $C, $L );
}

=head2 distance_hcl

  my $distance = distance_hcl( [ $h1, $c1, $l1 ], [ $h2, $c2, $l2 ] );

Computes the distance between two colors in the HCL color space.

=cut

sub distance_hcl {
    my( $t1, $t2 ) = @_;
    my( $h1, $c1, $l1 ) = @$t1;
    my( $h2, $c2, $l2 ) = @$t2;

    my $Ah = abs( $h1 - $h2 ) + Ah_inc;
    my( $Dl, $Dh ) = ( abs( $l1 - $l2 ), abs( $h1 - $h2 ) );
    return sqrt(
                abs( # In case value < 0 (Håkon, 20070316)
                    ( Al * $Dl ) ** 2
                    + $Ah * (   $c1 ** 2
                                + $c2 ** 2
                                - 2 * $c1 * $c2 * cos( deg2rad( $Dh ) )
                                )
                    )
                );
}

=head1 SEE ALSO

L<http://mmis.doc.ic.ac.uk/mmir2005/CameraReadyMissaoui.pdf>

Corrected 180 to 90 in the RGB -> HCL transformation (see C<rgb2hcl>).

=head1 AUTHOR

Mattia Barbon, C<< <mbarbon@cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2007, Mattia Barbon

This program is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
