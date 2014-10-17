package O2::Template::Taglibs::Html::Ajax;

use strict;

use base 'O2::Template::Taglibs::Html::Form';

use O2 qw($context);

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my %methods = (
    ajaxScheduleCalls => '',
    ajaxCall          => '',
    ajaxLink          => '',
    button            => '',
    ajaxForm          => 'postfix',
    input             => 'postfix',
    select            => 'postfix',
  );
  
  my $obj = bless { parser => $params{parser} }, $package;
  
  my $formTaglib = $obj->{parser}->getTaglibByName('Html::Form', %params);
  $formTaglib->addJsFile(  file => 'o2escape' );
  $formTaglib->addJsFile(  file => 'ajax'     );
  $formTaglib->addCssFile( file => 'ajax'     );
  
  $formTaglib->addJs(
    where   => 'onLoad',
    content => 'o2.ajax.addHiddenIframe();',
  );
  
  $obj->{scheduledCallId} = 0;
  return ($obj, %methods);
}
#----------------------------------------------------
sub button {
  my ($obj, %params) = @_;
  my $onClick = '';

  if ($params{ajaxEvent} && lc $params{ajaxEvent} eq 'onclick') {
    $params{onClick} .= ";" if $params{onClick} && $params{onClick} !~ m{ ; \z }xms;
    $params{onClick} .= $obj->_getAjaxJsCode(\%params) . ' return false;';
  }
  return $obj->SUPER::button(%params);
}
#----------------------------------------------------
sub ajaxForm {
  my ($obj, %params) = @_;
  my $ajaxJsCode;
  $ajaxJsCode = $obj->_getAjaxJsCode(\%params, 1);
  $ajaxJsCode =~ s{ \s \s+ }{ }xmsg;
  $params{name}    ||= 'form' . int (1_000_000_000 * rand);
  $params{onSubmit} .= "; if (o2.rules.checkForm(this)) { $ajaxJsCode } return false;";
  return $obj->SUPER::form(%params, isAjaxForm => 1);
}
#----------------------------------------------------
sub ajaxCall { # Perform an imidiate call to a serverside function trough AJAX
  my ($obj, %params) = @_;
  my $ajaxJsCode;
  $ajaxJsCode = $obj->_getAjaxJsCode(\%params, 0);
  $ajaxJsCode =~ s{ \s \s+ }{ }xmsg;
  my $html = $obj->addJs(
    where   => 'post',
    content => $ajaxJsCode,
  );
  return $html;
}
#----------------------------------------------------
sub ajaxLink {
  my ($obj, %params) = @_;
  $params{target} = $params{id} ||= 'ajaxLink_' . $obj->_getRandomId() if $params{target} && $params{target} eq 'this';
  
  my $onClick = $obj->_getAjaxJsCode(\%params, 0);
  $onClick    =~ s{ \s \s+ }{ }xmsg;
  if ( $params{type}  &&  ($params{type} eq 'image' || $params{type} eq 'button') ) {
    $params{onClick} .= "; $onClick";
  }
  else {
    $params{onClick} .= "; $onClick; if (window.event) { event.cancelBubble = true; } return false;";
    $params{href}     = "#";
  }
  
  return $obj->link(%params);
}
#----------------------------------------------------
sub input {
  my ($obj, %params) = @_;
  my $ajaxEvent = delete $params{ajaxEvent};
  if ($ajaxEvent) {
    my $ajaxJsCode = $obj->_getAjaxJsCode(\%params);
    $params{$ajaxEvent} = $ajaxJsCode;
  }
  return $obj->SUPER::input(%params);
}
#----------------------------------------------------
sub select {
  my ($obj, %params) = @_;
  my $ajaxEvent = delete $params{ajaxEvent};
  if ($ajaxEvent) {
    my $ajaxJsCode = $obj->_getAjaxJsCode(\%params);
    $params{$ajaxEvent} = $ajaxJsCode;
  }
  return $obj->SUPER::select(%params);
}
#----------------------------------------------------
sub ajaxScheduleCalls {
  my ($obj, %params) = @_;
  my $jsFunctionName = 'ajaxScheduledCall' . ++$obj->{scheduledCallId};
  $params{ajaxId} = 'ajaxCallId'.$obj->{scheduledCallId};
  my $ajaxJsCode = $obj->_getAjaxJsCode(\%params);
  $ajaxJsCode    =~ s{ \s \s+ }{ }xmsg;

  # Define a recursive function:
  $obj->addJs(
    where   => 'pre',
    content => 'function ' . $jsFunctionName . '() { ' . $ajaxJsCode . ' setTimeout("' . $jsFunctionName. '();", ' . 1000 * $params{interval} . '); }',
  );
  # Call the function:
  $obj->addJs(
    where   => 'onLoad',
    content => $jsFunctionName . '();', # setTimeout("' . $jsFunctionName . '();", ' . 1000 * $params{interval} . ');',
  );
  return '';
}
#----------------------------------------------------
sub _getAjaxJsCode {
  my ($obj, $params, $isFormTag) = @_;
  my $jsCode = '';
  my $url = $params->{serverScript} || '';
  if (!$url) {
    require O2::Util::UrlMod;
    my $content = delete $params->{content};
    my $urlMod = $context->getSingleton('O2::Util::UrlMod');
    $url = $urlMod->urlMod( %{$params} );
    $urlMod->deleteUrlModParams($params);
    $params->{content} = $content;
  }
  # Remove ajax params from URL
  foreach my $param (qw(_target _where _html onSuccess onError onTimeout handler errorHandler ignoreMissingTarget ajaxId debug isAjaxRequest xmlHttpRequestSupported o2AjaxEncoding)) {
    $url =~ s{ \b $param=[^&]+ &? }{}xms;
  }
  
  my $_params = "'";
  my $isAllParams = 0;
  $params->{formParams} = '' unless length $params->{formParams};
  if (lc $params->{formParams} eq 'all') {
    delete $params->{formParams};
    my $formElm = $isFormTag ? "this" : "o2.getCurrentForm(this)"; # "this.form";
    $_params = "o2.getAllFormParamsAsQueryString($formElm)";
    $isAllParams = 1;
  }
  my @formParams = split /,\s*/, $params->{formParams};
  if ($isFormTag) {
    $params->{ajaxAction} = $url;
    $_params = "o2.getAllFormParamsAsQueryString(this)";
  }
  else {
    my $cnt = 0;
    foreach my $formParam (@formParams) {
      $cnt++;
      $_params .= "$formParam=' + o2.getEscapedInputValue(o2.getCurrentForm(this), '$formParam') + '&";
    }
    $_params  = substr ($_params, 0, -5) if $cnt  > 0;
    $_params .= "'"                      if $cnt == 0 && !$isAllParams;
  }

  foreach my $key (qw(onSuccess onError onTimeout)) {
    $params->{$key} = $obj->_jsEscape( $params->{$key} );
  }
  
  if ($params->{confirmMsg}) {
    # We have to make sure this value doesn't break JS
    require O2::Javascript::Data;
    my $confirmMsg = O2::Javascript::Data->new()->escapeForSingleQuotedString( $params->{confirmMsg} );
    $jsCode       .= "if (!confirm('$confirmMsg')) { return false; }\n";
  }
  
  $jsCode .= "o2.ajax.call({
  'serverScript' : '$url',
  'params'       : $_params,\n";
  foreach my $param (qw(target where onSuccess onError onTimeout handler errorHandler ajaxCallId debug ignoreMissingTarget method)) {
    $jsCode .= qq{$param : '$params->{$param}',\n} if $params->{$param};
  }
  $jsCode = substr $jsCode, 0, -2;
  $jsCode .= "});";
  
  foreach my $param (qw(confirmMsg target where onSuccess onError onTimeout handler errorHandler debug params formParams serverScript ajaxId ignoreMissingTarget method)) {
    delete $params->{$param};
  }
  return $jsCode;
}
#----------------------------------------------------
1;
