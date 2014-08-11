# Rank modules based on the sum of the severity of the Perl::Critic violations and the size of the file

use strict;

my @dirs = ("$ENV{O2ROOT}/lib/O2");

use Perl::Critic;
my $critic = Perl::Critic->new( -severity => 1 );

require O2::File;
my $fileMgr = O2::File->new();

my @results;

foreach my $dir (@dirs) {
  my @files = $fileMgr->find($dir, '[.]pm$');
  foreach my $file (@files) {
    next if -s $file < 10;
    my @violations = $critic->critique($file);
    my $totalSeverity = 0;
    my $fileSize = $fileMgr->getFileSize($file);
    foreach my $violation (@violations) {
      $totalSeverity += $violation->severity();
    }
    my $rating = $totalSeverity ? $fileSize / $totalSeverity : 999_999;
    push @results, {
      fileName      => $file,
      totalSeverity => $totalSeverity,
      numViolations => scalar @violations,
      fileSize      => $fileSize,
      rating        => $rating,
    };
  }
}

@results = reverse sort { $a->{rating} <=> $b->{rating} || $a->{fileSize} <=> $b->{fileSize} } @results;
foreach my $result (@results) {
  my $rating = $result->{rating} == 999_999 ? 'No violations!' : $result->{rating};
  if ($rating ne 'No violations!') {
    $rating  = sprintf '%d', $rating;
    $rating  = (' ' x (13 - length($rating))) . $rating;
  }
  my $fileName = $result->{fileName};
  $fileName    =~ s{ $ENV{O2ROOT}/lib/ }{}xms;
  $fileName    =~ s{ / }{::}xmsg;
  print "$rating\t$fileName ($result->{numViolations}, $result->{totalSeverity}, $result->{fileSize} B)\n";
}

1;
