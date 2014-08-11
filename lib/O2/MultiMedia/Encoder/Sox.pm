package O2::MultiMedia::Encoder::Sox;

# API for the SOX tool
#  http://sox.sourceforge.net/Main/HomePage
# Now SOX is not really an encoder, but more a sound prosessing tool. However its usage
# fits perfectly with the O2::MultiMedia structure. So I decided to put it here.

use strict;

use base 'O2::MultiMedia::Encoder::Encoder';

#------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = $pkg->SUPER::new(%init);
  
  if ($init{sox}) {
    $obj->{sox} = $init{sox};
    die "Could not locate sox at '$init{sox}'" unless -e $init{sox};
  }
  else {
    $obj->{sox} ||= `which sox`;
    if (!-e $obj->{sox}) {
      my @paths = qw{
        /usr/bin/sox
        /usr/local/bin/sox
        ./sox
      };
      while (!-e $obj->{sox}) {
        $obj->{sox} = shift @paths;
      }
      die "Could not locate sox" unless -e $obj->{sox};
    }
  }
  
  return $obj;
}

#------------------------------------------------------------
sub encode {
  my ($obj, $inMedia, $outMedia) = @_;
  my @cmdArgs = ($inMedia, $outMedia);
  push @cmdArgs, $obj->getCmdOptions();
  my $cmd = "$obj->{sox} " . join ' ', @cmdArgs;
  $obj->_execCMD($cmd);
  return $outMedia;
}
#------------------------------------------------------------
sub getCmdOptions {
  my ($obj) = @_;
  $obj->{_optionRules} ||= $obj->getAvailableOptions();
  my (@options, @effects);
  foreach (keys %{ $obj->{options} }) {
    my $arrRef = $obj->{_optionRules}->{$_}->{isEffect} ? \@effects : \@options;
    
    if ($obj->{_optionRules}->{$_}->{rule} eq 'boolean') {
      push @{$arrRef}, $obj->{_optionRules}->{$_}->{cmd} if exists $obj->{_optionRules}->{$_}->{cmd};
    }
    else {
      push @{$arrRef}, "$obj->{_optionRules}->{$_}->{cmd} $obj->{options}->{$_}" if exists $obj->{_optionRules}->{$_}->{cmd};
    }
  }
  
  return join (' ', @options) . ' ' . join (' ', @effects);
}
#------------------------------------------------------------
sub getEncoderName {
  my ($obj) = @_;
  return 'Sox';
}
#------------------------------------------------------------
sub getAvailableOptions {
  my ($obj) = @_;
  # ref: http://linux.die.net/man/1/sox
  # ref: http://techpubs.sgi.com/library/tpl/cgi-bin/getdoc.cgi?coll=0530&db=man&fname=/usr/share/catman/u_man/cat6/sox.z
  return {
    # general options
    volume => {
      cmd  => '-v',
      rule => '^\d\.\d$', #less than 1.0 decreases, greater than 1.0 increases
    },
    rate   => {
      cmd  => '-r',
      rule => '^\d+$', # hertz
    },
    channels => {
      cmd  =>'-c',
      rule => '^(?:1|2|4)$', # mono, stereo, quad
    },
    verbose => {
      cmd  => '-S',
      rule => 'boolean',
    },
    quiet =>  {
      cmd  => '-q',
      rule => 'boolean',
    },
    # effects
    copy => { 
      cmd      => 'copy',
      isEffect => 1, #internal use
    },
    trim => {
      cmd      => 'trim',
      rule     => '^\d+\s\d+$',
      isEffect => 1, #internal use
    },
    speed => {
      cmd      => 'speed',
      rule     =>'^\d+\.\d{1,2}$',
      isEffect => 1, #internal use
    },
    fade  => {
      cmd      => 'fade',
      rule     => '^\d+\s\d+\s\d+$', # fadeInTime songlength fadeOutTime
      isEffect => 1, #internal use
    },
    echo => {
      cmd      => 'echo',
      isEffect => 1,
      rule     => '^\d+\.\d+\s\d+\s\d+\s\d+\.\d+$', #echo gain-in gain-out delay decay 
    },
  };
}
#------------------------------------------------------------
1;
