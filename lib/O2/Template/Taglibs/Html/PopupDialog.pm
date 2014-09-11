package O2::Template::Taglibs::Html::PopupDialog;

use strict;

use base 'O2::Template::Taglibs::JqueryUi';

#------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my ($obj, %methods) = $package->SUPER::register(%params);
  %methods = (
    %methods,
    popupDialog => 'postfix',
  );
  $obj->addCssFile( file => 'bootstrap.min'            );
  $obj->addJsFile(  file => 'bootstrap.min'            );
  $obj->addJsFile(  file => 'taglibs/html/popupDialog' );
  $obj->addJs( # Allow HTML in the 'title' attribute (http://stackoverflow.com/questions/14488774/using-html-in-a-dialogs-title-in-jquery-ui-1-10)
    where   => 'pre',
    content => q{
      $.widget("ui.dialog", $.extend({}, $.ui.dialog.prototype, {
        _title: function(title) {
          title.html(this.options.title || "&#160;");
        }
      }));
    },
  );
  $obj->addJs(
    where   => 'onLoad',
    content => 'o2.popupDialog.init();',
  );
  return ($obj, %methods);
}
#------------------------------------------------------------------
sub popupDialog {
  my ($obj, %params) = @_;
  if (!$params{id}) {
    require O2::Util::Password;
    my $passwordGenerator = O2::Util::Password->new();
    $params{id} = $passwordGenerator->generatePassword(8);
  }
  $obj->{popupDialogId} = $params{id};
  $obj->_setupParams(\%params);

  my $contentHtml = delete $params{content};
  $obj->{parser}->pushMethod('button', $obj);
  $obj->{parser}->_parse(\$contentHtml);
  $obj->{parser}->popMethod('button', $obj);

  $contentHtml     = $obj->_jsEscape( $contentHtml           );
  $params{title}   = $obj->_jsEscape( $params{title}         ) || '&nbsp;';
  $params{onClose} = $obj->_jsEscape( $params{onClose} || '' );

  my $closeText  = $params{closeText};
  my $submitText = $params{submitText};
  my $contentId  = $params{contentId} || '';
  my $src        = $params{src}       || '';
  if (!$src) {
    my $url = $obj->urlMod(%params);
    $params{contentUrl} = $src = $url if $url ne $obj->urlMod();
  }
  my $jsContent = qq{o2.popupDialog.define("$params{id}", {
  autoOpen    : true,
  contentId   : "$contentId",
  contentUrl  : "$src",
  contentHtml : '$contentHtml',
  onClose     : '$params{onClose}',
  title       : '$params{title}',
  closeText   : '$params{closeText}',
  width       : '$params{width}',
  height      : '$params{height}'
});};
  delete $params{title};
  $jsContent .= qq{o2.popupDialog.addSubmitBtn( "$params{id}", "$submitText" );} if $submitText;
  $jsContent .= qq{o2.popupDialog.addCloseBtn(  "$params{id}", "$closeText"  );} if $closeText;
  $obj->addJs(
    where   => 'post',
    content => $jsContent,
    noParse => 1,
  );
  $obj->{parser}->_parse( \$params{linkText} );
  my $linkText = delete $params{linkText};
  my $paramsStr = $obj->_packTagAttribs(%params);
  return qq{<button id="o2PopupDialogSubmit$params{id}" class="hidden" data-toggle="modal" data-target="#o2PopupDialog"></button>
<a href="javascript:o2.popupDialog.display('$params{id}')" $paramsStr>$linkText</a>} if $linkText;
  return qq{<button id="o2PopupDialogSubmit$params{id}" class="hidden" data-toggle="modal" data-target="#o2PopupDialog"></button>};
}
#------------------------------------------------------------------
sub button {
  my ($obj, %params) = @_;
  $params{class} ||= 'btn-primary';
  my $text    = $obj->_jsEscape( $params{text}    );
  my $onClick = $obj->_jsEscape( $params{onClick} );
  $obj->addJs(
    where    => 'post',
    content  => qq{o2.popupDialog.addBtn( '$obj->{popupDialogId}', '$text', '$onClick', '$params{class}' );},
    priority => 6,
  );
  return '';
}
#------------------------------------------------------------------
1;
