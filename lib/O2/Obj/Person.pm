package O2::Obj::Person;

use strict;

use base 'O2::Obj::Object';

use O2 qw($context);

#-----------------------------------------------------------------------------
sub isSerializable {
  return 1;
}
#-----------------------------------------------------------------------------
sub getFullName {
  my ($obj) = @_;
  my $name = $obj->getFirstName();
  $name   .= ' ' . $obj->getMiddleName() if $obj->getMiddleName();
  $name   .= ' ' . $obj->getLastName();
  return $name;
}
#-----------------------------------------------------------------------------
sub getCountry {
  my ($obj) = @_;
  return $context->getLocale()->getTerritoryName( uc $obj->getCountryCode() );
}
#-----------------------------------------------------------------------------
sub setBirthDate {
  my ($obj, $value) = @_;
  my $birthDate = $value ? $context->getSingleton('O2::Util::SwedishDates')->toSwedishDate($value) : undef;
  die "Invalid birthDate $birthDate (translated from $value)" if $birthDate && $birthDate !~ m{ \A \d{8} \z }xms;
  
  $birthDate =~ s{ \A  (\d{4})  (\d{2})  (\d{2})  \z }{$1-$2-$3 00:00:00}xms;
  $obj->setModelValue('birthDate', $birthDate);
}
#-----------------------------------------------------------------------------
sub getBirthDate {
  my ($obj, $format) = @_;
  my $birthDate = $obj->getModelValue('birthDate');
  return unless $birthDate;
  
  my $dateTime = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject();
  $dateTime->setDateTime($birthDate);
  return $format ? $dateTime->format($format) : $dateTime;
}
#-----------------------------------------------------------------------------
sub setAttribute {
  my ($obj, $name, $value) = @_;
  my %attributes = $obj->getAttributes();
  $attributes{$name} = $value;
  $obj->setAttributes(%attributes);
}
#-----------------------------------------------------------------------------
sub getAttribute {
  my ($obj, $name) = @_;
  my %attributes = $obj->getAttributes();
  return $attributes{$name};
}
#-----------------------------------------------------------------------------
sub deleteAttribute {
  my ($obj, $name) = @_;
  my %attributes = $obj->getAttributes();
  undef $attributes{$name};
  $obj->setAttributes(%attributes);
}
#-----------------------------------------------------------------------------
sub getIndexableFields {
  my ($obj) = @_;
  return ($obj->SUPER::getIndexableFields(), qw(firstName middleName lastName email cellPhone phone));
}
#-----------------------------------------------------------------------------
1;
