package O2::Template::Taglibs::Html::Form::Select;

use strict;

use base 'O2::Template::Taglibs::Html::Form';

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my $obj = bless { parser => $params{parser} }, $package;
  $obj->{parser}->registerTaglib('Html::Form');
  my %methods = (
    select => 'postfix',
  );
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub select {
  my ($obj, %params) = @_;
  
  my %localeValues;
  %localeValues = $obj->_getLocaleValues(%params) if $params{multilingual};
  $obj->_setupParams(\%params);
  $params{class} ||= 'select';
  $obj->addCss(class => $params{class});
  $obj->{selectValue}  = delete $params{value};
  
  my $values = delete $params{values} || '';
  if ($values =~ m{ \A ARRAY \( .+? \) \z }xms) {
    $values = $obj->{parser}->findVar( $obj->getRawParam('values') );
    $values = join ', ', @{ $values };
  }
  $obj->{selectValues} = $values;
  
  $obj->{id} = $params{id} ||= ($obj->{parser}->getProperty('currentFormName') || '') . "_$params{name}";
  $params{_type} = 'select';
  
  $obj->{parser}->pushMethod('option' => $obj);
  my ($pre, $post) = $obj->_getPrePostForInputFieldsWithLabel(\%params);
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->popMethod('option' => $obj);
  
  $obj->addJsFile(file => 'ie/select-disabled-fix', browser => 'ie7', where => 'pre');
  
  $obj->_updateHiddenRulesString(%params);
  return $pre . $obj->_createLocaleFields(\%params, \%localeValues, 'select', 0) . $post;
}
#----------------------------------------------------
sub option {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params);
  $params{value}   = $params{content} unless defined $params{value};
  $params{content} = $params{value}   unless $params{content};
  $obj->{selectValue}  ||= '';
  $obj->{selectValues} ||= '';
  my $isSelected
    =   $params{selected}
   || ( $params{value}  &&  ($params{value} eq $obj->{selectValue}  ||  $obj->{selectValues} =~ m{  (?: \A | [,])  \s*  \Q$params{value}\E  \s*  (?:  \z | [,])  }xms) )
    ;
  return "<option " . $obj->_packTagAttribs(%params) . ($isSelected ? " selected='selected'" : '')  .  ">$params{content}</option>\n";
}
#--------------------------------------------------------------------------------------------
1;
