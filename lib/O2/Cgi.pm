package O2::Cgi;

use strict;

require Encode;

use JSON;
use O2::Util::List qw(upush);
require O2;

our $isModPerl = undef;
our $CGI;

#--------------------------------------------------------------------------------------------
sub import {
  my ($thisPackage, %params) = @_;
  my $package = caller;

  $isModPerl = 1 if exists $ENV{MOD_PERL} || $ENV{MOD_PERL_API_VERSION};

  if ( (!$params{handleFatals} || lc $params{handleFatals} ne 'no')  &&  !$isModPerl ) {
    no strict;
    ${$package.'::SIG'}{__DIE__} = O2::Cgi::_gracefulDie;
  }
}
#--------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  if ($CGI) {
    $CGI->{bufferKilled}    = 0;
    $CGI->{cookies}         = {};
    $CGI->{outputCalled}    = 0;
    $CGI->{paramsInstalled} = 0;
    return $CGI;
  }

  my $obj = bless {}, $package;

  $obj->setStatus('ok');
  $obj->{isSpeedyCgi}    = $params{isSpeedyCgi} || 0;
  $obj->{isModPerl}      = $isModPerl;
  $obj->{modPerlRequest} = $params{modPerlRequest};
  if (exists $ENV{IS_O2_DEV_SERVER}) {
    if (exists $ENV{GATEWAY_INTERFACE} && $ENV{GATEWAY_INTERFACE} eq 'CGI-PerlEx') {
      PerlEx::ReloadAll();
    }
  }

  if ( !$params{tieStdout} || lc $params{tieStdout} ne 'no' ) {
    $obj->_tieStdOut();
  }
  else {
    $obj->{isTied} = 0;
  }

  $obj->{paramsInstalled} = 0;
  $obj->{bufferKilled}    = 0;
  $obj->{cookies}         = {};
  $obj->{outputCalled}    = 0;
  return $CGI = $obj;
}
#--------------------------------------------------------------------------------------------
sub getContext {
  my ($obj) = @_;
  return $O2::context;
}
#--------------------------------------------------------------------------------------------
sub _tieStdOut {
  my ($obj) = @_;
  return if $obj->{isTied};
  $obj->{isTied} = 1;
  tie *STDOUT, 'O2::Cgi::TieOutput', $obj;
}
#--------------------------------------------------------------------------------------------
sub _untieStdOut {
  my ($obj) = @_;
  return unless $obj->{isTied};
  $obj->{isTied} = 0;
  untie *STDOUT;
}
#--------------------------------------------------------------------------------------------
sub isSpeedyCgi {
  my ($obj) = @_;
  return $obj->{isSpeedyCgi};
}
#--------------------------------------------------------------------------------------------
sub getEnv {
  my ($obj, $name) = @_;
  my $context = $obj->getContext();
  return $context ? $context->getEnv($name) : $ENV{$name};
}
#--------------------------------------------------------------------------------------------
# Sends all content we've collected so far to the browser
# Doesn't untie STDOUT permanently, as output does
sub flush {
  my ($obj) = @_;
  $obj->_untieStdOut();
  $obj->outputHeaders() unless $obj->headersSent();
  $obj->encodeContent();
  print STDOUT $obj->{content};
  $obj->_tieStdOut();
  $obj->{content} = '';
}
#--------------------------------------------------------------------------------------------
sub enableAutoflush {
  my ($obj) = @_;
  $obj->{autoflush} = 1;
}
#--------------------------------------------------------------------------------------------
sub encodeContent {
  my ($obj) = @_;
  if (!$obj->{doNotEncodeOutputBuffer}  &&  $obj->getContentType() =~ m{ \A text/ }xmsi) { # Encodes all content-types that start with "text/", is that ok?
    $obj->{content} = Encode::encode( $obj->getCharacterSet(), $obj->{content} );
  }
}
#--------------------------------------------------------------------------------------------
sub output {
  my ($obj) = @_;
  return if $obj->{bufferKilled}; # XXX This may not be a very well thought out plan
  return if $obj->{outputCalled};
  $obj->{outputCalled} = 1;

  return if !exists $obj->{content} || !length $obj->{content};
  return if $obj->{died};

  $obj->_untieStdOut();
  binmode STDOUT if $obj->{binMode};

  $obj->{content} =~ s{ \A \s+ }{}xms; # Remove newlines at the beginning
  $obj->encodeContent();
  $obj->outputHeaders();
  binmode STDOUT;
  print   STDOUT $obj->{content};
  $obj->{content} = undef;
}
#--------------------------------------------------------------------------------------------
sub headersSent {
  my ($obj) = @_;
  return $obj->{headersSent};
}
#--------------------------------------------------------------------------------------------
sub outputHeaders {
  my ($obj) = @_;
  $obj->{headersSent} = 1;
  
  # When processing AJAX request we should make sure we don't use cached data
  if ($obj->getParam('isAjaxRequest')) {
    $obj->addHeader('Cache-Control', 'no-cache, must-revalidate');
  }
  
  my @headers = $obj->getAndDeleteHeaders();
  
  # content type
  my $contentType = $obj->getContentType();
  print STDOUT "Content-type: $contentType\n";

  # send cookies
  foreach my $cookieName (keys %{ $obj->{cookies} }) {
    my $cookie = $obj->{cookies}->{$cookieName};
#    O2::_debug("Sending cookie: $cookie");
    print STDOUT "Set-Cookie: $cookie\n";
  }

  # send other headers
  for (my $i = 0; $i <= $#headers; $i += 2) {
    print STDOUT "$headers[$i]: $headers[$i+1]\n";
  }

  # send extra \n to indicate end-of-headers
  print STDOUT "\n";
}
#--------------------------------------------------------------------------------------------
sub getParams {
  my ($obj) = @_;
  $obj->installParams() unless $obj->{paramsInstalled};
  return %{ $obj->{params} || {} };
}
#--------------------------------------------------------------------------------------------
sub setParam {
  my ($obj, $key, @values) = @_;
  $obj->installParams() unless $obj->{paramsInstalled};
  $obj->{params}->{$key} = $#values ? [@values] : $values[0];
}
#--------------------------------------------------------------------------------------------
sub deleteParam {
  my ($obj,$key) = @_;
  $obj->installParams() unless $obj->{paramsInstalled};
  return delete $obj->{params}->{$key};
}
#--------------------------------------------------------------------------------------------
sub getParam {
  my ($obj, $key) = @_;
  $obj->installParams() unless $obj->{paramsInstalled};
  return undef unless defined $obj->{params}->{$key};
  return wantarray && ref $obj->{params}->{$key} eq 'ARRAY'  ?  @{ $obj->{params}->{$key} }  :  $obj->{params}->{$key};
}
#--------------------------------------------------------------------------------------------
sub getDecimalParam {
  my ($obj, $key) = @_;
  my $value = $obj->getParam($key);
  return 0 unless $value;
  
  $value =~ s{ , }{.}xmsg;
  $value =~ s{ \s }{}xmsg; # Ignore white space
  die "Not a decimal number: $value" if $value !~ m{ \A  (?: \d* [.] )?  \d+  \z }xms;
  
  return $value + 0;
}
#--------------------------------------------------------------------------------------------
sub deleteParams {
  my ($obj) = @_;
  my %params = $obj->getParams();
  foreach my $key (keys %params) {
    $obj->deleteParam($key);
  }
}
#--------------------------------------------------------------------------------------------
sub getStructure {
  my ($obj, $key, %params) = @_;
  my $ref;
  %params = $obj->getParams() unless %params;

  my @sortedParams;
  foreach (keys %params) {
    push @sortedParams, {
      param   => $_,
      sortKey => m{ _dataType }xms ? 0 : 1,
    };
  }

  foreach my $param ( map { $_->{param} }  sort { $a->{sortKey} <=> $b->{sortKey} }  @sortedParams ) {

    # 20080208 nilschd allow structure on this format in input fields "test->{a}->{b}" etc...
    my $orgParam = $param;
    $param =~ s{ [\{\}] }{}xmsg;
    $param =~ s{  ->    }{\.}xmsg;
    $orgParam = '' if $param eq $orgParam;
    # end nilschd 20080208 hack

    if ($param =~ m{ \A $key (?: \. | \[ [\d\s]+ \] ) }xms) {
      my @parts = split /\.|(\[[\d\s]+\])/, $param;
      my $notFirst = 0;
      my $string = '';
      foreach my $part (@parts) {
        next unless length $part;
        unless ($notFirst++) {
          $string = '$ref';
          next;
        }
        if ($part =~ m{ \A [\s\w\:-]+ \z }xms) {
          $string .= "->{'$part'}";
        }
        elsif ($part =~ m{ \A \[\s*(\d+)\s*\] \z }xms) {
          $string .= "->[$1]";
        }
        else {
          die "Illegal parameter '$part'!";
        }
      }
      my $value = $params{ $orgParam || $param };
      if ($parts[2] eq '_dataType') {
        $string
          .= $value =~ m{ array }xmsi ? '=[]'
           : $value =~ m{ hash  }xmsi ? '={}'
           :                            '=undef'
           ;
        $string  =~ s{ \{  _dataType  \}-> }{}xms;
        $string  =~ s{ \{\'_dataType\'\}-> }{}xms;
      }
      elsif (ref $value eq 'ARRAY') {
        for my $i ( 0 .. $#{$value} ) {
          my $elm = $value->[$i];
          next unless ref $elm;
          foreach ( $obj->_getKeysWithDots($elm) ) {
            $value->[$i]->{$_} = $obj->getStructure( $_, %{$elm} );
            $obj->_deleteEntriesStartingWith( $value->[$i], "$_." );
          }
        }
        $string .= '=$value';
      }
      elsif (ref $value eq 'O2::Cgi::File' || ref $value eq 'O2::Cgi::DateTime') {
        $string .= '=$value';
      }
      else {
        $value =~ s{ \\ }{\\\\}xmsg;
        $value =~ s{  ' }{\\\'}xmsg;
        $string .= length $value ? "='$value'" : '=undef';
      }
      eval "$string";
    }
  }
  return $ref;
}
#--------------------------------------------------------------------------------------------
sub _deleteEntriesStartingWith {
  my ($obj, $struct, $startsWith) = @_;
  foreach ( keys %{$struct} ) {
    delete $struct->{$_} if $_ =~ m{ \A \Q$startsWith\E }xms;
  }
}
#--------------------------------------------------------------------------------------------
sub _getKeysWithDots {
  my ($obj, $params) = @_;
  my @keys;
  foreach ( keys %{$params} ) {
    upush @keys, $1 if $_ =~ m{ \A (.+) [.] .+ }xms;
  }
  return @keys;
}
#--------------------------------------------------------------------------------------------
sub installParams {
  my ($obj) = @_;
  return if $obj->{paramsInstalled};
  
  $obj->{params} = $obj->_findQ();
  my @dateParams;
  
  foreach my $key (keys %{ $obj->{params}} ) {
    # Make sure variables whose name ends with "[]" are array refs. Also remove "[]" from the variable name
    if (my ($newKey, $arrayIndex) = $key =~ m{ \A (.+) \[ (\d*) \] \z }xms) {
      if (length $arrayIndex) {
        $obj->{params}->{$newKey}->[$arrayIndex] = delete $obj->{params}->{$key};
      }
      else {
        $obj->{params}->{$newKey} = delete $obj->{params}->{$key};
        if ( !ref $obj->{params}->{$newKey}   &&   length ( $obj->{params}->{$newKey} )  >  0 ) {
          $obj->{params}->{$newKey} = [ $obj->{params}->{$newKey} ];
        }
        elsif (!ref $obj->{params}->{$newKey}) {
          $obj->{params}->{$newKey} = [];
        }
      }
    }
    elsif (my ($hashName) = $key =~ m{ \A (.+) \{\} \z }xms) {
      $obj->{params}->{$hashName} = from_json( delete $obj->{params}->{$key} );
    }
    elsif (my ($arrayName, $keyName) = $key =~ m{ \A (.+) \[\] [.] (.+) \z }xms) { # Support parameters with arrays inside them, like object.members[].username and object.members[].password
      while (exists $obj->{params}->{$key}) {
        $obj->{params}->{$arrayName} ||= [];
        my $hasInsertedKey = 0;
        my $numElements = @{ $obj->{params}->{$arrayName} };
        my $i = 0; # $i is used after the for loop, so can't declare $i in the for loop, as would be normal
        for (0 .. $numElements) {
          $i = $_;
          if ( $obj->{params}->{$arrayName}->[$i]  &&  !exists $obj->{params}->{$arrayName}->[$i]->{$keyName} ) {
            $obj->{params}->{$arrayName}->[$i]->{$keyName} = ref ( $obj->{params}->{$key} ) eq 'ARRAY'  ?  shift @{ $obj->{params}->{$key} }  :  delete $obj->{params}->{$key};
            $hasInsertedKey = 1;
          }
        }
        if (!$hasInsertedKey) {
          $obj->{params}->{$arrayName}->[$i] = {
            $keyName => ref ( $obj->{params}->{$key} ) eq 'ARRAY'  ?  shift @{ $obj->{params}->{$key} }  :  delete $obj->{params}->{$key},
          };
        }
        delete $obj->{params}->{$key} if ref ( $obj->{params}->{$key} ) eq 'ARRAY'  &&  @{ $obj->{params}->{$key} } == 0;
      }
    }
    
    next if ref $obj->{params}->{$key} eq 'O2::Cgi::DateTime';
    
    if (my ($name) = $key =~ m{ \A o2DateSelectFormat_ (.*) \z }xms) {
      my $dateTime = $obj->getContext()->getSingleton('O2::Mgr::DateTimeManager')->newObject( $obj->{params}->{$name} );
      if ($obj->{params}->{$name}) {
        require O2::Cgi::DateTime;
        $obj->{params}->{$name} = O2::Cgi::DateTime->new(
          name     => $name,
          format   => $obj->{params}->{$key},
          dateTime => $dateTime,
        );
      }
      push @dateParams, $key;
    }
  }
  
  $obj->{paramsInstalled} = 1;
  foreach my $param (@dateParams) {
    $obj->deleteParam($param); # Have to call deleteParam after paramsInstalled is set, otherwise we get an infinite loop
  }
}
#--------------------------------------------------------------------------------------------
sub killBuffer {
  my ($obj) = @_;
  
  if ($obj->{isTied}) {
    $obj->_untieStdOut();
    $obj->{binMode} = 0;
  }
  $obj->{bufferKilled} = 1;
  
  $obj->{content} = undef;
}
#--------------------------------------------------------------------------------------------
sub setCookie {
  my ($obj, @params) = @_;
  require O2::Cgi::Cookie;
  my ($header, $cookie) = O2::Cgi::Cookie::setCookie(@params);
  my ($cookieName, $cookieValue) = $cookie =~ m{  \A  ([^=]+)  =  ([^;]*)  }xms;
  $obj->{cookies}->{$cookieName} = $cookie;
  $obj->_removeDeleteCookieHeaders($cookieName);
}
#--------------------------------------------------------------------------------------------
sub _removeDeleteCookieHeaders {
  my ($obj, $cookieName) = @_;
  my @headers = @{ $obj->{headers} || [] };
  foreach (my $i = 0; $i <= $#headers; $i += 2) {
    if ($headers[$i+1] =~ m{ \A \Q$cookieName\E = }xms) {
      splice @headers, $i, 2;
      $obj->{headers} = \@headers;
    }
  }
}
#--------------------------------------------------------------------------------------------
sub getCookie {
  my ($obj, @params) = @_;
  require O2::Cgi::Cookie;
  return O2::Cgi::Cookie::getCookie(@params);
}
#--------------------------------------------------------------------------------------------
sub deleteCookie {
  my ($obj, @params) = @_;
  require O2::Cgi::Cookie;
  $obj->addHeader( O2::Cgi::Cookie::deleteCookie(@params) );
}
#--------------------------------------------------------------------------------------------
sub error {
  my ($obj, @params) = @_;
  $obj->killBuffer();
  
  require O2::Cgi::FatalsToBrowser;
  print O2::Cgi::FatalsToBrowser::html(@params);
  $obj->output();
  $obj->exit();
}
#--------------------------------------------------------------------------------------------
sub ajaxError {
  my ($obj, $errorMsg, $errorHeader) = @_;
  $obj->_tieStdOut();
  my %params = $obj->getParams();
  $params{result}      = 'error';
  $params{errorMsg}    = $errorMsg;
  $params{errorHeader} = $errorHeader || '';
  require O2::Javascript::Data;
  my $js = O2::Javascript::Data->new()->dump(\%params);
  $js    =~ s{\r}{ }xmsg;
  if (!$obj->getParam('xmlHttpRequestSupported')) {
    print "<script type='text/javascript'>parent.o2.ajax.handleServerResponseIframe($js);</script>";
  }
  else {
    print "result = $js";
  }
  $obj->_untieStdOut();
  $obj->output();
  $obj->exit();
}
#--------------------------------------------------------------------------------------------
sub redirectWithoutExit {
  my ($obj, @params) = @_;
  my $url = @params == 1  ?  shift @params  :  $obj->getContext()->getSingleton('O2::Util::UrlMod')->urlMod(@params);
  my %params = @params;
  
  my $session = $obj->getContext()->getSession();
  $session->save() if $session->{needsToBeSaved};
  
  if ($params{__method} && lc $params{__method} eq 'post') {
    $obj->setParam('url', $url);
    $obj->getContext()->getSingleton('O2::Gui::System::Redirect')->redirectWithPost();
    $obj->output();
    return;
  }
  
  $obj->killBuffer();
  
  # Tip: to test redirect results, use: HEAD http://<hostname>/<path>/<file>?<params>
  $obj->setHttpStatusMessage('HTTP/1.1 302 Found');
  my $serverName = $obj->getEnv('SERVER_NAME');
  if    ($url =~ m!^https?://!) {}
  elsif ($url =~ m!^[^/]+!) {
    # This is to support relative redirects
    my ($request) = $obj->getEnv('REQUEST_URI') =~ m!(.*)/[^/]*$!;
    $url = "http://$serverName$request/$url";
  }
  elsif ($url =~ m!^/!) {
    # This is to support absolute redirect without server address
    $url = "http://$serverName$url";
  }
  
  $obj->addHeader('Location', $url);
  $obj->outputHeaders();
  $obj->setStatus('redirected');
}
#--------------------------------------------------------------------------------------------
sub redirect {
  my ($obj, @params) = @_;
  $obj->redirectWithoutExit(@params);
  $obj->exit();
}
#--------------------------------------------------------------------------------------------
sub fileDownload {
  my ($obj,%params)=@_;
  require O2::Cgi::FileDownload;
  O2::Cgi::FileDownload::setupDownload(cgi => $obj,%params);
  $obj->exit();
}
#--------------------------------------------------------------------------------------------
sub urlEncode { # XXX Move this out??
  my ($obj, $url) = @_;
  return $obj->utf8UrlEncode($url) if $obj->getCharacterSet() eq 'utf-8';
  $url =~ s/([^\sa-zA-Z0-9_])/"%" . uc (sprintf "%lx", ord $1)/eg;
  $url =~ tr/ /+/;
  return $url;
}
#--------------------------------------------------------------------------------------------
{
  # Javascript version found on http://www.hypergurl.com/urlencode.html
  # According to RFC 3986, only characters from a set of reserved and a set of unreserved characters are allowed in a URL:
  my $unreserved = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_.~";
  my $reserved   = "!*'();:@&=+\$,/?%#[]";
  my $allowed    = "$unreserved$reserved";
  my $hexchars   = "0123456789ABCDEFabcdef";
  my %chars; # Cache, so that we don't need to look up the same character more than once

  sub getHex {
    my ($obj, $decimal) = @_;
    my $hex = "%" . substr ($hexchars, $decimal >> 4, 1) . substr ($hexchars, $decimal & 0xF, 1);
    return $hex;
  }

  sub utf8UrlEncode {
    my ($obj, $str) = @_;
    my $encoded = "";

    my @chars = split //, $str;

    foreach my $ch (@chars) {
      # Check if character is an unreserved character:
      if ($chars{$ch}) {
        $encoded = $encoded . $chars{$ch};
      }
      elsif (-1 != index $unreserved, $ch) {
        $encoded = $encoded . $ch;
        $chars{$ch} = $ch;
      }
      else {

        # The position in the Unicode table tells us how many bytes are needed.
        # Note that if we talk about first, second, etc. in the following, we are
        # counting from left to right:
        #
        #   Position in   |  Bytes needed   | Binary representation
        #  Unicode table  |   for UTF-8     |       of UTF-8
        # ----------------------------------------------------------
        #     0 -     127 |    1 byte       | 0XXX.XXXX
        #   128 -    2047 |    2 bytes      | 110X.XXXX 10XX.XXXX
        #  2048 -   65535 |    3 bytes      | 1110.XXXX 10XX.XXXX 10XX.XXXX
        # 65536 - 2097151 |    4 bytes      | 1111.0XXX 10XX.XXXX 10XX.XXXX 10XX.XXXX

        my $charcode = ord $ch;
        my $encodedChar = '';

        # Position 0 - 127 is equal to percent-encoding with an ASCII character encoding:
        if ($charcode < 128) {
          $encodedChar .= $obj->getHex($charcode);
        }

        # Position 128 - 2047: two bytes for UTF-8 character encoding.
        if ($charcode > 127 && $charcode < 2048) {
          # First UTF byte: Mask the first five bits of charcode with binary 110X.XXXX:
          $encodedChar .= $obj->getHex(($charcode >> 6) | 0xC0);
          # Second UTF byte: Get last six bits of charcode and mask them with binary 10XX.XXXX:
          $encodedChar .= $obj->getHex(($charcode & 0x3F) | 0x80);
        }

        # Position 2048 - 65535: three bytes for UTF-8 character encoding.
        if ($charcode > 2047 && $charcode < 65536) {
          # First UTF byte: Mask the first four bits of charcode with binary 1110.XXXX:
          $encodedChar .= $obj->getHex(($charcode >> 12) | 0xE0);
          # Second UTF byte: Get the next six bits of charcode and mask them binary 10XX.XXXX:
          $encodedChar .= $obj->getHex((($charcode >> 6) & 0x3F) | 0x80);
          # Third UTF byte: Get the last six bits of charcode and mask them binary 10XX.XXXX:
          $encodedChar .= $obj->getHex(($charcode & 0x3F) | 0x80);
        }

        # Position 65536 - : four bytes for UTF-8 character encoding.
        if ($charcode > 65535) {
          # First UTF byte: Mask the first three bits of charcode with binary 1111.0XXX:
          $encodedChar .= $obj->getHex(($charcode >> 18) | 0xF0);
          # Second UTF byte: Get the next six bits of charcode and mask them binary 10XX.XXXX:
          $encodedChar .= $obj->getHex((($charcode >> 12) & 0x3F) | 0x80);
          # Third UTF byte: Get the last six bits of charcode and mask them binary 10XX.XXXX:
          $encodedChar .= $obj->getHex((($charcode >> 6) & 0x3F) | 0x80);
          # Fourth UTF byte: Get the last six bits of charcode and mask them binary 10XX.XXXX:
          $encodedChar .= $obj->getHex(($charcode & 0x3F) | 0x80);
        }

        $encoded   .= $encodedChar;
        $chars{$ch} = $encodedChar;

      }
    }
    return $encoded;
  }
}
#--------------------------------------------------------------------------------------------
sub urlDecode { # XXX Move this out??
  my ($obj, $item, $ajaxEncoding) = @_;
  return $item unless $item;

  $item =~ tr/+/ /;
  $item =~ s{ % ( [\da-fA-F]{2} ) }{ pack('C', hex $1) }xmsge;
  $item = Encode::decode($ajaxEncoding || 'utf-8', $item);

  return $item;
}
#--------------------------------------------------------------------------------------------
sub setStatus {
  my ($obj, $status) = @_;
  $obj->{status} = $status;
}
#--------------------------------------------------------------------------------------------
sub getStatus {
  my ($obj) = @_;
  return $obj->{status};
}
#--------------------------------------------------------------------------------------------
sub setContentType {
  my ($obj, $contentType) = @_;
  $obj->{contentType} = $contentType;
}
#--------------------------------------------------------------------------------------------
sub setCharacterSet {
  my ($obj, $charset) = @_;
  $obj->{characterSet} = $charset || 'utf-8';
}
#--------------------------------------------------------------------------------------------
sub getCharacterSet {
  my ($obj, $charset) = @_;
  return $obj->{characterSet} || 'utf-8';
}
#--------------------------------------------------------------------------------------------
sub characterSetIsSet {
  my ($obj) = @_;
  return $obj->{characterSet} ? 1 : 0;
}
#--------------------------------------------------------------------------------------------
sub getContentType {
  my ($obj) = @_;
  my $charset = '';
  if ($obj->{characterSet} && (!defined $obj->{contentType} || index ($obj->{contentType}, 'charset') == -1)) {
    $charset = '; charset=' . $obj->getCharacterSet();
  }
  return ($obj->{contentType} || 'text/html') . $charset;
}
#--------------------------------------------------------------------------------------------
sub addHeader {
  my ($obj, $type, $value) = @_;
  push @{ $obj->{headers} }, $type => $value;
}
#--------------------------------------------------------------------------------------------
# set http status message (example: "HTTP/1.1 200 OK")
sub setHttpStatusMessage {
  my ($obj, $statusMessage) = @_;
  $obj->{httpStatusMessage} = $statusMessage;
}
#--------------------------------------------------------------------------------------------
sub getAndDeleteHeaders {
  my ($obj) = @_;
  my $headers = $obj->{headers} || [];
  $obj->{headers} = [];
  return @{$headers};
}
#--------------------------------------------------------------------------------------------
sub getPathInfo {
  my ($obj, %params) = @_;
  require O2::Cgi::PathInfo;
  return O2::Cgi::PathInfo::getPathInfo(%params);
}
#--------------------------------------------------------------------------------------------
sub isFile {
  my ($obj, $value) = @_;
  return ref $value eq 'O2::Cgi::File' ? 1 : 0;
}
#--------------------------------------------------------------------------------------------
sub isMultiple {
  my ($obj, $value) = @_;
  return ref $value eq 'ARRAY' ? 1 : 0;
}
#--------------------------------------------------------------------------------------------
# returns full url (including PATH_INFO, but without QUERY_STRING)
sub getRequestUri {
  my ($obj) = @_;
  return $obj->getEnv('REQUEST_URI') if $obj->getEnv('REQUEST_URI');
  
  my $port = $obj->getEnv('SERVER_PORT');
  my $url  = 'http://' . $obj->getContext()->getHostname();
  $url    .= ":$port" if $port && $port != 80;
  $url    .= $obj->getEnv('SCRIPT_NAME');
  return $url;
}
#--------------------------------------------------------------------------------------------
# XXX Should support https
sub getCurrentUrl {
  my ($obj, %params) = @_; # includePort [0], includeQueryString [1], includeServer [0]
  return $obj->{currentUrl} if $obj->{currentUrl};

  # If this is an ajax request, we must discard query string parameters in currentUrl.
  # Long GET ajax requests are turned into POST, so I think we have to do this to get some predictability.
  my $isAjax = $obj->getParam('isAjaxRequest');

  my $url = $obj->getRequestUri();
  $url    =~ s{ [?] .* }{}xms if $isAjax;
  my $queryString = $obj->getEnv('QUERY_STRING');
  $url   .= "?$queryString" if $params{includeQueryString} && $queryString && !$isAjax;
  if ($params{includeServer}) {
    # Add server part of url (and possibly the port):
    if ($url !~ m{ \A http }xms) {
      my $pre = 'http://' . $obj->getEnv('SERVER_NAME');
      if ($params{includePort}) {
        $pre .= ':' . $obj->getEnv('SERVER_PORT');
      }
      $url = $pre . $url;
    }
  }
  elsif (!$params{includeServer} && $url =~ m{ \A http }xms) {
    $url =~ s{ \A https?:// [^/]+ }{}xms; # Remove server part of url
  }
  return $obj->urlDecode($url);
}
#--------------------------------------------------------------------------------------------
sub setCurrentUrl {
  my ($obj, $url) = @_;
  my ($queryString) = $url =~ m{ [?] ([^#]*) }xms;
  if ($queryString) {
    $obj->deleteParams();
    require O2::Util::UrlMod;
    my $urlMod = O2::Util::UrlMod->new();
    my %params = $urlMod->getParams($url);
    foreach my $key (keys %params) {
      $obj->setParam($key, $params{$key});
    }
  }
  $obj->{currentUrl} = $url;
}
#--------------------------------------------------------------------------------------------
sub getRawPostContent {
  my ($obj) = @_;
  return $obj->{rawPostContent};
#  return join $/, @{ $obj->{rawPostContent} }; # $/ is the new-line character.
}
#--------------------------------------------------------------------------------------------
sub verifyRules {
  my ($obj) = @_;

  my $actualUrl    = $obj->getEnv('PATH_INFO');
  my $actualServer = $obj->getEnv('SERVER_NAME');

  my $rulesString = $obj->getParam('__rules');
  my $ruleHash    = $obj->getParam('__ruleHash');

  my $secretKey = $obj->getContext()->getSession()->get('o2FormSecretKey');
  die "Missing key in session" unless $secretKey;
  use Digest::MD5 qw(md5_hex);
  die "Invalid hash" if md5_hex($secretKey . $rulesString) ne $ruleHash;

  my ($server, $url, $ruleTitle, @inputFields) = split /¤/, $rulesString;
  if ($url ne $actualUrl || $server ne $actualServer) {
    print "$url eq $actualUrl ?? $server eq $actualServer"; return;
    die "Invalid URL";
  }

  require O2::Cgi::Rules;
  my $rules = O2::Cgi::Rules->new();
  my (@errorMessages, %checkedInputs);
  my @availableLocales = $obj->getParam('__availableLocales') || ();
  my %q = $obj->getParams();

  # Find the locales with at least one value set
  my %usedLocales;
  foreach my $key (keys %q) {
    foreach my $availableLocale (@availableLocales) {
      if ($key =~ m{ \A $availableLocale [.] }xms   ||   $key =~ m{ \A [^.]+ [.] $availableLocale [.] }xms) {
        if ($q{$key}) {
          $usedLocales{$availableLocale} = 1;
        }
      }
    }
  }

  foreach my $inputField (@inputFields) {
    my ($name, $rule, $ruleMsg) = split /\|/, $inputField;

    next if $checkedInputs{$name};
    $checkedInputs{$name} = 1;

    if (%usedLocales) {
      my $originalName = $name;
      foreach my $locale (keys %usedLocales) {
        if ($originalName =~ m{ [.] }xms) {
          my $_name = $originalName;
          $_name =~ s{ \A  ([^.]+)  [.] }{$1.$locale.}xms;
          $name  = $_name if defined $q{$_name};
        }
        else {
          my $_name = "$locale.$originalName";
          $name     = $_name if defined $q{$_name};
        }
        next if $checkedInputs{$name};
        my @errMsgs = $obj->_verifyRule($rules, $name, $rule, $ruleMsg);
        if (@errMsgs) {
          push @errorMessages, @errMsgs;
          $checkedInputs{$name} = 1;
        }
      }
    }
    else {
      my @errMsgs = $obj->_verifyRule($rules, $name, $rule, $ruleMsg);
      push @errorMessages, @errMsgs if @errMsgs;
    }
  }

  return ($ruleTitle, \@errorMessages);
}
#--------------------------------------------------------------------------------------------
sub _verifyRule {
  my ($obj, $rules, $name, $rule, $ruleMsg) = @_;
  my @errorMessages;
  if ($name =~ m{  \[\]  \z }xms) { # Array
    $name =~ s{  \[\]  \z }{}xms;
    my @values = $obj->getParam($name);
    if ($rule =~ m{ \A numChecked }xms) {
      my $numChecked = scalar @values;
      my $errorMsg = $rules->validate($rule, $numChecked) ? '' : $ruleMsg;
      $errorMsg   .= " (numChecked: $numChecked)" if $errorMsg;
      push @errorMessages, $errorMsg              if $errorMsg;
      return @errorMessages;
    }
    foreach my $value (@values) {
      my $errMsg = $rules->validate($rule, $value) ? '' : $ruleMsg;
      $errMsg   .= " ($value)"     if $errMsg && $value;
      push @errorMessages, $errMsg if $errMsg;
    }
    return @errorMessages;
  }
  my $value  = $obj->getParam($name);
  my $errMsg = $rules->validate($rule, $value) ? '' : $ruleMsg;
  $errMsg   .= " ($value)"     if $errMsg && $value;
  push @errorMessages, $errMsg if $errMsg;
  return @errorMessages;
}
#--------------------------------------------------------------------------------------------
sub doNotEncodeOutputBuffer {
  my ( $obj,$bool)=@_;
  $obj->{doNotEncodeOutputBuffer} = ($bool?1:0);
}
#--------------------------------------------------------------------------------------------
# Internal methods
#--------------------------------------------------------------------------------------------
sub _findQ {
  my ($obj) = @_;
  my ($body, $q);
  my %q;
  my $requestMethod = $obj->getEnv('REQUEST_METHOD');
  my $contentType   = $obj->getEnv('CONTENT_TYPE');
  my $queryString   = $obj->getEnv('QUERY_STRING');
  if ( $requestMethod && $requestMethod =~ m/POST|PUT|DELETE/ ) {
    if ($contentType && $contentType =~ m!multipart/form-data;\s*boundary=(.+)!) {
      my $boundary = $1;
      require O2::Cgi::FileUpload;
      return O2::Cgi::FileUpload::handleFileUpload();
    }
    else {
      $obj->{rawPostContent} = $body = join '', <STDIN>;
    }
  }
  $body = @ARGV ? join ('&', @ARGV) : $body || '';
  if ($requestMethod && $requestMethod eq 'GET') {
    $body = $queryString if defined $queryString;
  }
  $body =~ s{ o2Radio \d+ _ }{}xmsg;
  %q = $obj->_decodeQ($body);
  return \%q;
}
#--------------------------------------------------------------------------------------------
sub getRequestMethod {
  my ($obj) = @_;
  return $obj->getEnv('REQUEST_METHOD');
}
#--------------------------------------------------------------------------------------------
sub _decodeQ {
  my ($obj, $body) = @_;
  my %q;
  my $isAjaxRequest = $body =~ m{ isAjaxRequest=1 }xms   &&   $body =~ m{ xmlHttpRequestSupported=1 }xms;
  my $ajaxEncoding;
  ($ajaxEncoding) = $body =~ m{ o2AjaxEncoding= ( [\w-]+ ) }xms if $isAjaxRequest;
  for (split /&/, $body) {
    my ($name, $value) = split /=/, $_, 2;
    $value = $name, $name = 'isindex' unless defined $value;
    $value = $obj->urlDecode($value, $ajaxEncoding);
    $name  = $obj->urlDecode($name,  $ajaxEncoding);
    $value = undef unless length $value;
    if (!exists $q{$name}) {
      $q{$name} = $value;
    }
    else {
      $q{$name} = [ $q{$name} ] unless ref $q{$name};
      push @{ $q{$name} }, $value;
    }
  }
  return %q;
}
#--------------------------------------------------------------------------------------------
sub _gracefulDie {
  my ($message) = @_;
  return if $message =~ m{ \A MOD_PERL [ ] exit }xms;
  
  my ($callerId, $guiModule, @callerContent) = (0);
  while (my ($file, $line, $moduleAndMethod) = (caller $callerId++)[1..3]) {
    next if $file eq '-e'  ||  $line == 0  ||  ($file =~ m{ mod_perl[.]pm \z }xms && $moduleAndMethod eq '(eval)');
    
    if ($moduleAndMethod eq '(eval)' && $file !~ m{ mod_perl[.]pm \z }xms) { # The exception was caught
      $CGI->{_stackTrace} = $CGI->getContext()->getConsole()->getStackTrace();
      return;
    }
    
    if (!$guiModule) {
      $guiModule = $moduleAndMethod if $moduleAndMethod =~ m{ ::Gui:: }xms;
      if ($guiModule) {
        my @parts = split /::/, $guiModule;
        pop @parts; # Popping off method
        $guiModule = join '::', @parts;
      }
    }
    push @callerContent, "$moduleAndMethod, line $line in $file";
  }
  
  CORE::die($message) unless $CGI;
  $CGI->_untieStdOut();
  
  my $dontLog = $message =~ m{ \A DONT_LOG: (.*) }xms;
  $message =~ s{ \A DONT_LOG: }{}xms if $dontLog;
  $message =~ s{ at [^\s]+ line \d+[.]\s*\z}{}ms;
  my %params = (
    dontLog    => $dontLog,
    stackTrace => [ reverse @callerContent ],
  );
  require O2::Cgi::FatalsToBrowser;
  if ($CGI->getParam('isAjaxRequest')) {
    print STDOUT O2::Cgi::FatalsToBrowser::ajax($message, %params);
  }
  else {
    print STDOUT O2::Cgi::FatalsToBrowser::html($message, %params);
  }
  return if $CGI->{isModPerl};
  
  CORE::die($message);
  $CGI->exit();
}
#--------------------------------------------------------------------------------------------
sub exit {
  my ($obj) = @_;
  my $session = $obj->getContext()->getSession();
  $session->save() if $session->{needsToBeSaved};
  exit;
}
#--------------------------------------------------------------------------------------------
package O2::Cgi::TieOutput; # Package for handling tying of STDOUT
#--------------------------------------------------------------------------------------------
sub TIEHANDLE {
  my ($package, $obj) = @_;
  return bless { cgiObj => $obj }, $package;
}
#--------------------------------------------------------------------------------------------
sub PRINT {
  my ($handleObj, @params) = @_;
  my $content = '';
  if (@params) {
    my $joiner = $, || '';
    $content .= join $joiner, map { ref $_ eq 'SCALAR' ? ${$_} : $_ } @params;
    $content .= $\ if $\;
  }
  my $cgi = $handleObj->{cgiObj};
  $cgi->{content} .= $content;
  $cgi->flush() if $cgi->{autoflush};
  return;
}
#--------------------------------------------------------------------------------------------
sub PRINTF {
  my ($handleObj, $format, @params) = @_;
  $handleObj->{cgiObj}->{content} .= sprintf ($format, @params) . $\;
  return;
}
#--------------------------------------------------------------------------------------------
sub BINMODE {
  my ($handleObj) = @_;
  $handleObj->{cgiObj}->{binMode} = 1;
  return;
}
#--------------------------------------------------------------------------------------------
1;
