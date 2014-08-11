package O2::Template::Taglibs::Html::Form::ComboBox;

use strict;

use base 'O2::Template::Taglibs::Html::Form';

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my $obj = bless { parser => $params{parser} }, $package;
  $obj->{cssIncluded} = 0;
  $obj->{parser}->registerTaglib('Html::Form');
  my %methods = (
    comboBox => 'postfix',
  );
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub comboBox {
  my ($obj, %params) = @_;
  $params{name} = "hidden_$params{name}";
  $obj->addJsFile(  file => 'combobox' );
  $obj->addCssFile( file => 'comboBox', includeFirst => 1 );
  
  my %localeValues;
  %localeValues = $obj->_getLocaleValues(%params) if $params{multilingual};
  $obj->_setupParams(\%params);
  $params{class} ||= 'comboBox o2ComboBoxList';
  $params{_type}   = 'comboBox';
  $obj->{comboBoxValue} = delete $params{value};
  $obj->{id}            = $params{id} ||= ($obj->{parser}->getProperty('currentFormName') || '') . "_$params{name}";
  
  $obj->{parser}->pushMethod('option' => $obj);
  my ($pre, $post) = $obj->_getPrePostForInputFieldsWithLabel(\%params);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('option' => $obj);
  
  $obj->addJs(
    where   => 'onLoad',
    content => "o2.comboBox.init( '$obj->{id}', '$obj->{comboBoxValue}' );",
  );
  
  $obj->_updateHiddenRulesString(%params);
  my $html = $pre . $obj->_createLocaleFields(\%params, \%localeValues, 'ul', 0) . $post;
  my $numReplacements = $html =~ s{ (<td [^>]*? >) (.*?) (</td>) }{$1<div>$2</div>$3}xmsg;
  if ($numReplacements > 0 && !$obj->{cssIncluded}) {
    $obj->addCss(content => '.o2ComboBox td div ul { left : 0; }');
    $obj->{cssIncluded} = 1;
  }
  return $html;
}
#----------------------------------------------------
sub option {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params);
  $params{value}   = $params{content} unless defined $params{value};
  $params{content} = $params{value}   unless $params{content};
  $params{onClick} = "o2.comboBox.setInputValue('$obj->{id}', '$params{value}'); o2.comboBox.toggleOptions('$obj->{id}');";
  $obj->{comboBoxValue} ||= '';
  my $isSelected = $params{selected}  ||  ( $params{value} && $params{value} eq $obj->{comboBoxValue} );
  return "<li " . $obj->_packTagAttribs(%params) . ">$params{content}</li>\n";
}
#--------------------------------------------------------------------------------------------
1;
