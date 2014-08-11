package O2::Util::UrlMod;

use strict;

use O2 qw($context $cgi);

#-----------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  return bless \%params, $package;
}
#-----------------------------------------------------------------------------
sub hasUrlModParams {
  my ($obj, %params) = @_;
  foreach my $urlModParam ($obj->_getUrlModParams()) {
    return 1 if $params{$urlModParam};
  }
  return 0;
}
#-----------------------------------------------------------------------------
sub getQueryString {
  my ($obj, $url) = @_;
  $url ||= $obj->getCurrentUrl();
  my ($queryString) = $url =~ m{ [?] ([^#]*) }xms;
  return $queryString;
}
#-----------------------------------------------------------------------------
sub getParam {
  my ($obj, $param, $url) = @_;
  my $queryString = $obj->getQueryString($url);
  return $obj->_queryStringGetParam($queryString, $param);
}
#-----------------------------------------------------------------------------
sub getParams {
  my ($obj, $url) = @_;
  my $queryString = $obj->getQueryString($url);
  return $obj->_parseParams($queryString);
}
#-----------------------------------------------------------------------------
sub getCurrentUrl {
  my ($obj) = @_;
  return $cgi->getCurrentUrl();
}
#-----------------------------------------------------------------------------
sub getDispatcherPath {
  my ($obj, $url) = @_;
  return { $obj->_splitO2Url($url) }->{dispatcherPath};
}
#-----------------------------------------------------------------------------
sub getClass {
  my ($obj, $url) = @_;
  return { $obj->_splitO2Url($url) }->{class};
}
#-----------------------------------------------------------------------------
sub getMethod {
  my ($obj, $url) = @_;
  return { $obj->_splitO2Url($url) }->{method} || 'init';
}
#-----------------------------------------------------------------------------
sub getHash {
  my ($obj, $url) = @_;
  return { $obj->_splitO2Url($url) }->{hash};
}
#-----------------------------------------------------------------------------
sub _splitO2Url {
  my ($obj, $url) = @_;
  $url ||= $obj->getCurrentUrl();

  # Gui module url:
  if (my ($dispatcherPath, $class, $method, $queryString, $hash)
        = $url =~ m{ \A
                       / (\w+)                 # dispatcherPath
                       / ([-\w:]+)             # module
                       (?: / ([^?#]*)   )?     # method       (optional)
                       (?:  [?] ([^#]*) )?     # query string (optional)
                       (?:  [#] (.*)    )? \z  # hash part    (optional)
                     }xms) {
    return (
      dispatcherPath => $dispatcherPath,
      class          => $class,
      method         => $method,
      queryString    => $queryString,
      hash           => $hash,
    );
  }

  # Other url:
  my ($script, $queryString, $hash)
    = $url =~ m{ \A
                    ( / [^?]+ )             # script
                    (?:  [?] ([^#]*) )?     # query string (optional)
                    (?:  [#] (.*)    )? \z  # hash part    (optional)
             }xms;
  return (
    script      => $script,
    queryString => $queryString,
    hash        => $hash,
  );
}
#-----------------------------------------------------------------------------
sub urlMod {
  my ($obj, %params) = @_;
  die "Can't call urlMod as a package method anymore" unless ref $obj;
  
  my $currentUrl = $obj->getCurrentUrl();
  if ($params{setDispatcherPath} || $params{setClass} || $params{setMethod}) {
    my %urlParts = $obj->_splitO2Url();
    return $obj->_buildO2Url($urlParts{dispatcherPath}, $urlParts{class}, $urlParts{method}, $urlParts{queryString}, $urlParts{hash}, %params) if $urlParts{class};
    return $obj->_buildO2Url('o2cms', undef, undef, undef, undef, %params)                                                                     if $currentUrl =~ m{ \A / o2cms /? \z }xms;
    die 'Missing setDispatcherPath attribute' unless $params{setDispatcherPath};
    return $obj->_buildO2Url($params{setDispatcherPath}, undef, undef, $context->getEnv('QUERY_STRING'), $urlParts{hash}, %params);
  }
  # A regular url (not o2-url)
  my ($baseUrl, $queryString, $hash)
    = $currentUrl =~ m{
                        \A
                        ([^?#]*)
                        (?:  [?] ([^#]*) )?     # query string (optional)
                        (?:  [#] (.*)    )? \z  # hash part    (optional)
                        \z
                    }xms;
  $queryString = $obj->_updateQueryString( $queryString, %params );
  $hash        = $obj->_updateHash(        $hash,        %params );
  my $newUrl = $baseUrl;
  $newUrl   .= "?$queryString" if $queryString;
  $newUrl   .= "#$hash"        if $hash;
  $newUrl    = $obj->_getProtocol(%params) . '://' . $context->getHostname() . $newUrl if $params{absoluteURL} || $params{setSecure};
  return $newUrl;
}
#-----------------------------------------------------------------------------
sub _buildO2Url {
  my ($obj, $preSlash, $module, $method, $queryString, $hash, %params) = @_;
  $preSlash = $params{setDispatcherPath} || $preSlash;
  $module   = $params{setClass}          || $module;
  $module   =~ s{ :: }{-}xmsg;
  $method   = $params{setMethod}         || $method;
  $queryString = $obj->_updateQueryString( $queryString, %params );
  $hash        = $obj->_updateHash(        $hash,        %params );
  my $newUrl = "/$preSlash/$module/$method";
  $newUrl   .= "?$queryString" if $queryString;
  $newUrl   .= "#$hash"        if $hash;
  $newUrl    = $obj->_getProtocol(%params) . '://' . $context->getHostname() . $newUrl if $params{absoluteURL} || $params{setSecure};
  return $newUrl;
}
#-----------------------------------------------------------------------------
sub _updateQueryString {
  my ($obj, $queryString, %params) = @_;
  return '' if $params{removeParams};
  $queryString = $obj->_updateQueryStringFromRemoveParam( $queryString, $params{removeParam} ) if $params{removeParam};
  $queryString = $obj->_updateQueryStringFromSetParams(                 $params{setParams}   ) if exists $params{setParams};
  # It was actually possible to set more than 1 parameter with setParam and appendParam, so we must continue to support that..
  $queryString = $obj->_updateQueryStringFromSetParam(    $queryString, $params{setParam}    ) if $params{setParam};
  $queryString = $obj->_updateQueryStringFromAppendParam( $queryString, $params{appendParam} ) if $params{appendParam};
  $queryString = $obj->_updateQueryStringFromToggleParam( $queryString, $params{toggleParam} ) if $params{toggleParam};
  $queryString =~ s{ \A & }{}xms if length $queryString;
  return $queryString;
}
#-----------------------------------------------------------------------------
sub _updateHash {
  my ($obj, $hash, %params) = @_;
  return $params{setHash} if $params{setHash};
  return ''               if $params{removeHash};
  return $hash;
}
#-----------------------------------------------------------------------------
sub _parseParams {
  my ($obj, $params) = @_;
  my @params = split /&(?:amp;)?/, $params;
  my %params;
  foreach (@params) {
    my ($key, $value) = split /=/, $_, 2;
    if(exists($params{$key})) {
      if( ref $params{$key} ne 'ARRAY' ) {
        $params{$key} = [$params{$key}];
      }
      push @{$params{$key}}, $value;
    }
    else {
      $params{$key} = $value;
    }
  }
  return %params;
}
#-----------------------------------------------------------------------------
sub _replaceQueryStringParam {
  my ($obj, $queryString, $param, $value) = @_;
  if ($obj->_queryStringParamExists($queryString, $param)) {
    $queryString =~ s{
                      $param=.*?
                      ( &(?:amp;)? | \z ) # Either ampersand or end of (query) string
                      }{$param=$value$1}xms;
    return $queryString;
  }
  return $obj->_appendQueryStringParam($queryString, $param, $value);
}
#-----------------------------------------------------------------------------
sub _appendQueryStringParam {
  my ($obj, $queryString, $param, $value) = @_;
  $value = '' unless length $value;
  $queryString .= '&' if $queryString;
  $queryString .= "$param=$value";
  return $queryString;
}
#-----------------------------------------------------------------------------
sub _queryStringParamExists {
  my ($obj, $queryString, $param) = @_;
  return 0 unless $queryString;
  if ($queryString =~ m{
                         (?: \A | &(?:amp;)? ) # Start of query string, or directly after an ampersand
                         $param=               # The name of the parameter followed by an equals sign
                         (.*?)                 # The value we want to capture
                         (?: &(?:amp;)? | \z ) # An ampersand or end of (query) string
                     }xms) {
    return 1;
  };
  return 0;
}
#-----------------------------------------------------------------------------
sub _queryStringGetParam {
  my ($obj, $queryString, $param) = @_;
  if (my ($value) = $queryString =~ m{
                                      (?: \A | &(?:amp;)? ) # Start of query string, or directly after an ampersand
                                      $param=               # The name of the parameter followed by an equals sign
                                      (.*?)                 # The value we want to capture
                                      (?: &(?:amp;)? | \z ) # An ampersand or end of (query) string
                                    }xms) {
    return $value;
  }
  return;
}
#-----------------------------------------------------------------------------
sub _deleteQueryStringParam {
  my ($obj, $queryString, $param) = @_;
  $queryString =~ s{
                    (?: \A | &(?:amp;)? ) # Start of query string, or directly after an ampersand
                    $param=               # The name of the parameter followed by an equals sign
                    [^&]*                 # Anything except ampersand
                  }{}xmsg;
  return $queryString;
}
#-----------------------------------------------------------------------------
sub _getProtocol {
  my ($obj, %params) = @_;
  
  return 'https' if $params{setSecure};
  return 'http'  if exists $params{setSecure} && !$params{setSecure};
  
  my $currentProtocol = lc $context->getEnv('SERVER_PROTOCOL');
  $currentProtocol =~ s{ / .* \z }{}xms;
  return $currentProtocol;
}
#-----------------------------------------------------------------------------
sub _updateQueryStringFromSetParams {
  my ($obj, $setParams) = @_;
  return $setParams if ref $setParams ne 'HASH';
  
  my $queryString = '';
  while (my ($key, $value) = each %{$setParams}) {
    $queryString .= sprintf "$key=%s&", $cgi->urlEncode($value);
  }
  $queryString = substr $queryString, 0, -1;
  return $queryString;
}
#-----------------------------------------------------------------------------
sub _updateQueryStringFromRemoveParam {
  my ($obj, $queryString, $removeParam) = @_;
  my @removeParams = split /,/, $removeParam;
  foreach my $param (@removeParams) {
    $queryString = $obj->_deleteQueryStringParam($queryString, $param);
  }
  return $queryString;
}
#-----------------------------------------------------------------------------
sub _updateQueryStringFromSetParam {
  my ($obj, $queryString, $setParam) = @_;
  my @params = split /,|&(?:amp;)?/, $setParam;
  foreach my $param (@params) {
    my ($key, $value) = split /=/, $param, 2;
    $queryString = $obj->_replaceQueryStringParam($queryString, $key, $value);
  }
  return $queryString;
}
#-----------------------------------------------------------------------------
sub _updateQueryStringFromAppendParam {
  my ($obj, $queryString, $setParam) = @_;
  my @params = split /,|&(?:amp;)?/, $setParam;
  foreach my $param (@params) {
    my ($key, $value) = split /=/, $param, 2;
    $queryString = $obj->_appendQueryStringParam($queryString, $key, $value);
  }
  return $queryString;
}
#-----------------------------------------------------------------------------
# Example: toggleParam => a=1|2|3,b=4|5|6
sub _updateQueryStringFromToggleParam {
  my ($obj, $queryString, $toggleParams) = @_;
  my @toggles = split /,\s*/, $toggleParams;
  foreach my $toggle (@toggles) {
    my ($key, $values) = split /=/, $toggle, 2;
    my @values = split /[|]/, $values;
    my %hashValues;
    my $oldValue = $obj->_queryStringGetParam($queryString, $key);
    if ($oldValue) {
      # arrange so e.g when toggle values is 0|1|2, toggle sequence should be like this 
      # value : toggle to value
      #  0 : 1
      #  1 : 2
      #  2 : 0
      my $value;
      my $firstToggleValue = $values[0];
      for my $i (0 .. scalar(@values)-1) {
        $value = $values[$i+1] if $oldValue eq $values[$i] && $i < scalar(@values);
      }
      $value = $firstToggleValue unless length($value);
      $queryString = $obj->_replaceQueryStringParam($queryString, $key, $value);
    }
    else {
      $queryString = $obj->_replaceQueryStringParam($queryString, $key, $values[0]);
    }
  }
  return $queryString;
}
#-----------------------------------------------------------------------------
sub deleteUrlModParams {
  my ($obj, $params) = @_;
  foreach my $param ($obj->_getUrlModParams()) {
    delete $params->{$param};
  }
}
#-----------------------------------------------------------------------------
sub _getUrlModParams {
  my ($obj) = @_;
  return qw(setDispatcherPath setClass setMethod setParams setParam removeParams removeParam appendParam toggleParam absoluteURL setSecure);
}
#-----------------------------------------------------------------------------
1;
