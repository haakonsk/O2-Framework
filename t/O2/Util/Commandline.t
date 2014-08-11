use strict;
use warnings;

use Test::More qw(no_plan);

use_ok('O2::Util::Commandline');
my $cmdline = O2::Util::Commandline->new();
isa_ok( $cmdline => 'O2::Util::Commandline');

if (@ARGV && $ARGV[0] eq '--manual') {
  my $path = 'o2utilcommandline.txt';
  $cmdline->cls();
  $cmdline->heading('Manual testing O2::Util::Commandline');
  $cmdline->divider();
  $cmdline->blank();
  $cmdline->say('TESTINGTESTINGTESTINGTESTINGTESTINGTESTING');
  ok( ($cmdline->ask('Did we now clear the screen, write a heading, a blank, a divider, a blank and a line with lots of text?', 'yes') eq 'yes'), 'Screen handling + ask');
  ok( ($cmdline->confirm('Please confirm', 'y'), 'y'), 'Confirm');
  $cmdline->writeFileWithConfirm($path, 'testing');
  ok( -e $path, 'writeFileWithConfirm - new file');
  ok( checkFile( $path, 'testing' ), 'file written correctly' );
  $cmdline->blank();
  $cmdline->say('Before proceeding, please answer Y to confirm overwrite of the file:');
  $cmdline->writeFileWithConfirm($path, 'testing2');
  ok( checkFile( $path, 'testing2' ), 'file overwritten correctly' );
  unlink $path;
}
else {
  print "For a full test, please run with $0 --manual\n";
}

sub checkFile {
  my ($path, $content) = @_;
  local $/ = undef;
  open FH, '<'.$path;
  my $fileContent = <FH>;
  close FH;
  return $fileContent eq $content;
}
