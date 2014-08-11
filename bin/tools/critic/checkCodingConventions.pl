use strict;

use O2::Script::Common;

use O2::Util::Args::Simple;

if (scalar(@ARGV) == 0 || $ARGV[0] eq '--help') {
  say("\nUsage:");
  say("  perl $0 --dirs <directory1> <directory2> ... [--severity N]");
  say("  perl $0 --files <file1> <file2> ... [--severity N]");
  say('    N is between 1 and 5');
  say('Example:');
  say("  perl $0 --dirs $ENV{O2ROOT}/t --severity 2\n");
  exit;
}

my $severity;
BEGIN {
  $severity = $ARGV{-severity} || undef;
  eval {
    require Test::Perl::Critic;
  };
  die "\nYou probably need to install Test::Perl::Critic\n\n$@" if $@;
}
use Test::Perl::Critic (
  -severity => $severity,
  -profile  => "$ENV{O2ROOT}/bin/tools/critic/.perlcriticrc",
);
require O2::Template::Critic::Test;
my $templateTester = O2::Template::Critic::Test->new(
  severity => $severity,
  profile  => "$ENV{O2ROOT}/bin/tools/critic/.templatecriticrc",
);
use Test::More qw(no_plan);

my (@files, @dirs);
@files = ref $ARGV{-files} ? @{ $ARGV{-files} } : ( $ARGV{-files} ) if $ARGV{-files};
@dirs  = ref $ARGV{-dirs}  ? @{ $ARGV{-dirs}  } : ( $ARGV{-dirs}  ) if $ARGV{-dirs};
foreach my $file (@files) {
  if ($file =~ m{ svnHookTmp }xms) {
    my $actualFile = $file;
    $actualFile    =~ s{ svnHookTmp/ }{}xms;
    $actualFile    =~ s{ _l_ }{/}xmsg;
    if ($file =~ m{ [.] (?:o2ml|html) \z }xms) {
      $templateTester->critic_ok($file, $actualFile);
    }
    else {
      critic_ok($file, $actualFile);
    }
  }
  elsif ($file =~ m{ [.] (?:o2ml|html) \z }xms) {
    $templateTester->critic_ok($file);
  }
  else {
    critic_ok($file);
  }
}
foreach my $dir (@dirs) {
  $templateTester->critic_ok($dir);
}
