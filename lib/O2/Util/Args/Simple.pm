package O2::Util::Args::Simple;

use strict;

use vars qw/%ARGV/;

#----------------------------------------------------
sub import {
  my $package = caller;
  my %args;
  for ($_ = 0; $_<= $#ARGV; $_++) {
    if ($ARGV[$_] =~ m/^-([\w-]+)/) {
      my ($name, $step, @args) = ($1, 1, ());
      while (length ($ARGV[$_+$step]) > 0 && $ARGV[$_+$step] !~ m/^-/) {
        push @args, $ARGV[$_+$step++];
      }
      $args{$name}
        = $#args == -1 ? 1
        : $#args ==  0 ? $args[0]
        :                \@args
        ;
    }
  }
  %ARGV = %args; # If O2::Util::Args::Simple is used from a different package than main, it can still be accessed in the normal way.
                 # Without this line you would have to write *ARGV = *O2::MyPackage::ARGV or something like that.

  # Keeping the following 3 lines for backward compatibility:
  no strict;
  *{$package . '::ARGV'} = \%args;
  use strict;
}
#----------------------------------------------------
1;
