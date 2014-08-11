package O2::Gui::User::Locale;

use strict;

use base 'O2::Gui';

use O2 qw($context $cgi $session);

#------------------------------------------------------------------------------------------------------------
sub setLocale {
  my ($obj, %q) = @_;
  my $user = $context->getUser();
  
  if ($user) {
    $user->setAttribute( 'locale', $obj->getParam('locale') );
    $user->save();
  }
  else {
    $session->set('locale', $obj->getParam('locale'));
    $session->save();
  }
  
  return $obj->ajaxSuccess() if $obj->getParam('isAjaxRequest');
  
  $cgi->redirect( $obj->getParam('url') || '/' );
}
#------------------------------------------------------------------------------------------------------------
sub redirect {
  my ($obj) = @_;
  $cgi->redirect( $obj->getParam('url') || '/' );
}
#------------------------------------------------------------------------------------------------------------
1;
