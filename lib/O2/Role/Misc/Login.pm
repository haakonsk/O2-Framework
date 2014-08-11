package O2::Role::Misc::Login;

use strict;

use O2 qw($context $cgi $config $session);

#--------------------------------------------------------------------------------------#
sub login {
  my ($obj, %params) = @_;
  
  %params = $obj->getParams() unless %params;
  
  my $username  = $params{username};
  my $password  = $params{password};
  
  return $obj->usernameIsMissing(%params) unless $username;
  return $obj->passwordIsMissing(%params) unless $password;
  
  my $member = $context->getSingleton('O2::Mgr::MemberManager')->getMemberByUsername($username);
  if ( $member && ($params{loginOnBehalf} || $member->isCorrectPassword($password)) ) {
    # If permanent flag is set, we add a ttl to the session cookie
    if ($params{permanent}) {
      $session->set( 'cookieTtl', $config->get('session.backend.permanentTtl') );
      $session->save();
      $session->refreshCookie();
    }
    
    $session->set(
      'user',
      {
        username   => $member->getUsername(),
        userId     => $member->getId(),
        email      => $member->getEmail(),
        firstname  => $member->getFirstName(),
        middlename => $member->getMiddleName(),
        lastname   => $member->getLastName(),
      },
    );
    
    $session->login();
    
    return $obj->loginOnBehalfSuccess($member, %params) if $params{loginOnBehalf};
    return $obj->ajaxSuccess()                          if $params{isAjaxRequest} && $params{refreshLogin};
    return $obj->loginSuccess($member, %params);
  }
  
  return $obj->error() if $params{isAjaxRequest} && $params{refreshLogin};
  return $obj->loginError(%params);
}
#--------------------------------------------------------------------------------------#
sub redirectToLogin {
  my ($class, $params) = @_;
  # Build query string
  my $queryString;
  if (ref $params eq 'HASH') {
    foreach my $key (keys %{$params}) {
      my $value = $params->{$key};
      $queryString .= "$key=$value&";
    }
    $queryString = substr $queryString, 0, -1 if $queryString;
  }
  else {
    $queryString = $params;
  }
  require O2::Util::UrlMod;
  require O2::Cgi;
  my $cgi = O2::Cgi->new();

  my $loginSuccessUrl = $cgi->urlEncode( O2::Util::UrlMod->urlMod() );
  my $loginUrl        = O2::Util::UrlMod->urlMod(
    setClass  => 'User-Login',
    setMethod => 'loginForm',
    setParams => "loginSuccessUrl=$loginSuccessUrl&$queryString",
  );

  $cgi->redirect($loginUrl);
}
#--------------------------------------------------------------------------------------#
sub loginOnBehalf {
  my ($obj, %q) = @_;
  %q = $obj->getParams() unless %q;

  # Delete username and password in case they are present. Otherwise they could mess up the call to login.
  delete $q{username};
  delete $q{password};

  my $loginAsUserid = delete $q{loginAsUserid};
  my $loginAsUser   = $context->getObjectById($loginAsUserid);

  my $user = $session->get('user');

  my $currentUser = $context->getObjectById( $user->{userId} );

  if (!$context->getSingleton('O2::Mgr::MemberManager')->canLoginAs( $user->{userId}, $loginAsUserid )) {
    $obj->errorNotAllowedToLoginAsUser(%q);
    return;
  }

  $session->pushSession();
  $obj->login(
    username      => $loginAsUser->getUsername(),
    loginOnBehalf => 1,
    %q
  );
}
#--------------------------------------------------------------------------------------#
sub logout {
  my ($obj, %q) = @_;
  %q = $obj->getParams() unless %q;

  if ($session->canPopSession()) {
    # Logout on behalf
    $session->popSession();
    my $user = $session->get('user');
    my $loginAsUser = $context->getObjectById( $user->{userId} );
    $obj->login(
      username      => $user->{username},
      loginOnBehalf => 1,
      %q,
    );
  }
  else {
    $session->deleteSession();
    $obj->logoutSuccess();
  }
}
#--------------------------------------------------------------------------------------#
sub loginSuccess {
  my ($obj, $user, %q) = @_;
  return unless $q{loginSuccessUrl};

  # Build query string
  my $queryString = '';
  foreach my $key (keys %q) {
    next if $key !~ m{ \A loginSuccessParam_ (.+) \z }xms;
    my $newKey = $1;
    $queryString .= "$newKey=$q{$key}&";
  }
  $queryString = '?' . substr $queryString, 0, -1 if $queryString;

  $cgi->redirect( "$q{loginSuccessUrl}$queryString" );
}
#--------------------------------------------------------------------------------------#
sub loginOnBehalfSuccess {
  my ($obj, $user, %q) = @_;
  if ($q{loginOnBehalfSuccessUrl}) {
    $cgi->redirect( $q{loginOnBehalfSuccessUrl} );
  }
}
#--------------------------------------------------------------------------------------#
sub loginError {
  my ($obj, %q) = @_;
  if ($q{loginErrorUrl}) {
    $cgi->redirect( $q{loginErrorUrl} );
  }
}
#--------------------------------------------------------------------------------------#
sub logoutSuccess {
  my ($obj, %q) = @_;
  if ($q{logoutUrl}) {
    $cgi->redirect( $q{logoutUrl} );
  }
}
#--------------------------------------------------------------------------------------#
sub usernameIsMissing {
  my ($obj, %q) = @_;
  if ($q{usernameIsMissingUrl}) {
    $cgi->redirect( $q{usernameIsMissingUrl} );
  }
}
#--------------------------------------------------------------------------------------#
sub passwordIsMissing {
  my ($obj, %q) = @_;
  if ($q{passwordIsMissingUrl}) {
    $cgi->redirect( $q{passwordIsMissingUrl} );
  }
}
#--------------------------------------------------------------------------------------#
sub errorNotAllowedToLoginAsUser {
  my ($obj, %q) = @_;
  if ($q{notAllowedToLoginAsUserUrl}) {
    $cgi->redirect( $q{notAllowedToLoginAsUserUrl} );
  }
}
#--------------------------------------------------------------------------------------#
1;
