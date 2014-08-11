package O2::Script::Test::Common;

use strict;

use base 'Exporter';
use Test::More;

our @EXPORT = qw(diag redirect_ok display_ok getTestObjectId deleteTestObjects);
our @TEST_OBJECT_IDS;

use O2 qw($context $cgi);
use O2::Util::Args::Simple;

# Declaring these variables with our instead of my, allows other modules to modify them, which may actually be necessary in certain situations.
our ($REDIRECT_URL, $DISPLAY_TEMPLATE);

#-----------------------------------------------------------------------------
sub import {
  my ($class, %params) = @_;
  require O2::Cgi; # Make sure Cgi.pm is read into memory before we start modifying its "redirect" method
  *O2::Cgi::redirect = sub {
    my ($obj, @params) = @_;
    my $url = @params == 1 ? $params[0] : $context->getSingleton('O2::Util::UrlMod')->urlMod(@params);
    $REDIRECT_URL = $url;
  };
  require O2::Gui; # Make sure Gui.pm is read into memory before we start modifying its "displayPage" method
  *O2::Gui::displayPage = sub {
    my ($obj, $file, %params) = @_;
    $DISPLAY_TEMPLATE = $file;
  };
  *O2::Gui::display = sub {
    my ($obj, $file, %params) = @_;
    $DISPLAY_TEMPLATE = $file;
  };
  return O2::Script::Test::Common->export_to_level(1, $class, %params); # I didn't understand why I had to do this. It's an Exporter thing (http://search.cpan.org/~nwclark/perl-5.8.8/lib/Exporter.pm)
}
#-----------------------------------------------------------------------------
sub diag {
  my ($msg) = @_;
  $msg =~ s{ \n }{\n# }xmsg;
  print "# $msg\n" if $ARGV{-verbose} || $ARGV{v};
}
#-----------------------------------------------------------------------------
sub redirect_ok { # Underscore in method name for "compatibility" with Test::More
  my ($url, $title) = @_;
  my $redirectUrl = $REDIRECT_URL;
  $REDIRECT_URL = undef;
  return Test::More::is($redirectUrl, $url, $title);
}
#-----------------------------------------------------------------------------
sub display_ok { # Underscore in method name for "compatibility" with Test::More
  my ($template, $title) = @_;
  my $displayTemplate = $DISPLAY_TEMPLATE;
  $DISPLAY_TEMPLATE = undef;
  return Test::More::is($displayTemplate, $template, $title);
}
#-----------------------------------------------------------------------------
sub setCgiParams {
  my (%params) = @_;
  clearCgiParams();
  foreach my $key (keys %params) {
    $cgi->setParam($key, $params{$key});
  }
}
#-----------------------------------------------------------------------------
sub clearCgiParams {
  $cgi->deleteParams();
}
#-----------------------------------------------------------------------------
{
  my $originalContent;
  my $wasTied;

  sub startCapturingOutput {
    $originalContent = $cgi->{content};
    $cgi->{content} = '';
    if ($cgi->{isTied}) {
      $wasTied = 1;
    }
    else {
      tie *STDOUT, 'O2::Cgi::TieOutput', $cgi;
      $wasTied = 0;
    }
  }

  sub deleteCapturedOutput {
    my $content = $cgi->{content};
    $cgi->{content} = $originalContent;
    untie *STDOUT if !$wasTied;
    return $content;
  }
}
#-----------------------------------------------------------------------------
sub getTestObjectId {
  my $object = $context->getSingleton('O2::Mgr::ObjectManager')->newObject();
  $object->setMetaName('Test-object');
  $object->save();
  push @TEST_OBJECT_IDS, $object->getId();
  return $object->getId();
}

sub deleteTestObjects {
  foreach my $objectId (@TEST_OBJECT_IDS) {
    my $object = eval {
      return $context->getObjectById($objectId);
    };
    $object->deletePermanently() if $object;
  }
}
#-----------------------------------------------------------------------------
1;
