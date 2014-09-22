package O2::Template::Taglibs::Html::Form;

# IMPORTANT:
# $obj isn't necessarily the same for all input fields in a request, but $obj->{parser} is,
# so use $obj->{parser}->setProperty('name', $value) instead of $obj->{name} = $value.

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context $config $session);

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  
  my ($obj, %methods) = $package->SUPER::register(%params);
  
  %methods = (
    %methods,
    form                         => 'postfix',
    dateSelect                   => 'postfix',
    fileUpload                   => '',
    input                        => 'postfix',
    inputCounter                 => '',
    textarea                     => 'postfix',
    button                       => '',
    select                       => 'postfix',
    radioGroup                   => 'postfix',
    checkboxGroup                => 'postfix',
    formTable                    => 'postfix',
    multilingualController       => 'postfix',
    setCurrentMultilingualObject => 'postfix',
    comboBox                     => 'postfix',
    multiInput                   => 'postfix',
  );
  return ($obj, %methods);
}
#----------------------------------------------------
sub multilingualController {
  my ($obj, %params) = @_;
  my $object = $obj->{parser}->findVar( $params{object} );
  
  my $type = delete $params{type} || 'text';
  my @locales;

  my $lang = $obj->{parser}->findVar('$lang');  

  my @usedLocales  = $object ? $object->getUsedLocales() : ();
  my %localesInUse = map { $_ => 1 } @usedLocales;
  
  $obj->{parser}->setProperty( currentMultilingualObject => $object );
  foreach my $localeCode ( $object ? $object->getAvailableLocales() : @{ $config->get('o2.locales') } ) {
    my ($country) = $localeCode =~ m{ \A \w\w_(\w\w) \z }xms;
    $country      = lc $country;
    my $onClick;
    $onClick = qq[o2.ajax.sCall({ setDispatcherPath : "o2cms", setClass : "User-Locale", setMethod : "setFrontendLocaleCode", setParams : "localeCode=$localeCode", method : "post" });] if $context->isBackend();
    if ($params{reloadPage}) {
      $onClick = "$onClick o2.multilingualController.onSwitchReloadPage('$localeCode'); return false;";
      if ($params{reloadConfirmMsg}) {
        my $msg = $obj->{parser}->findVar( $params{reloadConfirmMsg} );
        $msg    =~ s{ \' }{\\\'}xmsg;
        $onClick = "if (confirm('$msg')) { $onClick } return false;";
      }
    }
    push @locales, {
      localeCode => $localeCode,
      selected   => $object && $object->getCurrentLocale() eq $localeCode,
      inUse      => $localesInUse{$localeCode} ? 1 : 0,
      name       => $lang->getString("o2.localeNames.$localeCode"),
      type       => $type,
      flagSrc    => "/images/locale/flag_16x11/$country.gif",
      onClick    => $onClick,
    };
    my $oldHtml = $obj->{parser}->getProperty('availableLocalesHtml') || '';
    $obj->{parser}->setProperty(
      'availableLocalesHtml',
      $oldHtml . $obj->input(
        type    => 'hidden',
        name    => '__availableLocales[]',
        value   => $localeCode,
        rule    => 'regex:/^\w\w_\w\w$/',
        ruleMsg => 'Error in available locales (hidden field)', # XXX Use language variable
      ) . "\n"
    );
  }
  
  my $controllerJs   = $context->getSingleton('O2::Javascript::Data')->dump(\@locales);
  my $onSwitchPreJs  = delete $params{onSwitchPre}  || '';
  my $onSwitchPostJs = delete $params{onSwitchPost} || '';
  $onSwitchPreJs     =~ s{ \' }{\\\'}xmsg;
  $onSwitchPostJs    =~ s{ \' }{\\\'}xmsg;

  $obj->addJsFile(file => 'multilingualController');
  $obj->addJs(
    where   => 'post',
    content => "var o2LocalesAvailable = $controllerJs ; \n var onSwitchPreJs = '$onSwitchPreJs' ; \n var onSwitchPostJs = '$onSwitchPostJs' ;",
  );
  my $localeCode;
  if ($context->isFrontend()) {
    $localeCode = $object ? $object->getCurrentLocale() : $config->get('o2.defaultLocale');
  }
  else {
    my $user = $context->getUser();
    $localeCode = $user->getAttribute('frontendLocaleCode') || $object->getCurrentLocale();
    if (!$user->getAttribute('frontendLocaleCode') && $context->isBackend()) {
      $user->setAttribute('frontendLocaleCode', $localeCode);
      $user->save();
    }
  }
  $obj->addJs(
    where    => 'onLoad',
    priority => 7,
    content  => "o2.multilingualController.switchToLocale( '$localeCode', onSwitchPreJs, onSwitchPostJs );\n",
  );
  $obj->addCssFile( file => 'multilingualController' );
  return "<div id='o2MultilingualControllerDiv' class='o2MultilingualControllerType" . ucfirst ($type) . "'></div>";
}
#----------------------------------------------------
sub setCurrentMultilingualObject {
  my ($obj, %params) = @_;
  my $existingMultilingualObject;
  if ($params{scope}) {
    $existingMultilingualObject = $obj->{parser}->getProperty('currentMultilingualObject');
    my $object = $obj->{parser}->findVar( $params{object} );
    if ($object) {
      $obj->{parser}->setProperty( currentMultilingualObject => $object );
    }
    else {
      $params{scope} = 0;
    }
  }
  my $content = $obj->{parser}->_parse( \$params{content} );
  if ($params{scope}) {
    $obj->{parser}->setProperty( currentMultilingualObject => $existingMultilingualObject );
  }
  return ${$content};
}
#----------------------------------------------------
sub form {
  my ($obj, %params) = @_;

  $obj->_setupParams(\%params);

  if ($params{method} && lc $params{method} eq 'post') {
    $params{content} = ($obj->{parser}->getProperty('availableLocalesHtml') || '') . "\n" . $params{content};
    $obj->{parser}->setProperty('isPostRequest', 1);
  }

  my $urlModParamsUsed = 0;
  my $action = $params{action} || delete $params{ajaxAction};
  if (!$action) {
    require O2::Util::UrlMod;
    my $_content = delete $params{content};
    my $urlMod = $context->getSingleton('O2::Util::UrlMod');
    $action = $params{action} = $urlMod->urlMod(%params);
    $params{content} = $_content;
    $urlMod->deleteUrlModParams(\%params);
    $urlModParamsUsed = 1;
  }

  $obj->addJsFile( file => 'o2escape'      );
  $obj->addJsFile( file => 'formFunctions' );

  $obj->{parser}->setProperty('usingO2FormTag', 1);
  $params{name}     ||= $obj->_generateFormName();
  $params{onSubmit} ||= "return o2.rules.checkForm(this);";
  $params{onSubmit}   = "if (o2.formWasRecentlySubmitted('$params{name}')) { return false; } $params{onSubmit}" unless $params{allowMultipleSubmits};
  $params{class}    ||= 'o2Form';

  $obj->{parser}->setProperty( 'formOnChange', delete $params{onChange} ) if $params{onChange};
  $obj->{parser}->setProperty( 'currentFormName',     $params{name}     );
  $obj->_addRules();

  # Allow "smart detection" of enctype and post method
  my $content     = ${ $obj->{parser}->_parse( \$params{content} ) };
  my $formEncType =    $obj->{parser}->getProperty('formEnctype');
  if (!$params{enctype} && $formEncType) {
    $params{enctype} = $formEncType;
    $params{method}  = 'post';
  }
  
  my $extraHiddenInputs = '';
  
  # Don't use ajax when uploading files, since it doesn't work
  if ($params{enctype} && $params{enctype} eq 'multipart/form-data' && $params{isAjaxForm}) {
    my ($ajaxParamsStr) = $params{onSubmit} =~ m{ o2[.]ajax[.]call\(\{ (.+?) \}\) }xms;
    my @ajaxParams = $ajaxParamsStr =~ m{ (["']?) (\w+) \1 \s* : \s*  (?: (["']) (.*?) \3  |  (?: (.*?) ) )  (?: , | \s*\z) }xmsg;
    for (my $i = 0; $i < @ajaxParams; $i += 5) {
      my $key   = $ajaxParams[$i+1];
      my $value = $ajaxParams[$i+3] || $ajaxParams[$i+4];
      $key = "_$key" if $key eq 'where' || $key eq 'target';
      $extraHiddenInputs .= "<input type='hidden' name='$key' value='$value'>\n";
    }
    $params{onSubmit} =~ s{ o2[.]ajax[.]call\(\{ .+? \}\) }{this.submit()}xms;
    $params{target}   = 'o2ajaxIframe';
    delete $params{isAjaxForm};
    $params{action} = $action;
    $urlModParamsUsed = 1;
  }
  
  # Parameters in the action attribute aren't passed to the action script, so we have to handle that manually
  # (but not for ajax forms and not if urlMod params aren't used in the form tag):
  if (!$params{isAjaxForm}  &&  $urlModParamsUsed  &&  (my ($actionParams) = $action =~ m{ [?] ([^?]*) \z }xms)) {
    $params{action} =~ s{ [?] [^?]* \z }{}xms;
    my @attributes = split /&/, $actionParams;
    foreach (@attributes) {
      my ($key, $value) = split /=/, $_, 2;
      $value =~ s{\'}{&apos;}xmsg;
      $extraHiddenInputs .= "<input type='hidden' name='$key' value='$value'>\n" if $content !~ m{ name=[\"\'] $key [\"\'] }xms; # XXX Is this test good enough?
    }
  }
  if ($params{enctype} && $params{enctype} eq 'multipart/form-data' && exists $params{target} && $params{target} eq 'o2ajaxIframe') {
    $extraHiddenInputs .= "<input type='hidden' name='isMultipartAjax' value='1'>\n";
  }

  my $html = '<form ' . $obj->_packTagAttribs(%params) . ">\n";
  $html   .= $extraHiddenInputs;
  $html   .= $content;

  $obj->{parser}->setProperty('currentFormName', undef);

  # For input validation on the server side
  if ($obj->{parser}->getProperty('isPostRequest')) {
    my ($module, $method) = $action =~ m{  /  ( [^/]+ )  /  ( [^/\?]* )  (?: \? | \z )  }xms;
    my $actionWithoutServer = $action;
    if ($action =~ m{ \A https?:// }xms) {
      ($actionWithoutServer) = $action =~ m{  ( / [^/]+ / [^/\?]* )  (?: \? | \z )  }xms;
    }
    my $__rules = $context->getEnv('SERVER_NAME') . "¤$actionWithoutServer¤" . ($params{ruleTitle} || '') . ($obj->{parser}->getProperty('hiddenRulesString') || '');
    use Digest::MD5 qw(md5_hex);
    my $hash = md5_hex( $obj->_getSecretKey() . $__rules );

    $html .= "\n<input type='hidden' name='__rules'    value='$__rules'>";
    $html .= "\n<input type='hidden' name='__ruleHash' value='$hash'>";
  }
  $html .= "\n</form>";
  
  $obj->{parser}->setProperty( 'usingO2FormTag', 0 );
  $obj->{parser}->setProperty( 'isPostRequest',  0 );
  
  return $html;
}
#----------------------------------------------------
sub _generateFormName {
  my ($obj) = @_;
  return 'form' . int (1_000_000_000 * rand);
}
#----------------------------------------------------
# One secret key per session
sub _getSecretKey {
  my ($obj) = @_;
  my $secretKey = $session->get('o2FormSecretKey');
  if (!$secretKey) {
    $secretKey = $context->getSingleton('O2::Util::Password')->generatePassword(10, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
    $session->set('o2FormSecretKey', $secretKey);
  }
  return $secretKey;
}
#----------------------------------------------------
sub formTable {
  my ($obj, %params) = @_;
  $obj->{parser}->setProperty('isFormTable', 1);
  $obj->{parser}->pushPostfixMethod('tr' => $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('tr' => $obj);
  $obj->{parser}->setProperty('isFormTable', 0);
  $params{class} ||= 'o2FormTable';
  return '<table ' . $obj->_packTagAttribs(%params) . ">\n$params{content}\n</table>";
}
#----------------------------------------------------
# If you want to control the tr (and td) tags yourself inside formTable
sub tr {
  my ($obj, %params) = @_;
  $obj->{parser}->setProperty('manualTrTdTags', 1);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->setProperty('manualTrTdTags', 0);
  my $params = $obj->_packTagAttribs(%params);
  return "<tr $params>$params{content}</tr>";
}
#----------------------------------------------------
sub _addRules {
  my ($obj) = @_;
  $obj->addCssFile( file => 'rules' );
  $obj->addJsFile(  file => 'rules' );
  return '';
}
#----------------------------------------------------
sub button {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params);

  my $imageUrl = delete $params{image};
  if ($imageUrl) {
    $imageUrl    = "/images/buttons/$imageUrl" if $imageUrl !~ m{ \A [/.]                    }xms;
    $imageUrl   .= '.gif'                      if $imageUrl !~ m{ \. (?: jpe?g | gif | png ) }xmsi;
    my $imageWidth = delete $params{imageWidth} || 18;
    $params{style} = qq{background-image:url('$imageUrl'); background-repeat: no-repeat; background-position: center left; padding-left: ${imageWidth}px};
  }
  
  if (!$params{onClick}) {
    my $content = delete $params{content}; # Don't send content parameter to urlMod
    my $href    = delete $params{href} || $obj->urlMod(%params);
    $params{content} = $content;
    delete @params{qw/type src remove append appendX alter url setClass setMethod setParams setParam removeParams removeParam appendParam toggleParam absoluteURL/};
    $params{onClick} = qq{document.location.href = '$href';};
  }
  
  $obj->addCssFile(file => 'buttons');
  
  my $class = delete $params{class} || 'defaultButton';
  
  my $attribs = $obj->_packTagAttribs(%params);
  # Using span to "pack" in the button with own img. This to preserve button layouts
  return
      $imageUrl
    ? qq|<span class="$class"><button class="defaultImgButton" $attribs>$params{content}</button></span>|
    : qq|<button class="$class" $attribs>$params{content}</button> |
    ;
}
#----------------------------------------------------
sub fileUpload {
  my ($obj, %params) = @_;
  my $name     = delete $params{name}     or die "Need a name for the fileUpload";
  my $parentId = delete $params{parentId} or die "Need a parentId for the fileUpload";
  
  my $nextNumUploadify = ($obj->{parser}->getProperty('numUploadify') || 0) + 1;
  $obj->{parser}->setProperty('numUploadify', $nextNumUploadify);
  
  my $id = delete $params{id} || "file_upload_$nextNumUploadify";
  delete $params{content};

  $obj->addCssFile( file => 'uploadify/uploadify'                   );
  $obj->addJsFile(  file => 'jquery'                                );
  $obj->addJsFile(  file => 'uploadify/swfobject'                   );
  $obj->addJsFile(  file => 'uploadify/jquery.uploadify.v2.1.4.min' );

  my %defaults = (
    auto         => 'true',
    multi        => 'true',
    sizeLimit    => '15000000',
    script       => '/o2cms/File-Upload/fileUpload',
    fileDataName => $name,
    folder       => $parentId,
    wmode        => 'transparent',
    hideButton   => 'true',
    %params,
  );

  my $options = join ",\n", map { "'$_' : " . ($defaults{$_} =~ m/^function/ ? $defaults{$_} : "'$defaults{$_}'") } keys %defaults;

  my %extraData = (parentId => $parentId);
  
  my $backendSessionCookieName  = $config->get('session.backend.cookieName');
  my $frontendSessionCookieName = $config->get('session.cookieName');
  
  if ($session && !$session->isFrontend()) {
    $extraData{$backendSessionCookieName} = $session->getId();
  }
  else {
    $extraData{$frontendSessionCookieName} = $session->getId();
    $extraData{$backendSessionCookieName}  = $session->getBackendSession() if $session->can('getBackendSession') && $session->getBackendSession();
  }
  
  my $scriptData = "'scriptData': {\n" . join (",\n", map {"'$_' : '$extraData{$_}'"} keys %extraData) . "\n}";

  my $js = <<EOJS;
    \$(document).ready(function() {
      \$('#$params{id}').uploadify({
        'uploader'  : '/js/uploadify/uploadify.swf',
        'cancelImg' : '/js/uploadify/cancel.png',
        $scriptData,
        $options,
      });
    });
EOJS
  $obj->addJs( content => $js, where => 'pre' );
  
  my %tagAttribs = (
    name => $name,
    id   => $id,
  );
  $tagAttribs{eventHandlers} = $params{eventHandlers} if $params{eventHandlers};
  return "<input name='$name' type='file'" . $obj->_packTagAttribs(%tagAttribs) . '>';
}
#----------------------------------------------------
sub inputCounter {
  my ($obj, %params) = @_;
  my $type = delete $params{type} || 'span';
  my $id   = delete $params{id} or die 'No ID supplied for inputCounter';
  return "<$type id='$id'" . $obj->_packTagAttribs(%params) . "></$type>";
}
#----------------------------------------------------
sub _addInputCounterToElement {
  my ($obj, $params) = @_; # Need to pass as reference because we need to manipulate the params
  return unless $params->{counterId};
  
  my $counterId     = delete $params->{counterId};
  my $valueKey      = exists $params->{value} ? 'value' : 'content';
  my $currentLength = $params->{$valueKey} =~ m{ \A \s* \z }xms  ?  0  :  length $params->{$valueKey};
  my $maxLength     = $params->{maxLength} || -1;
  
  $params->{onKeyUp} = "o2.inputCount(this, '$counterId', $maxLength);";
  
  $obj->addJsFile( file => 'inputCounter' );
  $obj->addJs(
    content => "o2.inputCount($currentLength,'$counterId', $maxLength);",
    where   => 'post',
  );
}
#----------------------------------------------------
sub input {
  my ($obj, %params) = @_;
  $params{type} ||= 'text';
  
  my %localeValues;
  %localeValues = $obj->_getLocaleValues(%params) if $params{multilingual};
  
  $obj->_setupParams(\%params);
  
  my ($pre, $post, $checked) = ('', '');
  if ($params{type} ne 'hidden') {
    my $class;
    if ($params{type} =~ m/^(?:button|submit|file|reset)$/) {
      $class = 'button';
      $obj->{parser}->setProperty('formEnctype', 'multipart/form-data') if $params{type} eq 'file';
      $params{_type} = 'input';
      ($pre, $post) = $obj->_getPrePostForInputFieldsWithLabel(\%params);
    }
    elsif ($params{type} =~ m{ \A (?: radio | checkbox ) \z }xms) {
      $obj->{parser}->_parse( \$params{checked} ) if $params{checked};
      my $checked = delete $params{checked};
      $params{checked} = 'checked' if $checked;
      
      if ($params{content}) {
        $params{id} ||= $obj->{parser}->getProperty('currentFormName') . "_$params{name}" . ($params{type} eq 'radio' ? "_$params{value}" : '');
        $post = qq{<label for="$params{id}"> $params{content}</label>};
      }
    }
    else {
      $class = 'textInput';
      $obj->_addInputCounterToElement(\%params) if $params{counterId};
      $params{id}  ||= $obj->{parser}->getProperty('currentFormName') . "_$params{name}";
      $params{_type} = 'input';
      ($pre, $post) = $obj->_getPrePostForInputFieldsWithLabel(\%params);
    }
    $params{class} ||= $class;
  }
  
  delete $params{rawName};
  my $inputFieldHtml = $obj->_createLocaleFields(\%params, \%localeValues, 'input', 1);
  return $pre . $inputFieldHtml . $post;
}
#----------------------------------------------------
sub dateSelect {
  my ($obj, %params) = @_;

  $obj->_setupParams(\%params);

  $params{id}  ||= $obj->{parser}->getProperty('currentFormName') . "_$params{name}";
  $params{_type} = 'dateSelect';
  my ($pre, $post) = $obj->_getPrePostForInputFieldsWithLabel(\%params);

  $obj->_updateHiddenRulesString(%params);
  my $html = $obj->{parser}->getTaglibByName("Html::DateSelect")->dateSelect(%params);
  return "$pre$html$post";
}
#----------------------------------------------------
sub textarea {
  my ($obj, %params) = @_;

  my %localeValues;
  %localeValues = $obj->_getLocaleValues(%params) if $params{multilingual};
  $obj->_setupParams(\%params);

  $params{class} ||= 'textInput';
  $obj->_addInputCounterToElement(\%params) if $params{counterId};

  $params{id}  ||= $obj->{parser}->getProperty('currentFormName') . "_$params{name}";
  $params{_type} = 'textarea';
  if ($params{autoResize}) {
    $obj->addJsFile( file  => 'taglibs/html/form/textarea/autoResize' );
    $obj->addJs(
      where   => 'onLoad',
      content => "o2.autoResize.resizeTextarea( '$params{id}' );",
    );
  }
  my ($pre, $post) = $obj->_getPrePostForInputFieldsWithLabel(\%params);
  $params{content} = delete $params{value};

  my $inputFieldHtml = $obj->_createLocaleFields(\%params, \%localeValues, 'textarea', 0);
  return $pre . $inputFieldHtml . $post;
}
#----------------------------------------------------
sub comboBox {
  my ($obj, %params) = @_;
  $obj->{parser}->getTaglibByName('Html::Form::ComboBox')->comboBox(%params);
}
#----------------------------------------------------
sub select {
  my ($obj, %params) = @_;
  $obj->{parser}->getTaglibByName('Html::Form::Select')->select(%params);
}
#----------------------------------------------------
sub radioGroup {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params);
  $obj->_updateHiddenRulesString(%params);
  return $obj->_radioOrCheckboxGroup(type => 'radio', %params);
}
#----------------------------------------------------
sub checkboxGroup {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params);
  $obj->_updateHiddenRulesString(%params);
  $obj->addJsFile( file => 'taglibs/html/form/checkboxGroup' );
  return $obj->_radioOrCheckboxGroup(type => 'checkbox', %params);
}
#----------------------------------------------------
sub radio {
  my ($obj, %params) = @_;
  return $obj->_radioOrCheckbox(type => 'radio', %params);
}
#----------------------------------------------------
sub checkbox {
  my ($obj, %params) = @_;
  return $obj->_radioOrCheckbox(type => 'checkbox', %params);
}
#----------------------------------------------------
sub _radioOrCheckboxGroup {
  my ($obj, %params) = @_;

  # If radio groups have the same name, you can't check off radio buttons in more than one group, so we have to make sure they have different names.
  # Cgi.pm strips away the prefix that we're adding here.
  $params{name} = 'o2Radio' . int(1_000_000_000 * rand) . "_$params{name}" if $params{type} eq 'radio' && $params{name} =~ m{ \[ \d* \] \z }xms;

  my %radioOrCheckboxParams = %params;
  delete $radioOrCheckboxParams{wrapperClass};
  $obj->{radioOrCheckboxParams} = \%radioOrCheckboxParams;

  $obj->{radioOrCheckboxNumber} = 0;
  $obj->{radioChecked} = delete $params{value};
  my $values           = delete $params{values} || '';
  if ($values =~ m{ \A ARRAY \( .+? \) \z }xms) {
    $values = $obj->{parser}->findVar( $obj->getRawParam('values') );
    $values = join ', ', @{ $values };
  }
  elsif ($values =~ m{ \A \s* \[ \s* \$ }xms) {
    $obj->{parser}->parseVars(\$values, 'externalDereference');
    $values = eval $values;
    die "Didn't understand 'values' attribute: $@" if $@;
    $values = join ', ', @{$values};
  }
  $obj->{checkboxChecked} = $values;

  my $oldFormOnChange = $obj->{parser}->getProperty('formOnChange');
  my $onChange = $params{onChange} || delete $params{onchange} || '';
  $onChange   .= '; ' if $params{onChange} && $params{onChange} !~ m{ ; \s* \z }xms;
  $onChange   .= $oldFormOnChange if length $oldFormOnChange;
  $obj->{parser}->setProperty('formOnChange', $onChange);

  $obj->{parser}->pushPostfixMethod( 'inputHint'   => $obj );
  $obj->{parser}->pushPostfixMethod( $params{type} => $obj ); # radio or checkbox
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod( $params{type} => $obj ); # radio or checkbox
  $obj->{parser}->popMethod( 'inputHint'   => $obj );
  my $post = $obj->{parser}->getProperty('inputHintHtml');
  $obj->{parser}->setProperty('inputHintHtml', undef);

  $obj->{parser}->setProperty('formOnChange', $oldFormOnChange);

  my $useTable = $obj->{parser}->getProperty('isFormTable');
  my $tag1 = $useTable ? 'tr' : 'div';
  my $groupClass = 'o2InputWrapper o2' . ucfirst( $params{type} ) . 'Group ' . ($params{class} || '') . ' ' . (delete $params{wrapperClass} || '');
  my $labelClass =                'o2' . ucfirst( $params{type} ) . 'GroupLabel';
  $labelClass   .= ' ' . delete $params{labelClass} if $params{labelClass};
  
  my $html = '';
  $html   .= "<$tag1 class='$groupClass'>\n" unless $obj->{parser}->getProperty('manualTrTdTags');
  $html   .= "<td>" if $useTable;
  $html   .= "<label class='$labelClass' onclick='document.getElementById(\"$obj->{radioOrCheckboxGroupFirstId}\").focus();'>" . ($params{label} || '') . "</label>\n";
  $html   .= "</td>" if $useTable;
  $html   .= $post   if $post && !$useTable;
  my $tag2 = $useTable ? 'td' : 'span';
  my $class = $params{type} eq 'radio' ? 'o2RadioButtons' : 'o2Checkboxes';
  $html .= "<$tag2 class='$class'>$params{content}</$tag2>\n";
  $html .= "</$tag1>" unless $obj->{parser}->getProperty('manualTrTdTags');

  if (delete $params{focus}) {
    $obj->addJs( content => "document.getElementById('$obj->{radioOrCheckboxGroupFirstId}').focus();", where => "post" );
  }
  if ($params{type} eq 'checkbox') {
    my $formName = $obj->{parser}->getProperty('currentFormName');
    $obj->addJs( content => "o2.checkboxGroup.setOnSubmit('$formName', '$params{name}');", where => 'post' ) if $formName;
  }

  return $html;
}
#----------------------------------------------------
sub _radioOrCheckbox {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params);
  %params = ( %{ $obj->{radioOrCheckboxParams} },  %params ) if $obj->{radioOrCheckboxParams};

  $params{id} ||= ($obj->{parser}->getProperty('currentFormName') || '') . "_$params{name}_$params{value}";
  my $accesskey = delete $params{accesskey};
  $obj->{radioOrCheckboxGroupFirstId} = $params{id} if ++$obj->{radioOrCheckboxNumber} == 1;
  my $display = delete $params{display};
  my $label   = delete $params{label};
  $params{style} ||= '';
  $params{style}   = 'clear: left; ' . $params{style} if $display && $display eq 'block';
  my $class = $params{type} eq 'radio' ? 'o2RadioButton' : 'o2Checkbox';
  my $style = $display         ? " style='display: $display;$params{style}'" :
              $params{style}   ? " style=$params{style}"                     : '';
  $params{onChange} = $obj->{parser}->getProperty('formOnChange');
  $params{onChange} =~ s{ \" }{&quot;}xmsg;
  if (
         ($params{type} eq 'radio'    && defined $obj->{radioChecked} && $obj->{radioChecked} eq $params{value})
      || ($params{type} eq 'checkbox' && $params{value} && $obj->{checkboxChecked} =~ m{   (?: \A | [,])   \s*   $params{value}   \s*   (?:  \z | [,])  }xms)
      || ($params{checked} && $params{checked} ne "0")
      ) {
    $params{checked} = "checked";
  }
  else {
    delete $params{checked};
  }
  my $type = delete $params{type};
  my $buttonClass = 'o2' . ucfirst($type) . 'Button';
  my $labelClass  = 'o2' . ucfirst($type) . 'Label';
  $labelClass    .= ' ' . delete $params{labelClass} if $params{labelClass};
  my $html = "<span class='$buttonClass'" . $style . ">";
  $html   .= '<input ';
  $html   .= "type='$type' " if $type;
  $html   .= $obj->_packTagAttribs(%params) . '>';
  $html   .= "<label for='$params{id}'";
  $html   .= " accesskey='$accesskey'" if $accesskey;
  $html   .= " class='$labelClass'>";
  if ($accesskey && $label =~ m{ $accesskey }xmsi) {
    $label =~ m{ \A (.*?) ($accesskey) (.*) \z }xmsi;
    my $labelBeforeAccesskey = $1;
    $accesskey               = $2;
    my $labelAfterAccesskey  = $3;
    $html .= "$labelBeforeAccesskey<span class='accesskey'>$accesskey</span>$labelAfterAccesskey";
  }
  else {
    $html .= $label if length $label;
  }
  $html .= "</label>";
  $html .= "</span>";
  $html .= "<br>" if $params{lineBreakAfter};
  return $html;
}
#----------------------------------------------------
sub _getPrePostForInputFieldsWithLabel {
  my ($obj, $params) = @_;

  $obj->addJS( content => "document.getElementById('$params->{id}').focus();", where => "post" ) if delete $params->{focus};;

  my $label = delete $params->{label};
  return ('', '') unless $label;

  my ($pre, $post) = ('', '');
  my $useTable  = $obj->{parser}->getProperty('isFormTable') && !$obj->{parser}->getProperty('manualTrTdTags');
  my $accesskey =         delete $params->{accesskey};
  my $type      = ucfirst delete $params->{_type};
  my $tag1 = $useTable ? 'tr' : 'div';
  my $tag2 = $useTable ? 'td' : 'span';
  if (!$obj->{parser}->getProperty('manualTrTdTags')) {
    $pre .= sprintf "<$tag1 class='o2InputWrapper o2$type %s'", delete $params->{wrapperClass} || '';
    $pre .= " style='$params->{containerStyle}'" if $params->{containerStyle};
    $pre .= '>';
    delete $params->{containerStyle};
  }
  
  $obj->{parser}->pushMethod('inputHint', $obj);
  $obj->{parser}->_parse( \$params->{content} );
  $obj->{parser}->popMethod('inputHint', $obj);
  $post .= $obj->{parser}->getProperty('inputHintHtml') || '';
  $obj->{parser}->setProperty('inputHintHtml', undef);
  
  $params->{id} ||= $obj->{parser}->getProperty('currentFormName') . "_$params->{name}";
  $pre .= "<td class='o2Label'>"    if $useTable;
  $pre .= "<label class='o2${type}Label " . ($params->{labelClass} || '') . "' for='$params->{id}'";
  $pre .= " accesskey='$accesskey'" if $accesskey;
  $pre .= ">";

  if ($accesskey && $label =~ m{ $accesskey }xmsi) {
    $label =~ m{ \A (.*?) ($accesskey) (.*) \z }xmsi;
    my $labelBeforeAccesskey = $1;
    $accesskey               = $2;
    my $labelAfterAccesskey  = $3;
    $pre .= "$labelBeforeAccesskey<span class='accesskey'>$accesskey</span>$labelAfterAccesskey";
  }
  else {
    $pre .= $label;
  }
  $pre  .= "</label>\n";
  $pre  .= "</td>" if $useTable;
  $pre  .= "<$tag2 class='o2Input'>" if $useTable;
  $post .= "</$tag2>\n"           if $useTable;
  $post .= "</$tag1>" unless $obj->{parser}->getProperty('manualTrTdTags');

  return ($pre, $post);
}
#----------------------------------------------------
sub inputHint {
  my ($obj, %params) = @_;
  $obj->addCssFile( file => 'taglibs/html/inputHint' );
  $obj->addJsFile(  file => 'modernizr'              );
  $obj->{parser}->setProperty('inputHintHtml', qq{<div class="inputHint">$params{content}</div>});
  return '';
}
#----------------------------------------------------
sub _getLocaleValues {
  my ($obj, %params) = @_;
  
  my %localeValues;
  my $multilingualObject = $obj->{parser}->getProperty('currentMultilingualObject');
  my @availableLocales = $multilingualObject ? $multilingualObject->getAvailableLocales() : @{ $config->get('o2.locales') };
  
  foreach my $locale (@availableLocales) {
    if ($multilingualObject) {
      $multilingualObject->setCurrentLocale($locale);
    }
    else {
      my ($suppressError, $objectString) = $params{value} =~ m{ \A (\^?) (\$ \w+) -> }xms;
      die qq{Couldn't find object in value ("$params{value}") for multilingual field} unless $objectString;
      my $object = $obj->{parser}->findVar($objectString);
      if ($object) {
        $object->setCurrentLocale($locale);
      }
      else {
        die qq{"$objectString" is not a valid object in multilingual field} unless $suppressError;
      }
    }
    $localeValues{$locale} = $obj->{parser}->findVar( $params{value} );
  }
  return %localeValues;
}
#----------------------------------------------------
sub _createLocaleFields {
  my ($obj, $params, $localeValues, $tagname, $selfClosing) = @_;
  delete $params->{label};
  
  if ($obj->{parser}->getProperty('formOnChange')) {
    $params->{onChange} ||= delete  $params->{onchange} || '';
    $params->{onChange}  .= '; ' if $params->{onChange} && $params->{onChange} !~ m{ ; \s* \z }xms;
    $params->{onChange}  .= $obj->{parser}->getProperty('formOnChange');
  }
  
  if (!$params->{multilingual}) {
    if ($params->{numberFormat} && length $params->{value}) {
      $params->{value} = $obj->{parser}->getTaglibByName('NumberFormat')->numberFormat(
        param   => $params->{numberFormat},
        content => $params->{value},
      );
    }
    my $returnString = "<$tagname " . $obj->_packTagAttribs(%{$params});
    $returnString   .= '>' if $selfClosing;
    if (!$selfClosing) {
      my $value = delete $params->{content} || delete $params->{value} || '';
      $returnString .= ">$value</$tagname>";
    }
    $obj->_updateHiddenRulesString( %{$params} );
    return $returnString;
  }
  my $inputFieldHtml = '';

  my $multilingualObject = $obj->{parser}->getProperty('currentMultilingualObject');
  foreach my $locale ( $multilingualObject ? $multilingualObject->getAvailableLocales() : @{ $config->get('o2.locales') } ) {
    my $value =  $localeValues->{$locale};
    $value    =~ s{ \' }{&apos;}xmsg;
    my $name  = $obj->_getMultilingualName( $locale, $params->{name} );
    my $id    = $name;
    $inputFieldHtml .= "<input type='hidden' id='$id' name='$name' value='$value' class='multilingual'>";
    $obj->_updateHiddenRulesString(%{$params});
  }
  if ($selfClosing) {
    $inputFieldHtml .= "<$tagname " . $obj->_packTagAttribs(%{$params});
    $inputFieldHtml .= '>';
  }
  else {
    my $value = delete $params->{value};
    $inputFieldHtml .= "<$tagname " . $obj->_packTagAttribs(%{$params});
    $inputFieldHtml .= ">$value</$tagname>";
  }
  return $inputFieldHtml;
}
#----------------------------------------------------
sub _getMultilingualName {
  my ($obj, $localeCode, $name) = @_;
  if ($name =~ m{ [.] }xms) { # name contains at least one dot, so we insert the locale-code after the first dot
    $name =~ s{ \A ([^.]+) [.] (.*) \z }{$1.$localeCode.$2}xms;
    return $name;
  }
  return "$localeCode.$name";
}
#----------------------------------------------------
sub multiInput {
  my ($obj, %params) = @_;

  $obj->addJsFile(  file => 'multiInput' );
  $obj->addCssFile( file => 'multiInput' );

  my $isFormTable  = $obj->{parser}->getProperty('isFormTable');
  my @columnTitles = split /\|/, $params{columnTitles} || '';

  my %multiInputParams;
  @multiInputParams{ qw(columnTitles minNumLines rearrangeable resizable label labelClass addRowText newRowHandler onDeleteRow id) }
   = delete @params{ qw(columnTitles minNumLines rearrangeable resizable label labelClass addRowText newRowHandler onDeleteRow id) };
  $multiInputParams{id} ||= 'multiInput_' . $obj->_getRandomId();

  if ($context->isAjaxRequest()) {
    $obj->addJs(
      content => "o2.multiInput.setup( document.getElementById('$multiInputParams{id}') );",
      where   => 'post',
    );
  }

  if ($params{values}) {
    my $js = "
      if (!multiInputValues) {
        var multiInputValues = {};
      }";
    my $jsData = $context->getSingleton('O2::Javascript::Data');
    if ($params{multilingual}) {
      $params{value} = delete $params{values};
      my %localeValues = $obj->_getLocaleValues(%params);
      delete $params{value};
      while (my ($localeCode, $values) = each %localeValues) {
        my $jsValues = $jsData->dump($values);
        my $name = $obj->_getMultilingualName( $localeCode, $params{name} );
        $js .= "multiInputValues['$name'] = $jsValues;";
      }
    }
    else {
      my $values   = $obj->{parser}->findVar( delete $params{values} );
      my $jsValues = $jsData->dump($values);
      $js .= "multiInputValues['$params{name}'] = $jsValues;";
    }
    $obj->addJs(
      where   => 'pre',
      content => $js
    );
  }

  my $content = delete $params{content};
  $content  ||= '<o2 input ' . $obj->_packTagAttribs(%params) . ' />';
  $content    = "<o2 row>$content</o2:row>" if !@columnTitles && $content !~ m{ <o2 \s+ row> }xms;

  my $titleRow;
  $titleRow = '<tr><th>' . join('</th><th>', @columnTitles) . '</th></tr>' if @columnTitles;

  $obj->{parser}->setProperty( 'hasColumnTitles', scalar @columnTitles );

  $obj->{parser}->pushPostfixMethod( 'row',          $obj );
  $obj->{parser}->pushMethod(        'columnTitles', $obj ) if @columnTitles;
  $obj->{parser}->_parse(\$content);
  $obj->{parser}->popMethod(         'columnTitles', $obj ) if @columnTitles;
  $obj->{parser}->popMethod(         'row',          $obj );

  $obj->{parser}->setProperty( 'hasColumnTitles', undef );

  my ($pre, $post) = $obj->_getPrePostForInputFieldsWithLabel(\%params);
  return $pre . $obj->_getMultiInputHtml($content, $titleRow, $isFormTable, scalar @columnTitles, %multiInputParams) . $post;
}
#----------------------------------------------------
sub _getMultiInputHtml {
  my ($obj, $content, $titleRow, $isFormTable, $hasColumnTitles, %params) = @_;

  my $minNumLines   = delete $params{minNumLines}   || 1;
  my $resizable     = delete $params{resizable}     || 0;
  my $rearrangeable = delete $params{rearrangeable} || 0;

  my $addRowText = delete $params{addRowText} || $obj->{parser}->findVar('$lang')->getString('Taglibs.Form.multiInput.linkTextAddRow');

  my ($labelHtmlPre, $labelHtmlPost) = ('', '');
  if ($params{label}) {
    if ($isFormTable) {
      $labelHtmlPre  = "<td><label>$params{label}</label></td>\n";
      $labelHtmlPost = "<td></td>";
    }
    elsif (!$isFormTable && !$hasColumnTitles) {
      $labelHtmlPre = "<div class='multiInputLabel'><label>$params{label}</label></div>";
    }
    elsif (!$isFormTable && $hasColumnTitles) {
      my $labelClass = 'o2MultiInputLabel';
      $labelClass   .= ' ' . delete $params{labelClass} if $params{labelClass};
      $labelHtmlPre = "<label class='$labelClass'>$params{label}</label>";
    }
  }
  
  $params{newRowHandler} ||= '';
  $params{onDeleteRow}   ||= '';
  
  if ($isFormTable && !$hasColumnTitles) {
    return <<"END";
<tbody id="$params{id}" class="multiInput" minNumLines="$minNumLines" resizable="$resizable" rearrangeable="$rearrangeable" newRowHandler="$params{newRowHandler}" onDeleteRow="$params{onDeleteRow}">
  <tr class="rows">
    $labelHtmlPre
    <td colspan="99">$content</td>
  </tr>
  <tr>
    $labelHtmlPost
    <td colspan="99"><a href='#addRow' class='iconBtn addBtn' onClick="o2.multiInput.addRow( o2.getClosestAncestorByClassName(this, 'multiInput') )">$addRowText</a></td>
  </tr>
</tbody>
END
  }

  if ($isFormTable && $hasColumnTitles) {
    return <<"END";
<tbody id="$params{id}" class="multiInput" minNumLines="$minNumLines" resizable="$resizable" rearrangeable="$rearrangeable" newRowHandler="$params{newRowHandler}" onDeleteRow="$params{onDeleteRow}">
  <tr>
    $labelHtmlPre
    <td class="rows" colspan="99">
      <table>
        $titleRow
        $content
      </table>
    </td>
  </tr>
  <tr>
    $labelHtmlPost
    <td colspan="99"><a href='#addRow' class='iconBtn addBtn' onClick="o2.multiInput.addRow( o2.getClosestAncestorByClassName(this, 'multiInput') )">$addRowText</a></td>
  </tr>
</tbody>
END
  }

  if (!$isFormTable && $hasColumnTitles) {
    return <<"END";
<div id="$params{id}" class="multiInput" minNumLines="$minNumLines" resizable="$resizable" rearrangeable="$rearrangeable" newRowHandler="$params{newRowHandler}" onDeleteRow="$params{onDeleteRow}">
  $labelHtmlPre
  <div class="rows">
    <table>
      $titleRow
      $content
    </table>
  </div>
  <div class='buttonRow'><a href='#addRow' class='iconBtn addBtn' onClick="o2.multiInput.addRow( o2.getClosestAncestorByClassName(this, 'multiInput') )">$addRowText</a></div>
</div>
END
  }

  if (!$isFormTable && !$hasColumnTitles) {
    return <<"END";
<div id="$params{id}" class="multiInput" minNumLines="$minNumLines" resizable="$resizable" rearrangeable="$rearrangeable" newRowHandler="$params{newRowHandler}" onDeleteRow="$params{onDeleteRow}">
  $labelHtmlPre
  <div class="rows">
    $content
  </div>
  <a href='#addRow' class='iconBtn addBtn' onClick="o2.multiInput.addRow( o2.getClosestAncestorByClassName(this, 'multiInput') )">$addRowText</a>
</div>
END
  }
}
#----------------------------------------------------
sub row {
  my ($obj, %params) = @_;

  $obj->{parser}->pushMethod('cell', $obj);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('cell', $obj);

  my $lang = $obj->{parser}->findVar('$lang');  
  my $moveUpTitle      = $lang->getString( 'Taglibs.Form.multiInput.titleMoveUp'      );
  my $moveDownTitle    = $lang->getString( 'Taglibs.Form.multiInput.titleMoveDown'    );
  my $deleteTitle      = $lang->getString( 'Taglibs.Form.multiInput.titleDelete'      );
  my $moveUpLinkText   = $lang->getString( 'Taglibs.Form.multiInput.linkTextMoveUp'   );
  my $moveDownLinkText = $lang->getString( 'Taglibs.Form.multiInput.linkTextMoveDown' );
  my $deleteLinkText   = $lang->getString( 'Taglibs.Form.multiInput.linkTextDelete'   );

  my $hasColumnTitles = $obj->{parser}->getProperty( 'hasColumnTitles' );

  my $rowTag      = $hasColumnTitles ? 'tr' : 'div';
  my $controlsTag = $hasColumnTitles ? 'td' : 'div';

  $params{content} = "<div class='rowContent'>$params{content}</div>" if $controlsTag eq 'div';
  $params{class} ||= '';

  my %rowParams = %params;
  delete $rowParams{content};
  delete $rowParams{class};
  my $rowParams = $obj->_packTagAttribs(%rowParams);

  return <<"END";
<$rowTag class="multiInputRow $params{class}" $rowParams>
  $params{content}
  <$controlsTag class="controls">
    <a href="#up"     class="iconBtn noText upBtn"     title="$moveUpTitle"   onClick="o2.multiInput.moveUp(    o2.getClosestAncestorByClassName(this, 'multiInputRow') )">$moveUpLinkText</a>
    <a href="#down"   class="iconBtn noText downBtn"   title="$moveDownTitle" onClick="o2.multiInput.moveDown(  o2.getClosestAncestorByClassName(this, 'multiInputRow') )">$moveDownLinkText</a>
    <a href="#delete" class="iconBtn noText deleteBtn" title="$deleteTitle"   onClick="o2.multiInput.deleteRow( o2.getClosestAncestorByClassName(this, 'multiInputRow') )">$deleteLinkText</a>
  </$controlsTag>
</$rowTag>
END
}
#----------------------------------------------------
sub cell {
  my ($obj, %params) = @_;
  return "<td>$params{content}</td>";
}
#----------------------------------------------------
sub getRawParam {
  my ($obj, $key) = @_;
  my $params = $obj->{rawParams} || { $obj->getParams() };
  return $params->{$key};
}
#----------------------------------------------------
sub _updateHiddenRulesString {
  my ($obj, %params) = @_;
  return unless $params{rule};
  
  my $oldString = $obj->{parser}->getProperty('hiddenRulesString') || '';
  my $hiddenRulesString = sprintf "$oldString¤$params{name}|$params{rule}|%s", $params{ruleMsg} || '';
  $obj->{parser}->setProperty('hiddenRulesString', $hiddenRulesString);
}
#----------------------------------------------------
sub _setupParams {
  my ($obj, $paramsRef) = @_;

  if (exists $paramsRef->{disabled}) {
    # Setting disabled to "0" should mean not disabling:
    if (!$paramsRef->{disabled}) {
      delete $paramsRef->{disabled};
    }
    elsif ($paramsRef->{disabled} =~ m{ \$ }xms) {
      my $result;
      $obj->{parser}->parseVars( \$paramsRef->{disabled}, 'externalDereference' );
      eval "\$result = $paramsRef->{disabled};";
      $paramsRef->{disabled} = 'disabled' if $result;
      delete $paramsRef->{disabled}   unless $result;
    }
    else {
      $paramsRef->{disabled} = 'disabled';
    }
  }
  
  $obj->SUPER::_setupParams($paramsRef);
}
#----------------------------------------------------
1;
