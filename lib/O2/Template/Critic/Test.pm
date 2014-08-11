package O2::Template::Critic::Test;

use strict;

use O2 qw($context);

use Test::Builder;
my $TEST = Test::Builder->new();

#-----------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $obj = bless {}, $package;
  $obj->{severity} = $params{severity};
  $obj->{profile}  = $params{profile};
  return $obj;
}
#-----------------------------------------------------------------------------
sub critic_ok {
  my ($obj, $file, $testName) = @_;
  if (-d $file) {
    my @allFiles = $obj->_findFiles($file);
    foreach my $file (@allFiles) {
      $obj->critic_ok($file);
    }
    return;
  }
  my $critic = $obj->_getCritic();
  die 'No file specified'      unless defined $file;
  die "'$file' does not exist" unless      -f $file;
  $testName ||= "O2::Template::Critic::Test for '$file'";

  my @violations;
  my $ok = 0;

  eval {
    @violations = $critic->critique($file);
    my $numViolations = scalar @violations;
    if (scalar(@violations) > 1) {
      require O2::Template::Critic::Violation;
      @violations = O2::Template::Critic::Violation::sortByLocation(@violations);
    }
    $ok = scalar(@violations) == 0;
  };

  $TEST->ok( $ok, $testName );

  if ($@) {
    $TEST->diag("\nO2::Template::Critic had errors in '$file':\n\t$@");
  }
  elsif (!$ok) {
    $TEST->diag("\nO2::Template::Critic found these violations in '$file':" );
    foreach my $violation (@violations) {
      $TEST->diag( $violation->toString() );
    }
  }

  return $ok;
}
#-----------------------------------------------------------------------------
sub _getCritic {
  my ($obj) = @_;
  if (!$obj->{critic}) {
    require O2::Template::Critic;
    $obj->{critic} = O2::Template::Critic->new(
      severity => $obj->{severity},
      profile  => $obj->{profile},
    );
  }
  return $obj->{critic};
}
#-----------------------------------------------------------------------------
sub _findFiles {
  my ($obj, $dir) = @_;
  my @files = $context->getSingleton('O2::File')->scanDir($dir);
  my @allFiles;
  foreach my $file (@files) {
    next if $file =~ m{ \A [.] }xms;
    if ($file =~ m{ [.]html \z }xms) {
      push @allFiles, "$dir/$file";
    }
    elsif (-d "$dir/$file") {
      push @allFiles, $obj->_findFiles("$dir/$file");
    }
  }
  return @allFiles;
}
#-----------------------------------------------------------------------------
1;
