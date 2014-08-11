package O2::Gui::Response;

use strict;

use base 'O2::Gui';

use O2 qw($config);

#------------------------------------------------------------------------------------------------------------
sub send {
  my ($obj) = @_;
  my %q = $obj->getParams();

  my $langFile = $q{langFile} || 'response';

  require O2::Util::SendMail;
  eval {
    my $mail = O2::Util::SendMail->new(
      smtp    => $config->get('o2.smtp'),
      from    => $q{email},
      to      => $obj->{lang}->getString("$langFile.emailto", emailTo => $q{emailTo}),
      subject => $obj->{lang}->getString("$langFile.emailsubject"),
      body    => $obj->{lang}->getString("$langFile.emailbody", %q),
      html    => $q{isHtml} || 0,
    );
    $mail->send();
  };
  if ($@) {
    warning "Error sending mail: $@";
    if ($q{onErrorLanguageKey}) {
      $obj->ajaxDisplayString( '<div class="responseError">' . $obj->{lang}->getString( $q{onErrorLanguageKey} ) . '</div>' );
    }
    else {
      $obj->display(
        'sendOk.html',
        status => 'error',
      );
    }
  }
  else {
    if ($q{onSuccessLanguageKey}) {
      $obj->ajaxDisplayString( '<div class="responseOK">' . $obj->{lang}->getString( $q{onSuccessLanguageKey} ) . '</div>' );
    }
    else {
      $obj->display(
        'sendOk.html',
        status => 'ok',
      );
    }
  }
}
#------------------------------------------------------------------------------------------------------------
1;
