package O2::MultiMedia::Encoder::Encoder;

use strict;

#------------------------------------------------------------
sub new {
  my ($pkg) = @_;
  return bless {
    options      => {},
    profilePaths => "$ENV{O2ROOT}/lib/O2/MultiMedia/Encoder/Profiles",
  }, $pkg;
}
#------------------------------------------------------------
sub encode {
  my ($obj, $inMeida, $outMedia) = @_;
  die 'Override by encoder module';
}
#------------------------------------------------------------
sub getEncoderName {
  my ($obj) = @_;
  die 'Override by encoder module';
}
#------------------------------------------------------------
sub hasOption {
  my ($obj, $option) = @_;
  $obj->{_optionRules} ||= $obj->getAvailableOptions();
  $option = lcfirst $option;
  return exists $obj->{_optionRules}->{$option};
}
#------------------------------------------------------------
sub getOption {
  my ($obj, $option) = @_;
  $option = lcfirst $option;
  return $obj->{options}->{$option} if $obj->hasOption($option);
  return undef;
}
#------------------------------------------------------------
sub setOption {
  my ($obj, $option, $value) = @_;
  $obj->{_optionRules} ||= $obj->getAvailableOptions();
  $option = lcfirst $option;
  
  # does this encoder support this option?
  return 0 unless exists $obj->{_optionRules}->{$option};
  
  my $opt = $obj->{_optionRules}->{$option};
  
  if ($opt->{values} && ref $opt->{values} eq 'ARRAY') {
    my $hasMatch = 0;
    foreach (@{ $opt->{values} }) {
      if ($_ eq $value) {
        $hasMatch = 1;
        last;
      }
    }
    return 0 unless $hasMatch;
  }
  elsif ($opt->{values} && ref  $opt->{values} eq 'HASH') {
    return 0 unless exists($opt->{values}->{$value});
  }
  elsif ($opt->{rule} eq 'boolean' && $value != 1 && $value ne 'yes' && $value ne 'on') {
    return 0;
  }
  elsif ($opt->{rule} && $opt->{rule} ne 'boolean' && $value !~ m|$opt->{rule}|) {
    return 0;
  }
  
  # Ok, this option works for this encoder
  $obj->{options}->{$option} = $value;
  return 1;
}
#------------------------------------------------------------
sub getCmdOptions {
  my ($obj) = @_;
  $obj->{_optionRules} ||= $obj->getAvailableOptions();
  my @params;
  foreach (keys %{ $obj->{options} }) {
    if ($obj->{_optionRules}->{$_}->{rule} eq 'boolean') {
      push @params, "-$obj->{_optionRules}->{$_}->{cmd}" if exists $obj->{_optionRules}->{$_}->{cmd};
    }
    else {
      push @params, "-$obj->{_optionRules}->{$_}->{cmd} $obj->{options}->{$_}" if exists $obj->{_optionRules}->{$_}->{cmd};
    }
  }
  return join ' ', @params;
}
#------------------------------------------------------------
# should return a hash with describing all the options this encoder
# can handle accept.
# format:
#{
#  optionName => {
#    description => 'I18N key',
#    values      => [1,2,3],
#    required    => bool (1,0)
#    rule        => 'regexp',
#  }
#}
# E.g.
#{
#  title => {
#    description => 'o2.encoder.ffmpeg.mediaTitle',
#    required    => 0,
#    rule        => undef,
#  },
#  bitrate => {
#    description => 'o2.encoder.ffmpeg.videoBitrate',
#    require     => 0,
#    rule        => '/^\d+$/',
#  },     
#}
sub getAvailableOptions {
  my ($obj) = @_;
  die 'Override by encoder module';
}
#------------------------------------------------------------
#------------------------------------------------------------
# CMD util methods that plugins can use to perform misc cmd's
#------------------------------------------------------------
sub _execCMD {
  my ($obj, $cmd, $callBack) = @_;
  print "$cmd\n";
  my @output;
  eval {
    my $pid = open (IN, "$cmd |") or die "Error $@";
    while (<IN>) { 
      chomp;
      push @output, $_;
    }
    close IN;
  };
  die "Could not run cmd '$cmd' -> $@ $!" if $@;
  return \@output; 
}
#------------------------------------------------------------
# Profile handling
#------------------------------------------------------------
sub loadProfile {
  my ($obj, $profileName) = @_;
  my $encoderName = $obj->getEncoderName();
  print "$encoderName\n";
  my @paths = split ';', $obj->{profilePaths};
  my $profile;
  foreach my $path (@paths) {
    my fullPath = "$path/$encoderName/$profileName.profile";
    print "\nENCODERPROFILE:|$fullPath|\n";
    if (-e $fullPath) {
      eval {
        $profile = do $fullPath;
      };
      print $@ if $@;
      $obj->setProfile($profile);
      return 1;
    }
  }
  return 0;
}
#------------------------------------------------------------
sub setProfile {
  my ($obj, $profileHash) = @_;
  $obj->{options} = $profileHash;
  return 1;
}
#------------------------------------------------------------
sub getDefaultFileExtension {
  my ($obj) = @_;
  return $obj->{options}->{defaultFileExtension} || 'unknown';
}
#------------------------------------------------------------
1;
