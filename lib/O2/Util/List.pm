package O2::Util::List;

use strict;

use base 'Exporter';

our @EXPORT_OK = qw(upush contains containsAny);

#-------------------------------------------------------------------------------
# Unique push: Only push a value if it doesn't already exist in the array
# Example usage:
#   upush @array, $element;
sub upush (\@@) {
  my ($array, @newElements) = @_;
  no warnings;
  my %elements = map  { $_ => 1 }  @{$array};
  foreach my $element (@newElements) {
    push @{$array}, $element unless $elements{$element};
    $elements{$element} = 1;
  }
  return 1;
}
#-------------------------------------------------------------------------------
sub contains (\@@) {
  my ($array, @elements) = @_;
  my %hash = map  { $_ => 1 }  @{$array};
  foreach my $element (@elements) {
    return 0 unless $hash{$element};
  }
  return 1;
}
#-------------------------------------------------------------------------------
sub containsAny (\@@) {
  my ($array, @elements) = @_;
  my %hash = map  { $_ => 1 }  @{$array};
  foreach my $element (@elements) {
    return 1 if $hash{$element};
  }
  return 0;
}
#-------------------------------------------------------------------------------
1;
