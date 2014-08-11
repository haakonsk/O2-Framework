#!/usr/bin/perl -w

# ====================================================================
# Based on /usr/share/subversion/hook-scripts/commit-email.pl.
# ====================================================================

# ====================================================================
# commit-email.pl: send a notification email describing either a
# commit or a revprop-change action on a Subversion repository.
#
# For usage, see the usage subroutine or run the script with no
# command line arguments.
#
# This script requires Subversion 1.2.0 or later.
#
# $HeadURL: http://svn.collab.net/repos/svn/branches/1.4.x/tools/hook-scripts/commit-email.pl.in $
# $LastChangedDate: 2006-04-19 23:08:55 +0000 (Wed, 19 Apr 2006) $
# $LastChangedBy: maxb $
# $LastChangedRevision: 19424 $
#
# ====================================================================
# Copyright (c) 2000-2006 CollabNet.  All rights reserved.
#
# This software is licensed as described in the file COPYING, which
# you should have received as part of this distribution.  The terms
# are also available at http://subversion.tigris.org/license-1.html.
# If newer versions of this license are posted there, you may use a
# newer version instead, at your option.
#
# This software consists of voluntary contributions made by many
# individuals.  For exact contribution history, see the revision
# history and logs, available at http://subversion.tigris.org/.
# ====================================================================

# Turn on warnings the best way depending on the Perl version.
#--------------------------------------------------------------------------------------------------
BEGIN {
  if ( $] >= 5.006_000) {
    require warnings;
    import warnings;
  }
  else {
    $^W = 1;
  }
}
#--------------------------------------------------------------------------------------------------
use strict;
use Carp;

my ($sendmail, $smtp_server);
#--------------------------------------------------------------------------------------------------
# Configuration section.

# Sendmail path, or SMTP server address.
# You should define exactly one of these two configuration variables,
# leaving the other commented out, to select which method of sending
# email should be used.
#$sendmail = "/usr/sbin/sendmail";
$smtp_server = "127.0.0.1";

# Svnlook path.
my $svnlook = "/usr/bin/svnlook";

# By default, when a file is deleted from the repository, svnlook diff
# prints the entire contents of the file.  If you want to save space
# in the log and email messages by not printing the file, then set
# $no_diff_deleted to 1.
my $no_diff_deleted = 1;

# By default, when a file is added to the repository, svnlook diff
# prints the entire contents of the file.  If you want to save space
# in the log and email messages by not printing the file, then set
# $no_diff_added to 1.
my $no_diff_added = 0;

# COLORS
my %themes;
$themes{default} = {
  bodyStyle                => '',
  headerBlockStyle         => 'background-color:#396498;color:#fff;border:solid 1px #000;padding:5px;margin:-5px;margin-bottom:10px;',
  headerBlockElementStyle  => '',
  fileBlockStyle           => '',
  fileBlockListStyle       => '',
  logBlockStyle            => "font-size:14px;font-family:lucida console,monospace;color:#000;background-color:#FEFFCE;border:solid 1px #FCCE27;padding:5px;margin:5px 0px;",
  diffBlockStyle           => 'font-size:14px;font-family:lucida console,monospace;color:#000;background-color:#EEEEEE;border:solid 1px #CCCCCC;padding:5px;margin:5px 0px;white-space:pre;',
  criticBlockStyle         => 'font-size:14px;font-family:lucida console,monospace;color:#fff;background-color:#574761;border:solid 1px;padding:5px;margin:5px 0px;white-space:pre;',
  highlightNegativeStyle   => 'background-color:#FEDDDD;color:#111111;padding:3px;',
  highlightPositiveStyle   => 'background-color:#DDFFDE;color:#111111;padding:3px;',
  highlightNeutralStyle    => '',
  highlightSVNStyle        => 'background-color:#545454;color:#fff;padding:3px;margin:1px 0px;',
  highlightFileStyle       => 'background-color:#396498;color:#fff;padding:10px;margin:-5px;margin-bottom:10px;',
  highlightCriticSeverity1 => 'color:#f63;',
  highlightCriticSeverity2 => 'color:#f53;',
  highlightCriticSeverity3 => 'color:#d22;',
  highlightCriticSeverity4 => 'color:#f00;',
  highlightCriticSeverity5 => 'color:#d00;font-weight:bold;',
};
$themes{dark} = {
  bodyStyle                => 'background-color:#000;color:#ddd;',
  headerBlockStyle         => 'font-family:Courier New,monospace;background-color:#222;color:#48a;border:solid 1px #ddd;padding:5px;margin-bottom:10px;white-space:pre;',
  headerBlockElementStyle  => '',
  fileBlockStyle           => 'margin-bottom:15px;',
  fileBlockListStyle       => 'margin:0;',
  logBlockStyle            => "font-size:14px;font-family:lucida console,monospace;color:#000;background-color:#666;border:solid 1px #ddd;padding:20px 5px 5px 5px;margin:5px 0px;white-space:pre;",
  diffBlockStyle           => 'font-size:14px;font-family:lucida console,monospace;color:#777;background-color:#111;border:solid 1px #ddd;white-space:pre;',
  criticBlockStyle         => 'font-size:14px;font-family:lucida console,monospace;color:#888;background-color:#333;border:solid 1px #ddd;padding:5px;margin:5px 0px;white-space:pre;',
  highlightNegativeStyle   => 'background-color:#222;color:#c44;padding:0 2px;',
  highlightPositiveStyle   => 'background-color:#222;color:#4b4;padding:0 2px;',
  highlightNeutralStyle    => '',
  highlightSVNStyle        => 'background-color:#333;padding:2px;margin:1px 0px;',
  highlightFileStyle       => 'background-color:#000;color:#ddd;padding:10px;',
  highlightCriticSeverity1 => $themes{default}->{highlightCriticSeverity1},
  highlightCriticSeverity2 => $themes{default}->{highlightCriticSeverity2},
  highlightCriticSeverity3 => $themes{default}->{highlightCriticSeverity3},
  highlightCriticSeverity4 => $themes{default}->{highlightCriticSeverity4},
  highlightCriticSeverity5 => $themes{default}->{highlightCriticSeverity5},
};
$themes{gunde} = {
  bodyStyle                   => 'background-color:#0A2A18;color:#C4FF29;font-size:14px;font-family:lucida console,monospace;',
  headerBlockStyle            => 'white-space:pre;color:#FFF504;background-color:#121803;border:solid 1px #243006;padding:5px;margin:10px 0px;',
  headerBlockElementStyle     => 'color:#F3FF98',
  fileBlockStyle              => 'background-color:#121803;border:solid 1px #243006;padding:5px;',
  fileBlockListStyle          => 'color:#3897B5;list-style-position: inside;list-style: none;padding:0px;margin:0px;margin-top:5px;',
  logBlockStyle               => 'background-color:#3897B5;font-size:120%;color:#C8F2FF;padding:5px;margin:10px 0px;',
  diffBlockStyle              => 'background-color:#121803;color:#5F5F5F;border:solid 1px #243006;margin:5px 0px;white-space:pre;padding:5px;line-height:1.1;',
  criticBlockStyle            => 'background-color:#121803;color:#5F5F5F;border:solid 1px #243006;margin:5px 0px;white-space:pre;padding:5px;line-height:1.1;',
  highlightSuperNegativeStyle => 'background-color:#0E1302;color:#799617;',
  highlightSuperPositiveStyle => 'background-color:#0E1302;color:#C9F92C;',
  highlightNegativeStyle      => 'background-color:#0E1302;color:#FF6F31;',
  highlightPositiveStyle      => 'background-color:#0E1302;color:#9EFF3F;',
  highlightNeutralStyle       => 'color:#5F5F5F;',
  highlightSVNStyle           => 'background-color:#121803;color:#5F5F5F;',
  highlightFileStyle          => 'background-color:#121803;color:#F3FF5E;',
  highlightCriticSeverity1    => $themes{default}->{highlightCriticSeverity1},
  highlightCriticSeverity2    => $themes{default}->{highlightCriticSeverity2},
  highlightCriticSeverity3    => $themes{default}->{highlightCriticSeverity3},
  highlightCriticSeverity4    => $themes{default}->{highlightCriticSeverity4},
  highlightCriticSeverity5    => $themes{default}->{highlightCriticSeverity5},
};
$themes{svan} = {
  bodyStyle                => 'background-color:#363636;color:#ededeb;font-size:14px;font-family:panic sans,lucida console,monospace;',
  headerBlockStyle         => 'color:#fbb0b0; margin:20px 0;',
  headerBlockElementStyle  => '',
  fileBlockStyle           => '',
  fileBlockListStyle       => '',
  logBlockStyle            => 'background-color:#222;padding:15px 10px;margin:20px 0;',
  diffBlockStyle           => 'background-color:#464646;color:#cccccc;margin:5px 0;white-space:pre;',
  criticBlockStyle         => 'color:#fff;background-color:#574761;margin:5px 0px;white-space:pre;',
  highlightNegativeStyle   => 'background-color:#2e2e2e;color:#ee7272;padding:3px;',
  highlightPositiveStyle   => 'background-color:#2e2e2e;color:#9ad875;padding:3px;',
  highlightNeutralStyle    => '',
  highlightSVNStyle        => 'background-color:#2e2e2e;color:#ffffff;padding:3px;',
  highlightFileStyle       => 'background-color:#009bc5;color:#ffffff;padding:10px;margin:10px 0 0;',  
  highlightCriticSeverity1 => $themes{default}->{highlightCriticSeverity1},
  highlightCriticSeverity2 => $themes{default}->{highlightCriticSeverity2},
  highlightCriticSeverity3 => $themes{default}->{highlightCriticSeverity3},
  highlightCriticSeverity4 => $themes{default}->{highlightCriticSeverity4},
  highlightCriticSeverity5 => $themes{default}->{highlightCriticSeverity5},
};
$themes{rick} = {
  bodyStyle                => 'background-color:#00100B;color:#02EE71;font-size:14px;font-family:lucida console,monospace;',
  headerBlockStyle         => 'background-color:#002525;border:solid 1px #061957;padding:5px;margin:10px 0px;',
  headerBlockElementStyle  => '',
  fileBlockStyle           => '',
  logBlockStyle            => 'background-color:#002525;border:solid 1px #061957;padding:5px;margin:10px 0px;',
  diffBlockStyle           => 'background-color:#002525;color:#0094C5;border:solid 1px #061957;margin:5px 0px;white-space:pre;',
  criticBlockStyle         => 'background-color:#002525;color:#0094C5;border:solid 1px #061957;margin:5px 0px;white-space:pre;',
  highlightNegativeStyle   => 'background-color:#00141B;color:#FF0C28;padding:3px;',
  highlightPositiveStyle   => 'background-color:#00141B;color:#0AD300;padding:3px;',
  highlightSVNStyle        => 'background-color:#002525;color:#0094C5;padding:6px;margin:-3px 0px;margin-bottom:3px;',
  highlightFileStyle       => 'background-color:#002525;color:#0AD300;padding:5px;margin:10px 0px;',
  highlightCriticSeverity1 => $themes{default}->{highlightCriticSeverity1},
  highlightCriticSeverity2 => $themes{default}->{highlightCriticSeverity2},
  highlightCriticSeverity3 => $themes{default}->{highlightCriticSeverity3},
  highlightCriticSeverity4 => $themes{default}->{highlightCriticSeverity4},
  highlightCriticSeverity5 => $themes{default}->{highlightCriticSeverity5},
};

$themes{haakonsk} = $themes{dark};
$themes{fmortens} = $themes{gunde};
$themes{vibeke}   = $themes{svan};
$themes{geirmw}   = $themes{rick};

# End of Configuration section.

#--------------------------------------------------------------------------------------------------
# Check that the required programs exist, and the email sending method
# configuration is sane, to ensure that the administrator has set up
# the script properly.
{
  my $ok = 1;
  foreach my $program ($sendmail, $svnlook) {
    next if not defined $program;
    
    if (-e $program) {
      unless (-x $program) {
        warn "$0: required program `$program' is not executable, ",
             "edit $0.\n";
        $ok = 0;
      }
    }
    else {
      warn "$0: required program `$program' does not exist, edit $0.\n";
      $ok = 0;
    }
  }
  
  if (not (defined $sendmail xor defined $smtp_server)) {
    warn "$0: exactly one of \$sendmail or \$smtp_server must be ",
         "set, edit $0.\n";
    $ok = 0;
  }
  
  exit 1 unless $ok;
}

require Net::SMTP if defined $smtp_server;

#--------------------------------------------------------------------------------------------------
# Initial setup/command-line handling.

# Each value in this array holds a hash reference which contains the
# associated email information for one project.  Start with an
# implicit rule that matches all paths.
my @project_settings_list = (&new_project);

# Process the command line arguments till there are none left.
# In commit mode: The first two arguments that are not used by a command line
# option are the repository path and the revision number.
# In revprop-change mode: The first four arguments that are not used by a
# command line option are the repository path, the revision number, the
# author, and the property name. This script has no support for the fifth
# argument (action) added to the post-revprop-change hook in Subversion
# 1.2.0 yet - patches welcome!
my $repos;
my $rev;
my $author;
my $propname;

my $mode = 'commit';
my $diff_file;

# Use the reference to the first project to populate.
my $current_project = $project_settings_list[0];

# This hash matches the command line option to the hash key in the
# project.  If a key exists but has a false value (''), then the
# command line option is allowed but requires special handling.
my %opt_to_hash_key = (
  '--from'           => 'from_address',
  '--revprop-change' => '',
  '-d'               => '',
  '-h'               => 'hostname',
  '-l'               => 'log_file',
  '-m'               => '',
  '-r'               => 'reply_to',
  '-s'               => 'subject_prefix',
  '--diff'           => '',
  '--customerRoot'   => 'customerRoot', # Only works for one "project"
);

while (@ARGV) {
  my $arg = shift @ARGV;
  if ($arg =~ /^-/) {
    my $hash_key = $opt_to_hash_key{$arg};
    unless (defined $hash_key) {
      die "$0: command line option `$arg' is not recognized.\n";
    }
    
    my $value;
    if ($arg ne '--revprop-change') {
      
      unless (@ARGV) {
        die "$0: command line option `$arg' is missing a value.\n";
      }
      
      $value = shift @ARGV;
    }
    
    if ($hash_key) {
      $current_project->{$hash_key} = $value;
    }
    else {
      if ($arg eq '-m') {
        $current_project                = &new_project;
        $current_project->{match_regex} = $value;
        push(@project_settings_list, $current_project);
      }
      elsif ($arg eq '-d') {
        if ($mode ne 'revprop-change') {
          die "$0: `-d' is valid only when used after"
          . " `--revprop-change'.\n";
        }
        if ($diff_file) {
          die "$0: command line option `$arg'"
          . " can only be used once.\n";
        }
        $diff_file = $value;
      }
      elsif ($arg eq '--revprop-change') {
        if (defined $repos) {
          die "$0: `--revprop-change' must be specified before"
          . " the first non-option argument.\n";
        }
        $mode = 'revprop-change';
      }
      elsif ($arg eq '--diff') {
        $current_project->{show_diff} = parse_boolean($value);
      }
      else {
        die "$0: internal error:"
        . " should not be handling `$arg' here.\n";
      }
    }
  }
  else {
    if (! defined $repos) {
      $repos = $arg;
    }
    elsif (! defined $rev) {
      $rev = $arg;
    }
    elsif (! defined $author && $mode eq 'revprop-change') {
      $author = $arg;
    }
    elsif (! defined $propname && $mode eq 'revprop-change') {
      $propname = $arg;
    }
    else {
      push(@{$current_project->{email_addresses}}, $arg);
    }
  }
}
#--------------------------------------------------------------------------------------------------
if ($mode eq 'commit') {
  &usage("$0: too few arguments.") unless defined $rev;
}
elsif ($mode eq 'revprop-change') {
  &usage("$0: too few arguments.") unless defined $propname;
}
#--------------------------------------------------------------------------------------------------
# Check the validity of the command line arguments.  Check that the
# revision is an integer greater than 0 and that the repository
# directory exists.
unless ($rev =~ /^\d+/ and $rev > 0) {
  &usage("$0: revision number `$rev' must be an integer > 0.");
}

unless (-e $repos) {
  &usage("$0: repos directory `$repos' does not exist.");
}

unless (-d _) {
  &usage("$0: repos directory `$repos' is not a directory.");
}
#--------------------------------------------------------------------------------------------------
# Check that all of the regular expressions can be compiled and
# compile them.
{
  my $ok = 1;
  for (my $i = 0; $i < @project_settings_list; ++$i) {
    my $match_regex = $project_settings_list[$i]->{match_regex};
    
    # To help users that automatically write regular expressions
    # that match the root directory using ^/, remove the / character
    # because subversion paths, while they start at the root level,
    # do not begin with a /.
    $match_regex =~ s#^\^/#^#;
    
    my $match_re;
    eval { $match_re = qr/$match_regex/ };
    if ($@) {
      warn "$0: -m regex #$i `$match_regex' does not compile:\n$@\n";
      $ok = 0;
      next;
    }
    $project_settings_list[$i]->{match_re} = $match_re;
  }
  exit 1 unless $ok;
}
#--------------------------------------------------------------------------------------------------
# Harvest common data needed for both commit or revprop-change.

# Figure out what directories have changed using svnlook.
my @dirschanged = &read_from_process($svnlook, 'dirs-changed', $repos, '-r', $rev);

# Lose the trailing slash in the directory names if one exists, except
# in the case of '/'.
my $rootchanged = 0;
for (my $i=0; $i<@dirschanged; ++$i) {
  if ($dirschanged[$i] eq '/') {
    $rootchanged = 1;
  }
  else {
    $dirschanged[$i] =~ s#^(.+)[/\\]$#$1#;
  }
}
#--------------------------------------------------------------------------------------------------
# Figure out what files have changed using svnlook.
my @svnlooklines = &read_from_process($svnlook, 'changed', $repos, '-r', $rev);
#--------------------------------------------------------------------------------------------------
# Parse the changed nodes.
my @adds;
my @dels;
my @mods;
foreach my $line (@svnlooklines) {
  my $path = '';
  my $code = '';
  
  # Split the line up into the modification code and path, ignoring
  # property modifications.
  if ($line =~ /^(.).  (.*)$/) {
    $code = $1;
    $path = $2;
  }
  
  if ($code eq 'A') {
    push(@adds, $path);
  }
  elsif ($code eq 'D') {
    push(@dels, $path);
  }
  else {
    push(@mods, $path);
  }
}
#--------------------------------------------------------------------------------------------------
# Declare variables which carry information out of the inner scope of
# the conditional blocks below.
my $subject_base;
my @body;
my $lastPartOfBody;
# $author - declared above for use as a command line parameter in
#   revprop-change mode.  In commit mode, gets filled in below.

if ($mode eq 'commit') {
  ######################################################################
  # Harvest data using svnlook.
  
  # Get the author, date, and log from svnlook.
  my @infolines = &read_from_process($svnlook, 'info', $repos, '-r', $rev);
  $author  = shift @infolines;
  my $date = shift @infolines;
  shift @infolines;
  
  my $theme = $themes{$author} || $themes{default};

  my @log = map { "$_\n" } @infolines;
  @log     = map { $_ =~ s/s\b/z/g; $_ } @log       if $author eq 'vibeke' && @log && 0.2 > rand;
  $log[-1] =~ s{ ([^.!])   (\s*) \z }{$1, LOL$2}xms if $author eq 'vibeke' && @log && 0.2 > rand;
  $log[-1] = uc $log[-1]                            if $author eq 'vibeke' && @log && 0.2 > rand;
  $log[-1] = join '', reverse split //, $log[-1]    if $author eq 'vibeke' && @log && 0.2 > rand;
  
  ######################################################################
  # Modified directory name collapsing.
  
  # Collapse the list of changed directories only if the root directory
  # was not modified, because otherwise everything is under root and
  # there's no point in collapsing the directories, and only if more
  # than one directory was modified.
  my $commondir = '';
  my @edited_dirschanged = @dirschanged;
  if (!$rootchanged and @edited_dirschanged > 1) {
    my $firstline    = shift @edited_dirschanged;
    my @commonpieces = split('/', $firstline);
    foreach my $line (@edited_dirschanged) {
      my @pieces = split('/', $line);
      my $i = 0;
      while ($i < @pieces and $i < @commonpieces) {
        if ($pieces[$i] ne $commonpieces[$i]) {
          splice(@commonpieces, $i, @commonpieces - $i);
          last;
        }
        $i++;
      }
    }
    unshift(@edited_dirschanged, $firstline);
    
    if (@commonpieces) {
      $commondir = join('/', @commonpieces);
      my @new_dirschanged;
      foreach my $dir (@edited_dirschanged) {
        if ($dir eq $commondir) {
          $dir = '.';
        }
        else {
          $dir =~ s#^\Q$commondir/\E##;
        }
        push(@new_dirschanged, $dir);
      }
      @edited_dirschanged = @new_dirschanged;
    }
  }
  
  my $dirlist = join(' ', @edited_dirschanged);
  
  ######################################################################
  # Assembly of log message.
  
  my $firstLogLine = $log[0];
  $firstLogLine =~ s/\n//g;
  
  if ($commondir ne '') {
    $subject_base = "r$rev - in $commondir : $firstLogLine";
  }
  else {
    $subject_base = "r$rev : $firstLogLine";
  }
  
  # Now that we have extracted subject from @log, we can encode html entities in @log:
  @log = map { $_ =~ s/</&lt;/g; $_ } @log;
  @log = map { $_ =~ s/>/&gt;/g; $_ } @log;
  
  # Put together the body of the log message.
  push(@body, '<div style="'.$theme->{headerBlockStyle}.'">');
  push(@body, 'Revision : <span style="'.$theme->{headerBlockElementStyle}.'">'.$rev."</span>\n");
  push(@body, 'Author   : <span style="'.$theme->{headerBlockElementStyle}.'">'.$author."</span>\n");
  push(@body, 'Date     : <span style="'.$theme->{headerBlockElementStyle}.'">'.$date."</span>\n");
  push(@body, "</div>\n");
  
  # Start of block listing affected file paths
  push(@body, '<div style="'.$theme->{fileBlockStyle}.'">');
  
  if (@adds) {
    @adds = sort @adds;
    push(@body, "Files added:<br>\n".'<ul style="'.$theme->{fileBlockListStyle}.'">');
    push(@body, map { "<li>$_</li>\n" } @adds);
    push(@body, '</ul>');
  }
  
  if (@dels) {
    @dels = sort @dels;
    push(@body, "Files removed:<br>\n".'<ul style="'.$theme->{fileBlockListStyle}.'">');
    push(@body, map { "<li>$_</li>\n" } @dels);
    push(@body, '</ul>');
  }
  
  if (@mods) {
    @mods = sort @mods;
    push(@body, "<br>\nModified:<br>\n".'<ul style="'.$theme->{fileBlockListStyle}.'">');
    push(@body, map { "<li>$_</li>\n" } @mods);
    push(@body, '</ul>');
  }
  
  # End of block
  push(@body, "</div>\n");
  
  # Start of log block
  push(@body, '<div style="'.$theme->{logBlockStyle}.'">');
  push(@body, '<div style="white-space:pre">');
  push(@body, @log);
  push(@body, '</div></div>');
  # end of log block
  
  die 'O2ROOT environment variable missing' unless $ENV{O2ROOT};
  my $root = $current_project->{customerRoot};
  $ENV{PERL5LIB} ||= "$ENV{O2ROOT}/lib";
  
  my @changedFiles = (@adds, @mods);
  @changedFiles    = grep { $_ =~ m{ [.] (?: pm | html )  \z }xms } @changedFiles; # Only files with .pm extension.
  
  if (scalar(@changedFiles) > 0) {
    $lastPartOfBody  = "Running Perl::Critic on changed .pm files and O2::Template::Critic on changed .html files:\n\n";
    
    # Create temporary files:
    my @files;
    foreach my $filename (@changedFiles) {
      if (!-e "$root/svnHookTmp") {
        mkdir "$root/svnHookTmp", 0755;
      }
      
      my @fileContent = &read_from_process($svnlook, 'cat', $repos, '-r', $rev, $filename);
      my $fileContent = join("\n", @fileContent);
      $filename =~ s{ / }{_l_}xmsg;
      
      open my $fh, '>', "$root/svnHookTmp/$filename";
      print {$fh} $fileContent;
      close $fh;
      
      push @files, $filename;
    }
    
    my $files = "$root/svnHookTmp/" . join(" $root/svnHookTmp/", @files);
    $lastPartOfBody .= qx{perl $ENV{O2ROOT}/bin/tools/critic/checkCodingConventions.pl -files $files 2>&1} . "\n";
    $lastPartOfBody =~ s/>/&gt;/g;
    $lastPartOfBody =~ s/</&lt;/g;
    my $victoryBaby  = $lastPartOfBody !~ m{ ^ not \s ok }xms  &&  $lastPartOfBody =~ m{ ^ ok \s }xms;
    my $disasterGirl = $lastPartOfBody =~ m{ ^ not \s ok }xms  &&  $lastPartOfBody !~ m{ ^ ok \s }xms;
    
    # Try to colorize the perl critic
    my @lastPartOfBodyLines = split("\n", $lastPartOfBody);
    @lastPartOfBodyLines = map { /^ok/              ? '<div  style="'.$theme->{  highlightPositiveStyle     }.'">'.$_.'</div>'  : $_ } @lastPartOfBodyLines;
    @lastPartOfBodyLines = map { /^not\ ok/         ? '<div  style="'.$theme->{  highlightNegativeStyle     }.'">'.$_.'</div>'  : $_ } @lastPartOfBodyLines;
    @lastPartOfBodyLines = map { /Severity:?\s(\d)/ ? '<span style="'.$theme->{ "highlightCriticSeverity$1" }.'">'.$_.'</span>' : $_ } @lastPartOfBodyLines;
    my $maxSeverity = 0;
    foreach my $line (@lastPartOfBodyLines) {
      my ($severity) = $line =~ m{ Severity :? \s (\d) }xms;
      $maxSeverity = $severity if $severity > $maxSeverity;
    }
    $lastPartOfBody  = join("\n", @lastPartOfBodyLines);
    $lastPartOfBody .= "<p><img src='http://cdn.memegenerator.net/instances/400x/27864379.jpg'></p>" if $victoryBaby;
    $lastPartOfBody .= "<p><img src='http://i1.kym-cdn.com/entries/icons/original/000/000/043/disaster-girl.jpg'></p>" if $disasterGirl;
    $lastPartOfBody .= "<p>Max severity: $maxSeverity</p>" if $maxSeverity >= 1;
    
    foreach my $filename (@files) {
      unlink "$root/svnHookTmp/$filename";
    }
  }
}
elsif ($mode eq 'revprop-change') {
  ######################################################################
  # Harvest data.
  my @svnlines;
  
  # Get the diff file if it was provided, otherwise the property value.
  if ($diff_file) {
    open(DIFF_FILE, $diff_file) or die "$0: cannot read `$diff_file': $!\n";
    @svnlines = <DIFF_FILE>;
    close DIFF_FILE;
  }
  else {
    @svnlines = &read_from_process(
      $svnlook, 'propget', '--revprop', '-r',
      $rev, $repos, $propname
    );
  }
  ######################################################################
  # Assembly of log message.
  $subject_base = "propchange - r$rev $propname";
  
  # Put together the body of the log message.
  push(@body, "Author: $author\n");
  push(@body, "Revision: $rev\n");
  push(@body, "Property Name: $propname\n");
  push(@body, "\n");
  
  unless ($diff_file) {
    push(@body, "New Property Value:\n");
  }
  
  push(@body, map { /[\r\n]+$/ ? $_ : "$_\n" } @svnlines);
}
#--------------------------------------------------------------------------------------------------
# Cached information - calculated when first needed.
my @difflines;

my $theme = $themes{$author} || $themes{default};

# Go through each project and see if there are any matches for this project.
# If so, send the log out.
foreach my $project (@project_settings_list) {
  my $match_re = $project->{match_re};
  my $match    = 0;
  foreach my $path (@dirschanged, @adds, @dels, @mods) {
    if ($path =~ $match_re) {
      $match = 1;
      last;
    }
  }
  
  next unless $match;
  
  my @email_addresses = @{$project->{email_addresses}};
  my $userlist        = join(' ', @email_addresses);
  my $to              = join(', ', @email_addresses);
  my $from_address    = $project->{from_address};
  my $hostname        = $project->{hostname};
  my $log_file        = $project->{log_file};
  my $reply_to        = $project->{reply_to};
  my $subject_prefix  = $project->{subject_prefix};
  my $subject         = $subject_base;
  my $diff_wanted     = ($project->{show_diff} and $mode eq 'commit');
  
  if ($subject_prefix =~ /\w/) {
    $subject = "$subject_prefix $subject";
  }
  my $mail_from = $author;
  
  if ($from_address =~ /\w/) {
    $mail_from = $from_address;
  }
  elsif ($hostname =~ /\w/) {
    $mail_from = "$mail_from\@$hostname";
  }
  elsif (defined $smtp_server) {
    die "$0: use of either `-h' or `--from' is mandatory when ",
        "sending email using direct SMTP.\n";
  }
  
  my @head;
  push(@head, "To: $to\n");
  push(@head, "From: $mail_from\n");
  push(@head, "Subject: $subject\n");
  push(@head, "Reply-to: $reply_to\n") if $reply_to;
  
  ### Below, we set the content-type etc, but see these comments
  ### from Greg Stein on why this is not a full solution.
  #
  # From: Greg Stein <gstein@lyra.org>
  # Subject: Re: svn commit: rev 2599 - trunk/tools/cgi
  # To: dev@subversion.tigris.org
  # Date: Fri, 19 Jul 2002 23:42:32 -0700
  #
  # Well... that isn't strictly true. The contents of the files
  # might not be UTF-8, so the "diff" portion will be hosed.
  #
  # If you want a truly "proper" commit message, then you'd use
  # multipart MIME messages, with each file going into its own part,
  # and labeled with an appropriate MIME type and charset. Of
  # course, we haven't defined a charset property yet, but no biggy.
  #
  # Going with multipart will surely throw out the notion of "cut
  # out the patch from the email and apply." But then again: the
  # commit emailer could see that all portions are in the same
  # charset and skip the multipart thang.
  #
  # etc etc
  #
  # Basically: adding/tweaking the content-type is nice, but don't
  # think that is the proper solution.
  push(@head, "Content-Type: text/html; charset=UTF-8\n");
  push(@head, "Content-Transfer-Encoding: 8bit\n");
  push(@head, "\n");
  
  if ($diff_wanted and not @difflines) {
    # Get the diff from svnlook.
    my @no_diff_deleted = $no_diff_deleted ? ('--no-diff-deleted') : ();
    my @no_diff_added   = $no_diff_added ? ('--no-diff-added') : ();
    
    @difflines = &read_from_process(
      $svnlook, 'diff', $repos,'-r', $rev, @no_diff_deleted,@no_diff_added
    );
    @difflines = map { /[\r\n]+$/ ? $_ : "$_\n" } @difflines;
    
    # Avoid HTML inside because we are sending HTML email
    @difflines = map { $_ =~ s/</&lt;/g; $_ } @difflines;
    @difflines = map { $_ =~ s/>/&gt;/g; $_ } @difflines;
    
    # Superpositive og negative lines, not sure what to really call them
    @difflines = map { /^\+\+\+ / ? '<div style="'.$theme->{highlightSuperPositiveStyle}.'">'.$_.'</div>' : "$_" } @difflines;
    @difflines = map { /^\-\-\- / ? '<div style="'.$theme->{highlightSuperNegativeStyle}.'">'.$_.'</div>' : "$_" } @difflines;
    
    # Check if a line starts with - or + Wrap in span and use red or green
    @difflines = map { /^\+([^+]|$)/ ? '<div style="'.$theme->{highlightPositiveStyle}.'">'.$_.'</div>' : "$_" } @difflines;
    @difflines = map { /^\-([^-]|$)/ ? '<div style="'.$theme->{highlightNegativeStyle}.'">'.$_.'</div>' : "$_" } @difflines;
    
    @difflines = map { /^[^-+]/ && !/^@@/ && !/^Modified:/ ? '<div style="'.$theme->{highlightNeutralStyle}.'">'.$_.'</div>' : "$_" } @difflines;
    
    # Highlight svn structure
    @difflines = map { /^@@/ ? '<div style="'.$theme->{highlightSVNStyle}.'">'.$_.'</div>' : "$_" } @difflines;
    
    # Hightlight what file is modified
    @difflines = map { /^Modified:/ ? '<div style="'.$theme->{highlightFileStyle}.'">'.$_.'</div>' : "$_" } @difflines;
  }
  
  # Start of diff block
  push(@body,'<div style="'.$theme->{diffBlockStyle}.'">') if @difflines;

  # Wrap a div around the whole message
  unshift @body, qq{<body style="$theme->{bodyStyle}">};
  my $footer =   qq{</body>};
  
  if (defined $sendmail and @email_addresses) {
    # Open a pipe to sendmail.
    my $command = "$sendmail -f'$mail_from' $userlist";
    if (open(SENDMAIL, "| $command")) {
      
      print SENDMAIL @head, @body;
      print SENDMAIL @difflines if $diff_wanted;
      print SENDMAIL $footer;
      
      close SENDMAIL
      or warn "$0: error in closing `$command' for writing: $!\n";
    }
    else {
      warn "$0: cannot open `| $command' for writing: $!\n";
    }
  }
  elsif (defined $smtp_server and @email_addresses) {
    my $smtp = Net::SMTP->new($smtp_server);
    
    handle_smtp_error($smtp, $smtp->mail($mail_from));
    handle_smtp_error($smtp, $smtp->recipient(@email_addresses));
    handle_smtp_error($smtp, $smtp->data());
    handle_smtp_error($smtp, $smtp->datasend(@head, @body));
    
    if ($diff_wanted) {
      handle_smtp_error($smtp, $smtp->datasend(@difflines));
    }
    
    # end of diff block
    my $originalLastPartOfBody = $lastPartOfBody;
    $lastPartOfBody  = '</div>' if @difflines;
    $lastPartOfBody .= qq{<div style="$theme->{criticBlockStyle}">$originalLastPartOfBody</div>} if $originalLastPartOfBody;
    
    handle_smtp_error($smtp, $smtp->datasend($lastPartOfBody));
    handle_smtp_error($smtp, $smtp->datasend($footer));
    handle_smtp_error($smtp, $smtp->dataend());
    handle_smtp_error($smtp, $smtp->quit());
  }
  
  # Dump the output to logfile (if its name is not empty).
  if ($log_file =~ /\w/) {
    if ( open(LOGFILE, ">> $log_file") ) {
      print LOGFILE @head, @body;
      print LOGFILE @difflines if $diff_wanted;
      
      close LOGFILE
      or warn "$0: error in closing `$log_file' for appending: $!\n";
    }
    else {
      warn "$0: cannot open `$log_file' for appending: $!\n";
    }
  }
}
#--------------------------------------------------------------------------------------------------
# Finished
exit 0;
#--------------------------------------------------------------------------------------------------
sub handle_smtp_error {
  my ($smtp, $retval) = @_;
  
  if (not $retval) {
    die "$0: SMTP Error: " . $smtp->message() . "\n";
  }
}
#--------------------------------------------------------------------------------------------------
sub usage {
  warn "@_\n" if @_;
  die "usage (commit mode):\n",
      "  $0 REPOS REVNUM [[-m regex] [options] [email_addr ...]] ...\n",
      "usage: (revprop-change mode):\n",
      "  $0 --revprop-change REPOS REVNUM USER PROPNAME [-d diff_file] \\\n",
      "    [[-m regex] [options] [email_addr ...]] ...\n",
      "options are:\n",
      "  --from email_address  Email address for 'From:' (overrides -h)\n",
      "  -h hostname           Hostname to append to author for 'From:'\n",
      "  -l logfile            Append mail contents to this log file\n",
      "  -m regex              Regular expression to match committed path\n",
      "  -r email_address      Email address for 'Reply-To:'\n",
      "  -s subject_prefix     Subject line prefix\n",
      "  --diff y|n            Include diff in message (default: y)\n",
      "                        (applies to commit mode only)\n",
      "\n",
      "This script supports a single repository with multiple projects,\n",
      "where each project receives email only for actions that affect that\n",
      "project.  A project is identified by using the -m command line\n".
      "option with a regular expression argument.  If the given revision\n",
      "contains modifications to a path that matches the regular\n",
      "expression, then the action applies to the project.\n",
      "\n",
      "Any of the following -h, -l, -r, -s and --diff command line options\n",
      "and following email addresses are associated with this project.  The\n",
      "next -m resets the -h, -l, -r, -s and --diff command line options\n",
      "and the list of email addresses.\n",
      "\n",
      "To support a single project conveniently, the script initializes\n",
      "itself with an implicit -m . rule that matches any modifications\n",
      "to the repository.  Therefore, to use the script for a single-\n",
      "project repository, just use the other command line options and\n",
      "a list of email addresses on the command line.  If you do not want\n",
      "a rule that matches the entire repository, then use -m with a\n",
      "regular expression before any other command line options or email\n",
      "addresses.\n",
      "\n",
      "'revprop-change' mode:\n",
      "The message will contain a copy of the diff_file if it is provided,\n",
      "otherwise a copy of the (assumed to be new) property value.\n",
      "\n";
}
#--------------------------------------------------------------------------------------------------
# Return a new hash data structure for a new empty project that
# matches any modifications to the repository.
sub new_project {
  return {
    email_addresses => [],
    from_address    => '',
    hostname        => '',
    log_file        => '',
    match_regex     => '.',
    reply_to        => '',
    subject_prefix  => '',
    show_diff       => 1,
    customerRoot    => $ENV{O2ROOT},
  };
}
#--------------------------------------------------------------------------------------------------
sub parse_boolean {
  if ($_[0] eq 'y') { return 1; };
  if ($_[0] eq 'n') { return 0; };
  
  die "$0: valid boolean options are 'y' or 'n', not '$_[0]'\n";
}
#--------------------------------------------------------------------------------------------------
# Start a child process safely without using /bin/sh.
sub safe_read_from_pipe {
  unless (@_) {
    croak "$0: safe_read_from_pipe passed no arguments.\n";
  }
  
  my $pid = open(SAFE_READ, '-|');
  unless (defined $pid) {
    die "$0: cannot fork: $!\n";
  }
  
  unless ($pid) {
    open(STDERR, ">&STDOUT")
    or die "$0: cannot dup STDOUT: $!\n";
    
    exec(@_)
    or die "$0: cannot exec `@_': $!\n";
  }
  
  my @output;
  while (<SAFE_READ>) {
    s/[\r\n]+$//;
    push(@output, $_);
  }
  
  close(SAFE_READ);
  
  my $result = $?;
  my $exit   = $result >> 8;
  my $signal = $result & 127;
  my $cd     = $result & 128 ? "with core dump" : "";
  
  if ($signal or $cd) {
    warn "$0: pipe from `@_' failed $cd: exit=$exit signal=$signal\n";
  }
  
  if (wantarray) {
    return ($result, @output);
  }
  else {
    return $result;
  }
}
#--------------------------------------------------------------------------------------------------
# Use safe_read_from_pipe to start a child process safely and return
# the output if it succeeded or an error message followed by the output
# if it failed.
sub read_from_process {
  unless (@_) {
    croak "$0: read_from_process passed no arguments.\n";
  }
  
  my ($status, @output) = &safe_read_from_pipe(@_);
  if ($status) {
    return ("$0: `@_' failed with this output:", @output);
  }
  else {
    return @output;
  }
}
#--------------------------------------------------------------------------------------------------
