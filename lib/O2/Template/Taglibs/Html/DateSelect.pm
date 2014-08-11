package O2::Template::Taglibs::Html::DateSelect;

use strict;

use base 'O2::Template::Taglibs::JqueryUi';

use O2 qw($context $config);

#--------------------------------------------------------------------------------------------
sub register {
  my ($pkg, %params) = @_;
  my ($obj, %methods) = $pkg->SUPER::register(%params);
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub dateSelect {
  my ($obj, %params) = @_;
  my $dateStr = $params{epoch} || $params{value};
  my $date    = $dateStr ? $context->getSingleton('O2::Mgr::DateTimeManager')->newObject($dateStr) : undef;
  return $obj->createCalendar(
    %params,
    date => $date,
  );
}
#--------------------------------------------------------------------------------------------
sub _formatDate {
  my ($obj, $date, $format) = @_;
  return unless $date;
  return $context->getDateFormatter()->dateFormat($date, $format);
}
#--------------------------------------------------------------------------------------------
# This method converts Unicode dateFormats to valid JS calendar formats
# E.g.
# Unicode       JsClandar
# yyyy-MN-dd    %Y-%m-%d
#
# This allows us to stay with one standard within O2
sub _convertFromO2DateFormat {
  my ($obj, $o2Format) = @_;

  if ($o2Format eq 'full' || $o2Format eq 'short' || $o2Format eq 'medium' || $o2Format eq 'long') {
    $o2Format = $obj->{locale} ? $obj->{locale}->getDateFormat($o2Format) : $obj->{parser}->{locale}->getDateFormat($o2Format);
  }

  my @hits;
  my $hitId = 0;
  my @mapping = $obj->_getFromO2DateFormatMapping();
  for (my $i = 0; $i < @mapping; $i += 2) {
    while ($o2Format =~ s/$mapping[$i]/<\#$hitId\#>/) {
      push @hits, $mapping[$i+1];
      $hitId++;
    }
  }
  $hitId = 0;
  while ($o2Format =~ s/<\#(\d+)\#>/$hits[$1]/ && $hitId++ <100) {} # just in case  
  return $o2Format;
}
#--------------------------------------------------------------------------------------------
# Opposite of _convertUnicodeDateFormat2JSCalendarDateFormat
sub _convertToO2DateFormat {
  my ($obj, $format) = @_;
  return $format if -1 != index $format, '%';
  my @mapping = $obj->_getToO2DateFormatMapping();
  my @hits;
  my $hitId = 0;
  for (my $i = 0; $i < @mapping; $i += 2) {
    while ($format =~ s/$mapping[$i]/<\#$hitId\#>/) {
      push @hits, $mapping[$i+1];
      $hitId++;
    }
  }
  $hitId = 0;
  while ($format =~ s/<\#(\d+)\#>/$hits[$1]/ && $hitId++ < 100) {} # just in case  
  return $format;
}
#--------------------------------------------------------------------------------------------
sub createCalendar {
  my ($obj, %params) = @_;

  my $o2Format = delete $params{format};
  $o2Format  ||= $config->get('o2.defaultDateFormat');
  $o2Format  ||= $obj->{parser}->{locale}->getDateFormatDefault();

  my $datePickerFormat = $obj->_convertFromO2DateFormat($o2Format);

  my $formTaglib = $obj->{parser}->getTaglibByName('Html::Form');
  $formTaglib->addJsFile( file => 'taglibs/html/form/dateSelect' );

  my $html = $formTaglib->input(
    type  => 'hidden',
    name  => "o2DateSelectFormat_$params{name}",
    value => $o2Format,
  ) unless $params{noObject};

  $obj->{locale} ||= $context->getLocale();

  # Date select MUST use given language and not overide the dateformat further down with context locale when language is given
  if ( my $language = delete $params{language} ) {
    my $localeMgr = $context->getSingleton('O2::Lang::LocaleManager');
    $obj->{locale} = $language =~ m{ \A \w\w _ \w\w \z }xms ? $localeMgr->getLocale($language) : $localeMgr->getSuggestedLocaleCodeForCountry($language);
  }

  my $size  = delete $params{size}  || 10;
  my $style = delete $params{style} || ''; # Don't want to use the style attribute by default

  my $id = $params{id} || $params{name};
  my $id_trigger = "${id}_calBtn";
  die 'No id or name supplied when creating calendar' unless $id;

  my $minDate = $params{minDate} || '';
  my $maxDate = $params{maxDate} || '';
  my $setupJs = "o2.dateSelect.setupDatePickerDateSelect('$id', '$datePickerFormat', '$minDate', '$maxDate')";
  my $field = $formTaglib->input(
    %params,
    type    => 'text',
    value   =>  O2::Template::Taglibs::Html::DateSelect::_formatDate($obj, $params{date}, $o2Format) || '',
    id      => $id,
    size    => $size,
    style   => ($params{inputStyle} || $style) . ($params{hideDate} ? ';display: none;' : ''),
    onFocus => $setupJs . "; \$('#$id').datepicker('show')",
  );

  $formTaglib->addJs( content => $setupJs, where => 'post' );

  return "$html $field";
}
#--------------------------------------------------------------------------------------------
sub _getFromO2DateFormatMapping {
  my ($obj) = @_;
  return (
    EEE  => 'D',
    EEEE => 'DD',
    MMMM => 'MM',
    MMM  => 'M',
    MM   => 'mm',
    M    => 'm',
    D    => 'o',
    yyyy => 'yy',
    yy   => 'y',
  );
}
#--------------------------------------------------------------------------------------------
sub _getToO2DateFormatMapping {
  my ($obj) = @_;
  return (
    D  => 'EEE',
    DD => 'EEEE',
    MM => 'MMMM',
    M  => 'MMM',
    mm => 'MM',
    m  => 'M',
    o  => 'D',
    yy => 'yyyy',
    y  => 'yy',
  );
}
#--------------------------------------------------------------------------------------------
1;
