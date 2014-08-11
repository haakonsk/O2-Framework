package O2::Role::Misc::HttpSession;

use strict;

use constant DEBUG => 0;

use O2 qw($context $cgi $config);

#--------------------------------------------------------------------------------------------------
sub _init {
  my ($obj, %params) = @_;
  $obj->{publicSession} = $obj->_getPublicSessionData();
  
  $obj->validate() unless $params{dontValidate};
  $obj->refreshCookie();
}
#--------------------------------------------------------------------------------------------------
sub getCookieName {
  return $config->get('session.cookieName');
}
#--------------------------------------------------------------------------------------------------
sub getCookiePath {
  return $config->get('session.cookiePath');
}
#--------------------------------------------------------------------------------------------------
sub getTtl {
  my ($obj) = @_;
  return $obj->get('cookieTtl') || $config->get('session.ttl');
}
#--------------------------------------------------------------------------------------------------
sub getExistingSessionId {
  my ($obj) = @_;
  return $cgi->getCookie( $obj->getCookieName() )  ||  $cgi->getParam( $obj->getCookieName() );
}
#--------------------------------------------------------------------------------------------------
sub regenerateId {
  my ($obj, $id) = @_;
  debug "regenerating ID";
  $obj->refreshCookie();
  $obj->{needsToBeSaved} = 1;
}
#--------------------------------------------------------------------------------------------------
# Sets a session variable. The session variable will also be accessible on the client (Javascript)
sub setPublic {
  my ($obj, $name, $value) = @_;
  $obj->set($name, $value);
  $obj->{publicSession}->{$name} = $value;
}
#--------------------------------------------------------------------------------------------------
sub login {
  my ($obj) = @_;
  debug "login";
  
  my $subnet    = $context->getClientIp(); # Actually this is the ip
  $subnet       =~ s{ [.] \d+ \z }{}xms;   # But *this* is the subnet
  my $userAgent = $context->getEnv('HTTP_USER_AGENT');
  
  $obj->set( 'isLoggedIn', 1                     );
  $obj->set( 'subnet',     $subnet               );
  $obj->set( 'userAgent',  $userAgent            );
  $obj->set( 'cookieName', $obj->getCookieName() );
  
  $obj->_regenerateId();
}
#--------------------------------------------------------------------------------------------------
sub isLoggedIn {
  my ($obj) = @_;
  return $obj->get('isLoggedIn') || 0;
}
#--------------------------------------------------------------------------------------------------
sub logout {
  my ($obj) = @_;
  $obj->delete( 'isLoggedIn' );
  $obj->delete( 'subnet'     );
  $obj->delete( 'userAgent'  );
  $obj->delete( 'cookieName' );
}
#--------------------------------------------------------------------------------------------------
sub validate {
  my ($obj, $msg) = @_;
  
  return 1 unless $obj->get('isLoggedIn');
  
  # Make sure subnet and user agent haven't changed
  my $actualSubnet    = $context->getClientIp() || ''; # Actually this is the ip
  $actualSubnet       =~ s{ [.] \d+ \z }{}xms;         # But *this* is the subnet
  my $actualUserAgent = $context->getEnv('HTTP_USER_AGENT');
  
  if ( $actualSubnet ne $obj->get('subnet')  ||  $actualUserAgent ne $obj->get('userAgent')  ||  $obj->getCookieName() ne $obj->get('cookieName') ) {
    warning sprintf "Forcing logout of user %s. Subnet: $actualSubnet (expected: %s), userAgent: $actualUserAgent (expected: %s), cookieName (session): %s (expected: %s)",
      $obj->get('user')->{userId} || '?', $obj->get('subnet'), $obj->get('userAgent'), $obj->get('cookieName'), $obj->getCookieName();
    
    $obj->deleteSession();
    
    my $loginUrl = $obj->getNeedAuthRedirectUrl();
    
    return $cgi->redirect($loginUrl) unless $cgi->getParam('isAjaxRequest');
    
    $cgi->setParam('loginUrl', $loginUrl);
    return $cgi->ajaxError('notLoggedIn');
  }
}
#--------------------------------------------------------------------------------------------------
# Set cookie with session variables set with "setPublic". The variables will be accessible with Javascript
sub setPublicSessionCookie {
  my ($obj, %params) = @_;
  
  use O2::Javascript::Data;
  my $jsData = O2::Javascript::Data->new();
  my $value  = $params{deletePublicSessionCookie} ? '' : $jsData->dump( $obj->{publicSession} );
  
  my %cookie = (
    name  => $context->getEnv('SERVER_NAME') . '_session',
    value => $value,
    path  => $obj->getCookiePath(),
    debug => 0,
  );
  
  my $ttl = $obj->getTtl();
  $cookie{expires} = $ttl + time if $ttl;
  
  $cgi->setCookie(%cookie);
}
#--------------------------------------------------------------------------------------------------
# Sets the session-id cookie
sub refreshCookie {
  my ($obj) = @_;
  
  my %cookie = (
    name  => $obj->getCookieName() || undef,
    value => $obj->getId()         || undef,
    path  => $obj->getCookiePath() || undef,
  );
  
  my $ttl = $obj->getTtl();
  $cookie{expires} = $ttl + time if $ttl;
  
  $cgi->setCookie(%cookie);
}
#--------------------------------------------------------------------------------------------------
sub _deleteCookies {
  my ($obj) = @_;
  $obj->setPublicSessionCookie( deletePublicSessionCookie => 1 );
  $cgi->deleteCookie( $context->getEnv('SERVER_NAME') . '_session' );
  $cgi->deleteCookie( $obj->getCookieName()                        );
}
#--------------------------------------------------------------------------------------------------
1;
