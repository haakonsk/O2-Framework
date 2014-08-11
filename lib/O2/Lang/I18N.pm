package O2::Lang::I18N;

# Provides support for I18N resource files
# I'm using the O2 config.pm object as my RESOURCE handler
# But I really should implement XLIFF standard or something similar,
# cause this will allows us to send the XML files to translators for translating.
# It is also heaps of Open source software to edit XLIFF files 
#
# NOTE: this is the base implementation, we need to create own tablibs for templates handling  
# The I18N will outline the API and when we change the underlaying resource implementation
# all overlaying components should be able work transparently.

use strict;

use constant DEBUG => 0;
use O2 qw($context);

#------------------------------------------------------------------
sub new {
  my ($package, %init) = @_;
  my $obj = bless \%init, $package;
  $obj->{defaultLocale}    ||= 'en';
  $obj->{locale}           ||= $context->getLocaleCode() || $obj->getLocale();
  $obj->{resourcePathPrefix} = '';
  return $obj;
}
#------------------------------------------------------------------
sub getString {
  my ($obj, $keyId, %params) = @_;
  my $locale = $params{locale};
  $locale  ||= $context->getLocaleCode(); # If context->{localeCode} has been updated after the constructor was called, we probably want to use that localeCode.
  $locale  ||= $obj->getLocale();
  if (!$obj->{$locale}) {
    require O2::Config;
    $obj->{$locale} = O2::Config->new( split /;/, $obj->{resourcePath} );
  }
  
  my $string = $obj->_getConfStringFromKey($keyId, $locale, %params);
  
  # Parse variables in the string
  if ($string) {
    $string =~ s{ \$   (\w+)    }{ exists $params{$1} ? $obj->encode( $params{$1} ) : $obj->getErrorString('$'.$1) }xge;
    $string =~ s{ \$\{ (\w+) \} }{ exists $params{$1} ? $obj->encode( $params{$1} ) : $obj->getErrorString('$'.$1) }xge;
  }
  return $string               if defined $string;
  return $params{missingValue} if exists $params{missingValue}; # custom return value for missing text
  
  my $warnMsg = "Missing language key: $keyId [$locale]";
  $warnMsg   .= "<br>\nResource path prefix is $obj->{resourcePathPrefix}" if $obj->{resourcePathPrefix} && $keyId !~ m{$obj->{resourcePathPrefix}}xms;
  warning $warnMsg;
  
  return $obj->_getErrorLink($keyId, $locale); # return error message (with link)
}
#------------------------------------------------------------------
# error message for missing texts (will display a link to locale editor)
sub _getErrorLink {
  my ($obj, $keyId, $locale) = @_;
  return "$keyId [$locale]";
  return "<a style=\"color: red;\" href=\"#\" onClick=\"var newWin = window.open('/o2cms/System-Language/editKey?keyId=$keyId','localeKeyEdit','width=400,height=300,resizable=1'); newWin.focus(); return false;\">$keyId [$locale]</a>";
}
#------------------------------------------------------------------
sub keyExists {
  my ($obj, $key) = @_;
  my $locale = $obj->{locale} || $obj->{defaultLocale};
  if (!$obj->{$locale}) {
    require O2::Config;
    $obj->{$locale} = O2::Config->new( $context, split /;/, $obj->{resourcePath} );
  }
  return  $obj->_getConfStringFromKey($key, $locale, useOnlyGivenLocale => 1)  ?  1  :  0;
}
#------------------------------------------------------------------
sub _getConfStringFromKey {
  my ($obj, $keyId, $locale, %params) = @_;
  my ($lang, $terr) = split /_/, $locale; # eg. en_US

  my $string;

  debug "GET: $keyId $locale";
  debug "resourcePath: $obj->{resourcePath}";
  debug "resourcePathPrefix: $obj->{resourcePathPrefix}";

  if ($obj->{resourcePathPrefix}) {
    debug "GET: $locale.$obj->{resourcePathPrefix}.$keyId-><b>" . ($string || 'not found') . '</b>';
    $string = $obj->{$locale}->get("$locale.$obj->{resourcePathPrefix}.$keyId");
  }
  
  $string ||= $obj->{$locale}->get("$locale.$keyId");
  debug "GET: $locale.$keyId-><b>" . ($string || 'not found') . '</b>' unless $string;
  # eg. en
  return $string if $params{useOnlyGivenLocale};

  $string ||= $obj->{$locale}->get("$lang.$obj->{resourcePathPrefix}.$keyId")                   if             $obj->{resourcePathPrefix};
  debug "GET: $lang.$obj->{resourcePathPrefix}.$keyId-><b>" . ($string || 'not found') . '</b>' if !$string && $obj->{resourcePathPrefix};
  
  $string ||= $obj->{$locale}->get("$lang.$keyId");
  debug "GET: $lang.$keyId-><b>" . ($string || 'not found') . '</b>' unless $string;

  $string ||= $obj->{$locale}->get("$obj->{defaultLocale}.$obj->{resourcePathPrefix}.$keyId")                   if             $obj->{resourcePathPrefix};
  debug "GET: $obj->{defaultLocale}.$obj->{resourcePathPrefix}.$keyId-><b>" . ($string || 'not found') . '</b>' if !$string && $obj->{resourcePathPrefix};

  # default locale
  $string ||= $obj->{$locale}->get("$obj->{defaultLocale}.$keyId");
  debug "GET: $obj->{defaultLocale}.$keyId-><b>" . ($string || 'not found') . '</b>' unless $string;
  return $string;
}
#------------------------------------------------------------------
# Same as getString
sub getArrayRef {
  my ($obj, $keyId, %params) = @_;
  return $obj->getString($keyId, %params);
}
#------------------------------------------------------------------
sub getLocale {
  my ($obj) = @_;
  return $obj->{locale} || $obj->{defaultLocale};
}
#------------------------------------------------------------------
sub setLocale {
  my ($obj, $locale) = @_;
  $obj->{locale} = $locale;
  return;
}
#------------------------------------------------------------------
sub setResourcePath {
  my ($obj, $resPath) = @_;
  debug "setResourcePath: $resPath";
  $obj->{resourcePathPrefix} = $resPath;
  return;
}
#------------------------------------------------------------------
sub getErrorString {
  my ($obj, $errString) = @_;
  return "<font color=red>$errString</font>";
}
#------------------------------------------------------------------
sub getClassname {
  my ($obj, $className) = @_;
  return $obj->getString("o2.className.$className");
}
#------------------------------------------------------------------
sub encode {
  my ($obj, $str) = @_;
  $str =~ s{ &  }{&amp;}xms;
  $str =~ s{ <  }{&lt;}xms;
  $str =~ s{ >  }{&gt;}xms;
  $str =~ s{ \" }{&quot;}xms;
  $str =~ s{ \' }{&#39;}xms;
  $str =~ s{ \$ }{&#36;}xms;
  return $str;
}
#------------------------------------------------------------------
1;
