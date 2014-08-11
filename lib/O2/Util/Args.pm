package O2::Util::Args;

use strict;

use vars qw/%ARGV $PARAM/;

$PARAM;

#--------------------------------------------------------------------------------------------
sub import {
  shift;
  print "You don't need ".__PACKAGE__." in $0!\nSince no option list is passed to handle args!\n" unless @_;
  %ARGV = %{ &setArgs(@_) };
}
#--------------------------------------------------------------------------------------------
sub setArgs {
  my (%args) = @_;
  my %ret;
  $ret{error} = undef;
  
  my $i = 0;
  
  while ($i <= $#main::ARGV) {
    if ($main::ARGV[$i] =~ m/^-/) {
      my $opt = substr ($main::ARGV[$i], 1, length $main::ARGV[$i]);
      if (!exists $args{$opt}) {
        $ret{error} .= "-$opt is an unknown option\n";
      }
      elsif ($args{$opt} =~ m/^PARAM.*/) {
        if (($i+2) <= $#main::ARGV && $main::ARGV[$i+2] !~ m/^-/) {
          while (($i+1) <= $#main::ARGV && $main::ARGV[$i+1] !~ m/^-/) {
            push @{ $ret{$opt} }, $main::ARGV[++$i] unless ($i+1) > $#main::ARGV;
          }
        }
        elsif (($i+1) <= $#main::ARGV && $main::ARGV[$i+1] !~ m/^-/) {
          $ret{$opt} = $main::ARGV[++$i] unless ($i+1) > $#main::ARGV;
        }
        else {
          $ret{error} .= "-$opt did not get an argument\n";
        }
      }
      elsif ($args{$opt} =~ m/^BOOL/) {
        $ret{$opt} = 1;
      }
    }
    $i++;
  }
  for (keys %args) {
    if (!exists $ret{$_}) {
      if ($args{$_} =~ m/_REQ/) {
        $ret{error} .= "-$_ is an required option\n";
      }
      elsif ($args{$_} =~ m/BOOL/) {
        $ret{$_} = 0;
      }
    }
  }
  return \%ret;
}
#--------------------------------------------------------------------------------------------
1;
