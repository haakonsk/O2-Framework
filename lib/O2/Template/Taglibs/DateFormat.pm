package O2::Template::Taglibs::DateFormat;

use strict;

use O2 qw($context $config);
use HTTP::Date qw(str2time);

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;

  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    dateFormat => '',
    timeFormat => '',
  );
  
  $obj->{locale} = $params{parser}->{locale} || $context->getLocale();
  $obj->_setDateFormatObject( $params{locale} );
  
  $obj->{defaultInstallationDateFormat} = $config->get('o2.defaultDateFormat') || undef;
  return ($obj, %methods);
}
#----------------------------------------------------
# params:
# time   =  iso8601|epoch|....
# format =  short|medium|long|full or a format pattern  default: will be locale's default dateformat
# ref url for format patterns: http://www.unicode.org/reports/tr35/#Date_Format_Patterns
sub dateFormat {
  my ($obj, %params) = @_;
  my $content = $params{content};
  $obj->_pushDateFormatObject( $params{locale} );
  
  my $time = $obj->_str2time($content)  ||  ($content =~ m/^\d{8,10}$/xms ? $content : time)  ||  time;
  die "Could not parse given date '$content'" if !$time && $content !~ m/^\d+$/xms;
  
  $time ||= $content; # We assume that given time is an epoch
  
  $params{locale} ||= $obj->{parser}->getProperty('locale') || $obj->{parser}->getVar('locale') || $obj->{locale} or die "Didn't find locale object";
  $obj->{dfObj}   ||= $context->getSingleton( 'O2::Util::DateFormat', $params{locale} );
  my $formattedDate = $obj->{dfObj}->dateFormat( $time, $params{format} );
  $obj->_popDateFormatObject();
  return $formattedDate;
}
#----------------------------------------------------
sub timeFormat {
  my ($obj, %params) = @_;
  $obj->_pushDateFormatObject( $params{locale} );
  
  my $content    = $params{content};
  my $format     = $params{format} || $obj->{defaultInstallationDateFormat};
  my $localeCode = $params{locale};
  
  my $time
    = $content
    ? $obj->_date2Time($content)  ||  $obj->str2time($content)  ||  ($content =~ m{ \A \d{8,10} \z }xms  ?  $content  :  undef)
    : time
    ;
  die "Could not parse given date '$content'" unless $time;
  
  $obj->{locale} ||= $obj->{parser}->getProperty('locale');
  $obj->{dfObj}  ||= $context->getSingleton( 'O2::Util::DateFormat', $obj->{locale} );
  
  # We assume the user is providing valid format for us if this conditional fails
  if ($format && $format =~ m{ (?: full | short | medium | long ) }xms) {
    my $method = 'getTimeFormat' . ucfirst $format;
    $format = eval "\$obj->{locale}->$method";
    die "Couldn't call method '$method': $@" if $@;
  }
  
  my $formattedTime = $obj->{dfObj}->dateFormat($time, $format);
  $obj->_popDateFormatObject();
  return $formattedTime;
}
#----------------------------------------------------
sub _setDateFormatObject {
  my ($obj, $localeCode) = @_;
  return unless $localeCode;
  
  die "'$localeCode' is not a valid locale code" if $localeCode !~ m{ \A (?: \w\w | \w\w _ \w\w ) \z }xms;
  
  $obj->{locale} = $context->getSingleton('O2::Lang::LocaleManager')->getLocale($localeCode);
  $obj->{dfObj}  = $context->getSingleton('O2::Util::DateFormat', $localeCode);
}
#----------------------------------------------------
sub _pushDateFormatObject {
  my ($obj, $localeCode) = @_;
  $obj->{oldLocale} = $obj->{locale};
  $obj->{oldDfObj}  = $obj->{dfObj};
  $obj->_setDateFormatObject($localeCode);
}
#----------------------------------------------------
sub _popDateFormatObject {
  my ($obj) = @_;
  $obj->{locale} = $obj->{oldLocale};
  $obj->{dfObj}  = $obj->{oldDfObj};
}
#----------------------------------------------------
sub _date2Time {
  my ($obj, $dateTime) = @_;
  #                          year      mn    day   hour  min   sec
  return if $dateTime !~ m/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d?\d?)$/;
  my @data = ( $1, $2-1, $3, $4, $5, $6 || 0 );
  use Time::Local;
  return timelocal(reverse @data)
}
#----------------------------------------------------
sub _str2time {
  my ($obj, $str) = @_;
  return int ($str) if $str =~ m{ \A \d{9,} \z }xms;
  return str2time($str);
}
#----------------------------------------------------
1;
