package O2::Lang::Locale;

# Provides support for L10N methods
# This modules uses the CLDR files from the CLDR project

use strict;

use O2 qw($config);

#------------------------------------------------------------------
sub new {
  my ($package, %init) = @_;
  die __PACKAGE__ . ", no locale or LocaleManager is given" if !$init{locale} && !$init{manager};
  $init{_encoding} = 'utf-8';
  return bless \%init, $package;
}
#------------------------------------------------------------------
sub getManager {
  my ($obj) = @_;
  return $obj->{manager};
}
#------------------------------------------------------------------
sub setEncoding {
  my ($obj, $encoding) = @_;
  $obj->{_struct} = $obj->_encodeStruct( $obj->{_struct}, $encoding ); # XXX Maybe not necessary?
  $obj->{_encoding} = $encoding;
}
#------------------------------------------------------------------
sub _encodeStruct {
  my ($obj, $struct, $encoding) = @_;
  
  eval {
    if (ref $struct eq 'HASH') {
      foreach my $item (keys %{$struct}) {
        if (ref $struct->{$item} eq 'HASH' || ref $struct->{$item} eq 'ARRAY') {
          $obj->_encodeStruct( $struct->{$item}, $encoding );
        }
      }
    }
    elsif (ref $struct eq 'ARRAY') {
      for (my $i = 0; $i < @{$struct}; $i++) {
        if (ref $struct->[$i] eq 'HASH' || ref  $struct->[$i] eq 'ARRAY') {
          $obj->_encodeStruct( $struct->[$i], $encoding );
        }
        else {
          require Encode;
          no strict 'subs';
          Encode::from_to( $struct->[$i], $obj->{_encoding}, $encoding, Encode::FB_WARN );
        }
      }
    }
    else {
      require Encode;
      no strict 'subs';
      Encode::from_to($struct, $obj->{_encoding}, $encoding, Encode::FB_WARN);
    }
  };
  return $struct;
}
#------------------------------------------------------------------
sub getEncoding {
  my ($obj) = @_;
  return $obj->{_encoding};
}
#------------------------------------------------------------------
sub getLocale {
  my ($obj) = @_;
  return $obj->{locale};
}
#-----------------------------------------------------------------
sub getLocaleCode {
  my ($obj) = @_;
  return $obj->getLocale();
}
#-----------------------------------------------------------------
# returns all installed locales with natives names and territories
sub getNativeLocales {
  my ($obj) = @_;
  return %{ $obj->{manager}->getInstalledLocales() } if wantarray;
  return $obj->{manager}->getInstalledLocales();
}
#------------------------------------------------------------------
sub getLanguage {
  my ($obj) = @_;
  return $obj->{_struct}->{language};
}
#------------------------------------------------------------------
sub getTerritory {
  my ($obj) = @_;
  return $obj->{_struct}->{territory};
}
#------------------------------------------------------------------
sub getISO639 {
  my ($obj)  =@_;
  return $obj->{_struct}->{territory};
}
#------------------------------------------------------------------
sub getISO3166 {
  my ($obj) = @_;
  return $obj->{_struct}->{territory};
}
#------------------------------------------------------------------
sub getISO4217 {
  my ($obj) = @_;
  return $obj->{_struct}->{iso4217};
}
#------------------------------------------------------------------
sub getLanguageCode {
  my ($obj) = @_;
  return $obj->getISO4217();
}
#------------------------------------------------------------------
sub getLanguageName {
  my ($obj, $language) = @_;
  $language ||= $obj->{_struct}->{language};
  return ($obj->{_struct}->{displayNames}->{languages}->{$language});
}
#------------------------------------------------------------------
sub getTerritoryName {
  my ($obj, $territory) = @_;
  $territory ||= $obj->{_struct}->{territory};
  return ($obj->{_struct}->{displayNames}->{territories}->{$territory});
}
#------------------------------------------------------------------
sub getTerritoryFlagSmallIconUrl {
  my ($obj, $territory) = @_;
  $territory ||= $obj->{_struct}->{territory};
  return $config->get('o2.adminImageRootUrl') . '/locale/flag_16x11/' . lc ($territory) . '.gif';
}
#------------------------------------------------------------------
sub getScriptName {
  my ($obj, $script) = @_;
  return ($obj->{_struct}->{displayNames}->{scripts}->{$script});
}
#------------------------------------------------------------------
sub getLanguages {
  my ($obj) = @_;
  return %{ $obj->{_struct}->{displayNames}->{languages} } if wantarray;
  return $obj->{_struct}->{displayNames}->{languages};
}
#------------------------------------------------------------------
sub getCountries {
  my ($obj) = @_;
  require utf8;
  my @countries;
  foreach my $territory (sort $obj->getTerritories()) {
    next if $territory =~ m/^(\d+|\w\w)$/;
    $territory =~ s/\\x\{(\w+)\}/pack ('C', hex $1)/ge;
    utf8::decode($territory);
    push @countries, $territory;
  }
  return @countries;
}
#------------------------------------------------------------------
sub getCountryCodesAndNames {
  my ($obj, $defaultCountryCode) = @_;
  require utf8;
  my @countries;
  foreach my $countryCode ($obj->getManager()->getISO3166Codes()) {
    my $countryName = $obj->getTerritoryName($countryCode);
    next unless $countryName;
    $countryName =~ s{ \\x \{ (\w+) \} }{pack('C', hex $1)}xmsge;
    utf8::decode($countryName);
    push @countries, {
      code => $countryCode,
      name => $countryName,
    };
  }
  @countries = sort {
    # Default country before the other countries
    return -1 if $defaultCountryCode && $a->{code} eq uc $defaultCountryCode;
    return  1 if $defaultCountryCode && $b->{code} eq uc $defaultCountryCode;
    return $a->{name} cmp $b->{name};
  } @countries;
}
#------------------------------------------------------------------
sub getTerritories {
  my ($obj) = @_;
  return %{ $obj->{_struct}->{displayNames}->{territories} } if wantarray;
  return $obj->{_struct}->{displayNames}->{territories};
}
#------------------------------------------------------------------
sub getScripts {
  my ($obj) = @_;
  return %{ $obj->{_struct}->{displayNames}->{scripts} } if wantarray;
  return $obj->{_struct}->{displayNames}->{scripts};
}
#------------------------------------------------------------------
sub getCharacters {
  my ($obj) = @_;
  return $obj->{_struct}->{characters}->{standard};
}
#------------------------------------------------------------------
sub getCalendarType {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{calendarType};
}
#------------------------------------------------------------------
sub getMinimumWeekDays {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{week}->{minDays}->{count};
}
#------------------------------------------------------------------
sub getFirstDayOfWeek {
  my ($obj) = @_;
  my $firstDay = $obj->{_struct}->{calendar}->{week}->{firstDay};
  return $firstDay ? $firstDay->{day} : 'sun';
}
#------------------------------------------------------------------
sub getDateFormatDefault {
  my ($obj) = @_;
  my $default = $obj->{_struct}->{calendar}->{dateFormat}->{default};
  return $obj->{_struct}->{calendar}->{dateFormat}->{$default};
}
#------------------------------------------------------------------
sub getDateFormat {
  my ($obj, $format) = @_;
  return $obj->{_struct}->{calendar}->{dateFormat}->{$format};
}
#------------------------------------------------------------------
sub getDateFormatShort {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{dateFormat}->{short};
}
#------------------------------------------------------------------
sub getDateFormatMedium {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{dateFormat}->{medium};
}
#------------------------------------------------------------------
sub getDateFormatLong {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{dateFormat}->{long};
}
#------------------------------------------------------------------
sub getDateFormatFull {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{dateFormat}->{full};
}
#------------------------------------------------------------------
sub getTimeZones {
  my ($obj) = @_;
  print "not yet finished";
  return 'n/a';
}
#------------------------------------------------------------------
sub getAbbreviatedMonth {
  my ($obj, $idx) = @_;
  my $defaultFormat = $obj->{_struct}->{calendar}->{months}->{default} || 'format';
  return $obj->{_struct}->{calendar}->{months}->{$defaultFormat}->{abbreviated}->{$idx};
}
#------------------------------------------------------------------
sub getWideMonth {
  my ($obj, $idx) = @_;
  my $defaultFormat = $obj->{_struct}->{calendar}->{months}->{default};
  return $obj->{_struct}->{calendar}->{months}->{$defaultFormat}->{wide}->{$idx};
}
#------------------------------------------------------------------
sub getNarrowMonth {
  my ($obj, $idx) = @_;
  return $obj->{_struct}->{calendar}->{months}->{'stand-alone'}->{narrow}->{$idx};
}
#------------------------------------------------------------------
sub getMonth {
  my ($obj, $idx) = @_;
  my $defaultFormat = $obj->{_struct}->{calendar}->{months}->{default} || 'format';
  my $defaultType = $obj->{_struct}->{calendar}->{months}->{$defaultFormat}->{default} || 'wide';
  return $obj->{_struct}->{calendar}->{months}->{$defaultFormat}->{$defaultType}->{$idx};
}
#------------------------------------------------------------------
sub getAbbreviatedDay {
  my ($obj, $idx, $skipLocaleRule) = @_;
  return $obj->_getDay($idx, 'abbreviated', $skipLocaleRule);
}
#------------------------------------------------------------------
sub getNarrowDay {
  my ($obj, $idx, $skipLocaleRule) = @_;
  return $obj->_getDay($idx, 'narrow', $skipLocaleRule);
}
#------------------------------------------------------------------
sub getDay {
  my ($obj, $idx, $skipLocaleRule) = @_;
  return $obj->_getDay($idx, 'wide', $skipLocaleRule);
}
#------------------------------------------------------------------
sub _getDay {
  my ($obj, $idx, $type, $skipLocaleRule) = @_;
  my @days = qw/sun mon tue wed thu fri sat/;
  $skipLocaleRule ||= 0;
  my $defaultFormat = $obj->{_struct}->{calendar}->{days}->{default} || 'format';
  my $defaultType   = $obj->{_struct}->{calendar}->{days}->{$defaultFormat}->{default} || 'wide';
  
  if ($idx =~ m/^\d+$/) {  
    if ($skipLocaleRule || $obj->getFirstDayOfWeek() ne 'sun') { # handling that some places week starts on monday, while others has sunday
      $idx = 0 if $idx == 7;
      $idx++;
    }
    $idx = $days[$idx-1]; 
  }
  my $formatted = $obj->{_struct}->{calendar}->{days}->{$defaultFormat}->{$type}->{$idx}; # look for formatting
  $formatted  ||= $obj->{_struct}->{calendar}->{days}->{$defaultFormat}->{$defaultType}->{$idx}; # fall back to default format
  return $formatted;
}
#------------------------------------------------------------------
sub getCurrencies {
  my ($obj) = @_;
  return %{ $obj->{_struct}->{number}->{currencies} } if wantarray;
  return $obj->{_struct}->{number}->{currencies};
}
#------------------------------------------------------------------
sub getCurrencyName {
  my ($obj, $currency) = @_;
  $currency ||= $obj->getISO4217();
  return $obj->{_struct}->{number}->{currencies}->{$currency}->{displayName};
}
#------------------------------------------------------------------
sub getCurrencySymbol {
  my ($obj, $currency) = @_;
  $currency ||= $obj->getISO4217();
  return $obj->{_struct}->{number}->{currencies}->{$currency}->{symbol};
}
#------------------------------------------------------------------
sub getTimeFormatDefault {
  my ($obj) = @_;
  my $default = $obj->{_struct}->{calendar}->{timeFormat}->{default};
  return $obj->{_struct}->{calendar}->{timeFormat}->{$default};
}
#------------------------------------------------------------------
sub getTimeFormatShort {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{timeFormat}->{short};
}
#------------------------------------------------------------------
sub getTimeFormatMedium {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{timeFormat}->{medium};
}
#------------------------------------------------------------------
sub getTimeFormatLong {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{timeFormat}->{long};
}
#------------------------------------------------------------------
sub getTimeFormatFull {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{timeFormat}->{full};
}
#------------------------------------------------------------------
sub getPM {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{timeFormat}->{pm};
}
#------------------------------------------------------------------
sub getAM {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{timeFormat}->{am};
}
#------------------------------------------------------------------
sub getEraAC {
  my ($obj) = @_;
  my $ac = 1;
  return $obj->{_struct}->{calendar}->{eras}->{eraAbbr}->{$ac};
}
#------------------------------------------------------------------
sub getEraBC {
  my ($obj) = @_;
  my $bc = 0;
  return $obj->{_struct}->{calendar}->{eras}->{eraAbbr}->{$bc};
}
#------------------------------------------------------------------
sub getEraACName {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{eras}->{eraNames}->{ac};
}
#------------------------------------------------------------------
sub getEraBCName {
  my ($obj) = @_;
  return $obj->{_struct}->{calendar}->{eras}->{eraNames}->{bc};
}
#------------------------------------------------------------------
sub getPercentFormat {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{percentFormat}->{percentFormatLength}->{standard};
}
#------------------------------------------------------------------
sub getScientificFormat {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{scientificFormat}->{scientificFormatLength}->{standard};
}
#------------------------------------------------------------------
sub getDecimalFormat {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{decimalFormat}->{decimalFormatLength}->{standard};
}
#------------------------------------------------------------------
sub getCurrencyFormat {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{currencyFormat}->{currencyFormatLength}->{standard};
}
#------------------------------------------------------------------
sub getInfinitySymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{infinity};
}
#------------------------------------------------------------------
sub getPatternDigitSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{patternDigit};
}
#------------------------------------------------------------------
sub getNANSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{nan};
}
#------------------------------------------------------------------
sub getPlusSignSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{plussSign};
}
#------------------------------------------------------------------
sub getExponentialSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{exponential};
}
#------------------------------------------------------------------
sub getGroupSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{group};
}
#------------------------------------------------------------------
sub getPercentSignSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{percentSign};
}
#------------------------------------------------------------------
sub getNativeZeroDigitSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{nativeZeroDigit} || '0';
}
#------------------------------------------------------------------
sub getDecimalSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{decimal};
}
#------------------------------------------------------------------
sub getPerMilleSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{perMille};
}
#------------------------------------------------------------------
sub getMinusSignSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{minusSign};
}
#------------------------------------------------------------------
sub getListSymbol {
  my ($obj) = @_;
  return $obj->{_struct}->{number}->{symbols}->{list};
}
#------------------------------------------------------------------
1;
