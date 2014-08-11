package O2::Template::Taglibs::DataDumper;

use strict;

#----------------------------------------------------
sub register {
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    dump => 'singularParam + postfix',
  );
  return ($obj, %methods);
}
#----------------------------------------------------
sub dump {
  my ($obj, %params) = @_;
  my $value = $params{param} || $params{content};
  my $unparsedValue = $value;
  $obj->{parser}->parseVars(\$value, 'externalDereference');
  
  $value = eval $value;
  die "Couldn't dump '$unparsedValue': $@" if $@;
  
  require O2::Javascript::Data;
  my $dumpedData = O2::Javascript::Data->new()->dump($value);
  $dumpedData    =~ s{ \\ \' }{\'}xmsg;
  $dumpedData    =~ s{ \A \' }{}xms;
  $dumpedData    =~ s{ \' \z }{}xms;
  
  return $dumpedData;
}
#----------------------------------------------------
1;
