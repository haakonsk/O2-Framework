package O2::Role::Obj::Attributes;

use strict;

use O2 qw($context);

#-----------------------------------------------------------------------------
sub setAttribute {
  my ($obj, $name, $value) = @_;
  if (ref($value) eq 'HASH' || ref($value) eq 'ARRAY') {
    $value = '_struct:' . $context->getSingleton('O2::Data')->dump($value);
  }
  my %attributes = $obj->getAttributes();
  $attributes{$name} = $value;
  $obj->setAttributes(%attributes);
}
#-----------------------------------------------------------------------------
sub getAttribute {
  my ($obj, $name) = @_;
  my %attributes = $obj->getAttributes();
  my $value = $attributes{$name};
  if ($value =~ m{ \A _struct: }xms) {
    $value =~ s{ \A _struct: }{}xms;
    $value = $context->getSingleton('O2::Data')->undump($value);
  }
  return $value;
}
#-----------------------------------------------------------------------------
1;
