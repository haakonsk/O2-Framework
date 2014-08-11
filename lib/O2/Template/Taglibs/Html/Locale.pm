package O2::Template::Taglibs::Html::Locale;

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context $config);

#----------------------------------------------------
sub register {
  my ($package, %params) = @_;

  my ($obj, %methods) = $package->SUPER::register(%params);
  %methods = (
    %methods,
    localeSwitch => 'postfix',
  );
  return ($obj, %methods);
}
#----------------------------------------------------
sub localeSwitch {
  my ($obj, %params) = @_;
  my $object = $obj->{parser}->findVar( delete $params{object} );
  
  my @availableLocales = $object  ?  $object->getAvailableLocales()  :  @{ $config->get('o2.locales') };
  my $currentLocale    = $object  ?  $object->getCurrentLocale()     :  $context->getLocaleCode();
  
  my $lang = $obj->{parser}->findVar('$lang');
  my $type = delete $params{type};
  my $divClass   = 'localeSwitch';
  $divClass     .= ' ' . delete $params{class} if $params{class};
  my $isVertical = lc (delete $params{orientation}) eq 'vertical' ? 1 : 0;
  my $localesHtml = '';
  
  my @locales = delete $params{useBackendLocales}  ?  @{ $config->get('o2.backendLocales') }  :  @availableLocales;
  foreach my $locale (@locales) {
    my $class = '';
    if ($locale eq $currentLocale) {
      $class = 'class="selected"';
    }
    my $onClick = $params{onClick};
    if ($onClick !~ m{ \" }xms) {
      $onClick =~ s{ \' }{\"}xmsg;
    }
    else {
      $onClick =~ s{ \' }{&quot;}xmsg;
    }
    my $url = $context->getSingleton('O2::Util::UrlMod')->urlMod(
      setDispatcherPath => $context->isBackend() ? 'o2cms' : 'o2',
      setClass          => 'User-Locale',
      setMethod         => 'setLocale',
      setParams         => "locale=$locale",
    );
    if ($params{onSuccess}) {
      $obj->{parser}->registerTaglib('Html::Ajax');
      my $onSuccess = $params{onSuccess};
      $onSuccess    =~ s{ \' }{\\\"}xmsg;
      $localesHtml .= qq[  <a href='#' onClick='$onClick; o2.ajax.call( { "serverScript" : "$url", "onSuccess" : "$onSuccess", method : "post" } );' $class>];
    }
    else {
      $url .= '&amp;url=' . $context->getEnv('REQUEST_URI');
      $onClick = "onClick='$onClick'";
      $localesHtml .= "  <a href=\"$url\" $class $onClick>";
    }
    if (lc $type eq 'flag') {
      my ($country) = $locale =~ m{ \A \w\w_(\w\w) \z }xms;
      $country = lc $country;
      $localesHtml .= "<img src=\"/images/locale/flag_16x11/$country.gif\" />";
    }
    else {
      $localesHtml .= $lang->getString("locale.languages.$locale");
    }
    $localesHtml .= '</a>';
    $localesHtml .= '<br />' if $isVertical;
    $localesHtml .= "\n";
  }
  delete $params{onSuccess};
  delete $params{onClick};
  $obj->addCssFile( file => 'locale' );
  return "<div class=\"$divClass\" " . $obj->_packTagAttribs(%params) . ">
$localesHtml</div>";
}
#----------------------------------------------------
1;
