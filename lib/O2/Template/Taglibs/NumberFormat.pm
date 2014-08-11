package O2::Template::Taglibs::NumberFormat;

use strict;

use O2 qw($context);
use O2::Util::NumberFormat;

#----------------------------------------------------
sub register{ # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    percentFormat => '',
    numberFormat  => 'singularParam + postfix',
    moneyFormat   => '',
    byteFormat    => '',
    sprintf       => '',
    int           => '',
  );
  
  $obj->{locale} = $params{parser}->{locale} || $context->getLocale();
  $obj->_setNumberFormatObject( $params{locale} );
  
  return ($obj, %methods);
}
#----------------------------------------------------
sub numberFormat {
  my ($obj, %params) = @_;
  $params{format} ||= delete $params{param};
  
  my ($matchedVariable, $ignoreError) = $obj->{parser}->matchVariable( $params{format} );
  $params{format} = $obj->{parser}->findVar( $params{format} ) if $matchedVariable eq $params{format};
  
  $obj->_pushNumberFormatObject( $params{locale} );
  
  $obj->{parser}->_parse( \$params{content} );
  return $params{content} if $params{content} =~ m{ macro }xms;
  
  if ($params{aggregateTo}) {
    my ($variableName) = $params{aggregateTo} =~ m{ \A \$ (\w+) \z }xms;
    die 'The value of the aggregateTo parameter must be in the form $variableName' unless $variableName;
    
    my $originalValue = $obj->{parser}->getVar($variableName) || 0;
    $params{content} ||= 0;
    $obj->{parser}->setVar( $variableName, $originalValue + $params{content} );
  }
  
  if ($params{format} eq 'mixedFraction') {
    my $formattedNumber = $obj->{nfObj}->getMixedFraction( $params{content} );
    $obj->_popNumberFormatObject();
    return $formattedNumber;
  }
  
  my $result = $obj->{nfObj}->numberFormat( $params{content} || 0,  undef,  %params );
  $result    =~ s{ \$ }{&\#36;}xmsg; # XXX Is this the right place for this?
  $obj->_popNumberFormatObject();
  return $result;
}
#----------------------------------------------------
sub percentFormat {
  my ($obj, %params) = @_;
  
  $obj->_pushNumberFormatObject( $params{locale} );
  
  my $number = $params{content} || 0;
  $number    = $number / 100 if $params{isPercentAlready};
  
  my $result = $obj->{nfObj}->percentFormat($number, undef, %params);
  $result    =~ s{ \$ }{&\#36;}xmsg; # XXX Is this the right place for this?
  $obj->_popNumberFormatObject();
  return $result;
}
#----------------------------------------------------
sub moneyFormat {
  my ($obj, %params) = @_;
  
  $obj->_pushNumberFormatObject( $params{locale} );
  
  my $result = $obj->{nfObj}->moneyFormat( $params{content} || 0,  undef,  %params );
  $result    =~ s{ \$ }{&\#36;}xmsg; # XXX Is this the right place for this?
  $obj->_popNumberFormatObject();
  return $result;
}
#----------------------------------------------------
sub byteFormat {
  my ($obj, %params) = @_;
  
  $obj->_pushNumberFormatObject( $params{locale} );
  
  my $result = $obj->{nfObj}->byteFormat( $params{content} || 0,  undef,  $params{format},  %params );
  $result =~ s{ \$ }{&\#36;}xmsg; # XXX Is this the right place for this?
  $obj->_popNumberFormatObject();
  return $result;
}
#----------------------------------------------------
sub sprintf {
  my ($obj, %params) = @_;
  return sprintf '%' . $params{format}, $params{content};
}
#----------------------------------------------------
sub _setNumberFormatObject {
  my ($obj, $localeCode) = @_;
  if (!$localeCode) {
    $obj->{nfObj} = O2::Util::NumberFormat->new( $obj->{locale}, undef, $context );
    return;
  }
  die "'$localeCode' is not a valid locale code" if $localeCode !~ m{ \A (?: \w\w | \w\w _ \w\w ) \z }xms;
  
  $obj->{locale} = $context->getSingleton('O2::Lang::LocaleManager')->getLocale($localeCode);
  $obj->{nfObj}  = O2::Util::NumberFormat->new( $obj->{locale}, undef, $context );
}
#----------------------------------------------------
sub _pushNumberFormatObject {
  my ($obj, $localeCode) = @_;
  $obj->{oldLocale} = $obj->{locale};
  $obj->{oldNfObj}  = $obj->{nfObj};
  $obj->_setNumberFormatObject($localeCode);
}
#----------------------------------------------------
sub _popNumberFormatObject {
  my ($obj) = @_;
  $obj->{locale} = $obj->{oldLocale};
  $obj->{nfObj}  = $obj->{oldNfObj};
}
#----------------------------------------------------
sub int {
  my ($ob, %params) = @_;
  return int $params{content};
}
#----------------------------------------------------
1;
