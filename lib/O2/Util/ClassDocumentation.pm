package O2::Util::ClassDocumentation;

# XXX Better logging, without tags

use strict;

use O2 qw($context);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless {}, $pkg;
}
#-----------------------------------------------------------------------------
sub generate {
  my ($obj) = @_;

  foreach my $path (@INC) {
    next unless $path =~ m{ o2 }xmsi;
    $obj->_scan($path);
  }

  my $documentationRoot = $context->getEnv('O2CUSTOMERROOT') . '/src/autodocumentation';

  $context->getSingleton('O2::File')->mkPath($documentationRoot) unless -d $documentationRoot;
  $context->getSingleton('O2::Data')->save("$documentationRoot/classes.plds", $obj->{classes});
  $obj->log("<font face='verdana,arial,helvetica'><b>Classes-documentation generated in $documentationRoot/classes.plds</b></font>");
}
#-----------------------------------------------------------------------------
sub _scan {
  my ($obj, $dir) = @_;
  my @files = eval { $context->getSingleton('O2::File')->scanDir($dir, '^[^.]') };
  foreach my $fileName (@files) {
    my $path = "$dir/$fileName";
    if (-d $path) {
      $obj->_scan($path);
    }
    else {
      next if $fileName !~ m{ \.pm \z }xms;
      $obj->_addClass($path);
    }
  }
}
#-----------------------------------------------------------------------------
sub _addClass {
  my ($obj, $fileName) = @_;
  my $currentClass = {};
  my $inTodo  = 0;
  my $todoIdx = 0;
  eval {
    foreach my $line ( $context->getSingleton('O2::File')->getFile($fileName) ) {
      if (my ($className) = $line =~ m{ \A \s* package \s+ ([^\s;]+) }xms) {
        if ($obj->{classes}->{$className}) {
          $currentClass = $obj->{classes}->{$className};
        }
        else {
          $currentClass = {};
          $obj->{classes}->{$className} = $currentClass;
          $obj->log("</ul>NEW CLASS: $1 => $fileName<ul>");
        }
      }
      elsif ($line =~ m/^\s*use\s+base\s+[\"\']([^\"\']+)[\"\']/) {
        $currentClass->{inherits}->{$1} = $1;
      }
      elsif ($line =~ m/^\s*(?:use|require)\s+([^\;\s\(]+)/) {
        $currentClass->{uses}->{$1} = $1;
      }
      elsif ($line =~ m/^\s*sub\s+([\w_\-]+)/) {
        $currentClass->{methods}->{$1} = $1;
      }
      elsif ($line =~ m/\#\s*(.+)/) { # We have a comment
        my $comment = $1;
        chomp $comment;
        if ($inTodo && $comment =~ m/\w+/) {
          $obj->log("<li> We are inside a todo, adding: $comment");
          $currentClass->{todos}->[$todoIdx] .= $comment;
        }
        elsif ($comment =~ m/XXX(.+)/i) {
          $obj->log("<li> FOUND TODO: $1");
          $currentClass->{todos}->[$todoIdx] = $1;
          $inTodo = 1;
        }
      }
      else {
        if ($inTodo) {
          $inTodo = 0;
          $todoIdx++;
        }
      }
    }
  };
  $obj->log("<li> WARNING: could not read $fileName: $@") if $@;
}
#-----------------------------------------------------------------------------
sub log {
  my ($obj, $msg) = @_;
  $obj->{logMessages} ||= [];
  push @{ $obj->{logMessages} }, $msg;
}
#-----------------------------------------------------------------------------
sub getLogMessages {
  my ($obj) = @_;
  return @{ $obj->{logMessages} };
}
#-----------------------------------------------------------------------------
1;
