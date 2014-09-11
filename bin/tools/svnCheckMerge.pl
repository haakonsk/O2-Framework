use strict;

use O2::Context;
my $context = O2::Context->new();

use O2::Util::List qw(upush);

use Term::ANSIColor;

use O2::Util::Args::Simple;
my $commitRepo = $ARGV{commitRepo};
my $mergeRepo  = $ARGV{mergeRepo};
my ($fromRev, $toRev) = split /:/, $ARGV{r};

if (!$commitRepo || !$mergeRepo || !$ARGV{r}) {
  my $configFilePath = "$ENV{HOME}/.svnCheckMerge";
  if (-f $configFilePath) {
    my $plds = do $configFilePath;
    if (my $options = $plds->{ $ARGV[0] }) {
      $commitRepo ||= $options->{commitRepo};
      $mergeRepo  ||= $options->{mergeRepo};
      ($fromRev, $toRev) = split /:/, $options->{r} unless $ARGV{r};
    }
  }
}

print color 'white';
die "Need -commitRepo and -mergeRepo" if !$commitRepo || !$mergeRepo;

$fromRev ||= 0;
$toRev   ||= 'head';

print "\n  $commitRepo -> $mergeRepo ($fromRev:$toRev)\n\n";

my %missingRevisions;

# If commitRepo merges from another repo, and then the commitRepo revision and the revisions it merges are "equivalent", so
# if the commitRepo revision exists in mergeRepo or the revisions it merges are merged to mergeRepo, they're not missing.
my %sameRevision;

my %files; # Keeps track of in which revisions the files were changed (key: file path, value: array of revisions)

my $svnLog = `svn log -v $commitRepo -r $fromRev:$toRev`;
my @commits = split /------------------------------------------------------------------------\n/, $svnLog;
foreach my $commit (@commits) {
  next unless $commit;

  my ($revision, $committer, $date, $changedFiles, $comment) = $commit =~ m{ \A r (\d+) \s+ \| \s+ (\w+) \s+ \| \s+ (\S+) .+? (?: Changed[ ]paths | Endrede[ ]filstier): \s+ (.+?) \n\n (.+) \z }xms;
  next unless checkUser($committer);

  my @files = split /\n/, $changedFiles;
  @files    = map { my ($filePath) = $_ =~ m{ [ ] (/.+) }xms; $filePath; } @files;
  my $commitInfo = {
    comment  => $comment,
    username => $committer,
    date     => $date,
    files    => \@files,
  };
  foreach my $file (@files) {
    $files{$file} = [] unless $files{$file};
    push @{ $files{$file} }, $revision;
  }
  if ($comment =~ m{ Revert }xmsi) { # Reverted commits don't need to be merged
    my @revisions = findRevisions($comment);
    foreach my $rev (@revisions) {
      delete $missingRevisions{$rev};
    }
  }
  elsif ($comment =~ m{ Merg (?: e | ing ) }xmsi) {
    my @revisions = findRevisions($comment);
    $missingRevisions{$revision} = $commitInfo;
    foreach my $rev (@revisions) {
      $sameRevision{$rev} = $revision;
    }
  }
  else {
    $missingRevisions{$revision} = $commitInfo;
  }
}

$svnLog = `svn log -v $mergeRepo -r head:$fromRev`;
my @commits = split /------------------------------------------------------------------------\n/, $svnLog;
foreach my $commit (@commits) {
  next unless $commit;

  my ($revision, $committer, $comment) = $commit =~ m{ \A r (\d+) \s+ \| \s+ (\w+) .+ \n\n (.+) \z }xms;
  $comment =~ s{ \s+ \z }{}xms;
  if ($comment =~ m{ Merg (?: e | ing ) }xmsi) {
    my @revisions = findRevisions($comment) or warn "r$revision seems to be merging, but doesn't say what ($comment)";
    foreach my $rev (@revisions) {
      delete $missingRevisions{$rev};
      delete $missingRevisions{ $sameRevision{$rev} } if $sameRevision{$rev};
    }
  }
  else {
    delete $missingRevisions{ $sameRevision{$revision} } if $sameRevision{$revision};
  }
}

my $maxUsernameLength = 0;
foreach my $commitInfo (values %missingRevisions) {
  my $length = length $commitInfo->{username};
  $maxUsernameLength = $length if $length > $maxUsernameLength;
}
foreach my $rev (sort keys %missingRevisions) {
  my $commitInfo = $missingRevisions{$rev};
  my $comment    = $commitInfo->{comment};
  $comment       =~ s{ \s+ \z }{}xms;
  my $possiblyConflictingRevisions;
  foreach my $file (@{ $commitInfo->{files} }) {
    foreach my $fileRev (@{ $files{$file} }) {
      upush @{ $possiblyConflictingRevisions->{$file} }, $fileRev if $fileRev < $rev && $missingRevisions{$fileRev};
    }
  }
  my $output;
  $output  = "" if $possiblyConflictingRevisions;
  $output .= sprintf "%8d ($commitInfo->{date}) ", $rev;
  $output .= sprintf "%-${maxUsernameLength}s - ", $commitInfo->{username} unless $ARGV{user};
  $output .= sprintf "($commitInfo->{date}) ",                                 if $ARGV{user};
  $output .= $comment;
  $output .= "\n";
  print color 'red' if $possiblyConflictingRevisions;
  print $output;
  print color 'yellow' if $possiblyConflictingRevisions;
  while (my ($file, $revisions) = each %{$possiblyConflictingRevisions}) {
    $file =~ s{ / [^/]+ / }{}xms;
    printf "        $file (%s)\n", join ', ', @{$revisions};
  }
  print color 'white';
}
print color 'reset';

sub checkUser {
  my ($committer) = @_;
  return 1 unless $ARGV{user};
  return $committer eq $ARGV{user};
}

sub findRevisions {
  my ($comment) = @_;

  my @revisions;

  my ($revisionsStr) = $comment =~ m{ ( [rc] \d+  (?: [rc] | \d | \s | , | and | - )+ ) }xms;
  chomp $revisionsStr;
  my @matches = $revisionsStr =~ m{ ( (?: (?:[\S] | ) - )? [rc]? \d+)  }xmsg;
  my $prevMatch;
  foreach my $match (@matches) {
    $match =~ s{ [rc] }{}xms;
    if ($match =~ m{ \A - }xms) {
      $match =~ s{ \A - }{}xms;
      upush @revisions, ($prevMatch .. $match);
    }
    else {
      $match =~ s{ .* - }{}xms;
      push @revisions, $match;
      $prevMatch = $match;
    }
  }
  return @revisions;
}
