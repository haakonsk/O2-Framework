package O2::Util::SendMail;

use strict;

use O2 qw($context $config);

#-----------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $obj = bless \%params, $package;
  require MIME::Lite;
  $obj->{smtp} = $context->getEnv('O2_SMTP') || $config->get('o2.smtp') unless $params{smtp};
  die "No SMTP-server supplied" unless $obj->{smtp};
  $obj->{from} = $config->get('o2.smtpSender') unless $params{from};
  return $obj;
}
#-----------------------------------------------------------
sub send {
  my ($obj, %params) = @_;
  foreach (keys %params) {
    $obj->{$_} = $params{$_};
  }
  
  my $error = '';
  foreach (qw/to from/) {
    $error .= "Missing $_-parameter" unless $obj->{$_};
  }
  $error .= "No subject and no body specified - need at least one of them" if !$obj->{subject} && !$obj->{body};
  die $error if $error;
  
  $obj->{subject} ||= 'No subject';
  MIME::Lite->send('smtp', $obj->{smtp}, Timeout => 60);
  my @toAdresses = ref $obj->{to} eq 'ARRAY' ? @{ $obj->{to} } : $obj->{to};
  foreach my $toAddress (@toAdresses) {
    require Encode;
    my $msg = MIME::Lite->new(
      To      => $toAddress,
      From    => $obj->{from},
      Subject => Encode::encode('MIME-Header', $obj->{subject}),
      Type    => 'multipart/mixed',
    );
    $msg->attr('content-type.charset' => 'utf-8'); # Doing this makes sure "charset" is included in the mail header, which is probably a good thing.
    my $body = $obj->{body};
    if ($obj->{html}) {
      $body = "<html><body>\n$body\n</body></html>" unless $body =~ m{<html>.+</html>}is;
      # XXX This encoding could be wrong, depending on the templates (but the templates don't seem to exist anyway...)
      my $part = MIME::Lite->new(
        Type => "text/html",
        Data => Encode::encode('utf-8', $obj->{body}),
      );
      $part->attr('content-type.charset' => 'utf-8');
      $msg->attach($part);
    }
    else {
      #there is no reason to use anything else than UTF-8 for plain text
      my $part = MIME::Lite->new(
        Type => "text/plain",
        Data => Encode::encode('utf-8', $obj->{body}),
      );
      $part->attr('content-type.charset' => 'utf-8');
      $msg->attach($part);
    }
    foreach my $file ( @{ $obj->{attachments} } ) {
      if ($file->{method} eq 'file') {
        $msg->attach(
          Type        => $file->{Type},
          Id          => $file->{Id},
          Path        => $file->{Path},
          Disposition => 'attachment',
        );
      }
      elsif ($file->{method} eq 'data') {
        $msg->attach(
          Type => $file->{Type},
          Data => $file->{Data},
        );
      }
    }
    # MIME::Lite->send("smtp");
    my $ok;
    eval {
      $ok = $msg->send();
    };
    if ($@ || !$ok) {
      my $errorMsg = "Couldn't send email to $toAddress";
      $errorMsg   .= ": $@" if $@;
      die $errorMsg;
    }
  }
  return 1;
}
#-----------------------------------------------------------
sub addAttachment {
  my ($obj,$file,$name,$type) = @_;
  return unless -r $file;
  unless ($name) {
    ($name) = $file =~ m!/([^/]+\.\w+)$!;
  }
  unless ($type) {
    require O2::Util::MimeType;
    my $mimeType = O2::Util::MimeType->new();
    $type = $mimeType->getMimeTypeByFileName($file);
    return unless $type;
  }
  push @{ $obj->{attachments} }, {
    Id     => $name,
    Path   => $file,
    Type   => $type,
    method => 'file',
  };
}
#-----------------------------------------------------------
sub addContent {
  my ($obj, $content, $type) = @_;
  return unless ($content);
  $type = "text/plain; charset=utf-8" unless $type;
  if ($type =~ m{ \A text }xms) {
    require Encode;
    $content = Encode::encode('utf-8', $content);
  }
  push @{ $obj->{attachments} }, {
    Data   => $content,
    Type   => $type,
    method => 'data',
  };
}
#-----------------------------------------------------------
1;
