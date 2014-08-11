package O2::Lang::LocaleManager;

# Provides support for L10N resource files
# This modules uses the CLDR files from the CLDR project
#  ref: http://unicode.org/cldr
# Which basically is a set of XML files describing how e.g numbers should be formatted for a locale
#
# This version uses XPATH to retrieve data from XML
#
# Note: I need to rewrite this when I have time for it. It is not really good :-(
# Think we should opt for a lighter version of this and not fully support everything or modularize it.

use strict;

use O2 qw($context $cgi $config);
use O2::Lang::Locale;

#------------------------------------------------------------------
sub new {
  my ($package, %init) = @_;
  $init{defaultLocale}   ||= 'en_US';
  $init{localeStruct}      = undef;
  $init{defaultEncoding} ||= $cgi->getCharacterSet();
  $init{resourcePath}    ||= $context->getFwPath() . '/var/resources/cldr';
  die "Could not locate resourcePath '$init{resourcePath}'" unless -d $init{resourcePath};
  
  return bless \%init, $package;
}
#-------------------------------------------------------------------
sub getLocale {
  my ($obj, $locale) = @_;
  $locale ||= $obj->{defaultLocale};
  my $localeStruct = $obj->_getLocaleStruct($locale);
  my $localeObj = O2::Lang::Locale->new(
    locale  => $locale,
    _struct => $localeStruct,
    manager => $obj,
  );

  $localeObj->setEncoding( $obj->{defaultEncoding} ) if $obj->{defaultEncoding};
  return $localeObj;
}
#------------------------------------------------------------------
sub getInstalledLocales {
  my ($obj) = @_;
  return $context->getSingleton('O2::Data')->load("$obj->{resourcePath}/compiled/activeLocales.plds");
}
#------------------------------------------------------------------
sub getLocales {
  my ($obj) = @_;
  opendir DIR, "$obj->{resourcePath}/common/main";
  my @locales;
  foreach (readdir DIR) {
    next if $_ !~ m/^(\w\w\_\w\w)\.xml$/i;
    push @locales, $1;
  }
  closedir DIR;
  return @locales;
}
#------------------------------------------------------------------
# try to select the most sensible locale code out of a list of locales codes
sub chooseLocale {
  my ($obj, $preferredLocale, @possibleLocales) = @_;
  
  my %possibleLocales = map { $_ => 1 } @possibleLocales;

  # Try preferred locale first. Then available locales, in the order given in o2.conf
  my @locales = $config->getArray('o2.locales');
  foreach my $locale ($preferredLocale, @locales) {
    return $locale if $possibleLocales{$locale};
  }
  
  # If we end up here, it means @possibleLocales is empty
  # or contains locales that has been removed from o2.conf
  return;
}
#------------------------------------------------------------------
sub _fixLocales {
  my ($obj) = @_;
  opendir DIR, "$obj->{resourcePath}/compiled";
  foreach (readdir DIR) {
    next if $_ !~ m/^(\w\w\_\w\w).plds$/i;
    $obj->_installLocale($1);
  }
  closedir DIR;
}
#------------------------------------------------------------------
sub _installLocale {
  my ($obj, $localeId) = @_;
  my $dObj = $context->getSingleton('O2::Data');
  my $data = $dObj->load( "$obj->{resourcePath}/compiled/activeLocales.plds" );
  my $ref  = $dObj->load( "$obj->{resourcePath}/compiled/$localeId.plds"     );
  $data->{ $ref->{locale} } = {
    language  => $ref->{displayNames}->{languages}->{   $ref->{language}  },
    territory => $ref->{displayNames}->{territories}->{ $ref->{territory} },
  };
  $dObj->save("$obj->{resourcePath}/compiled/activeLocales.plds", $data);
}
#------------------------------------------------------------------
sub getTerritories {
  my ($obj) = @_;
  opendir DIR, "$obj->{resourcePath}/common/main";
  my @locales;
  foreach (readdir DIR) {
    next if $_ !~ m/^\w\w\_(\w\w)\.xml$/i;
    push @locales,$1;
  }
  closedir DIR;
  return @locales;
} 
#------------------------------------------------------------------
# returns a ref to hash with mapping of territories (countries)
# to locales eg. NO => ['nb_NO','nn_NO'],
sub getTerritoryMap {
  my ($obj) = @_;
  return $obj->{territoryMap} if $obj->{territoryMap};
  return $obj->{territoryMap} = $context->getSingleton('O2::Data')->load("$obj->{resourcePath}/compiled/territoryMap.plds");
}
#------------------------------------------------------------------
sub getSuggestedLocaleCodeForCountry {
  my ($obj, $country) = @_;
  if ($country) {
    my $territoryMap = $obj->getTerritoryMap();
    if (exists $territoryMap->{ uc $country }) {
      # We always suggest the first entry for a territory
      return $territoryMap->{ uc $country }->[0];
    }
  }
  return undef;
}
#------------------------------------------------------------------
# uses the xml from ISO as basis current valid ISO3166 contry codes
# ref: http://www.iso.org/iso/country_codes/iso_3166_code_lists.htm
sub getISO3166Codes {
  my ($obj) = @_;
  my $dObj = $context->getSingleton('O2::Data');
  my $pldsFile = "$obj->{resourcePath}/compiled/iso3166Codes.plds";
  my $isoCodes;
  if (-e $pldsFile) {
    $isoCodes = $dObj->load($pldsFile);
  }
  else { #create the plds file
    my $data = '';
    open FILE, "<:utf8", "$obj->{resourcePath}/iso_3166-1_list_en.xml";

    # quick and simple parser
    foreach my $line (<FILE>) {
      if ($line =~ m/<ISO_3166-1_Alpha-2_Code_element>(\w\w)<\/ISO_3166-1_Alpha-2_Code_element>/i) {
        push @{$isoCodes}, $1;
      }      
    }
    close FILE;
    $dObj->save($pldsFile, $isoCodes);
  }
  return wantarray ? @{$isoCodes} : $isoCodes;
}
#------------------------------------------------------------------
sub _getLocaleStruct {
  my ($obj, $locale) = @_;
  my $localeFile = "$obj->{resourcePath}/compiled/$locale.plds";
  return $obj->_compileXmlResourceFile($locale) unless -e $localeFile;
  
  my $data = '';
  open FILE, "<:utf8", $localeFile;
  {
    local $/ = undef;
    $data = <FILE>;
  }
  close FILE;
  
  return $context->getSingleton('O2::Data')->undump($data);
}
#------------------------------------------------------------------
# regenerate locale plds file below var/resources/clds/compiles/
sub compileLocale {
  my ($obj, $localeCode) = @_;
  $obj->_compileXmlResourceFile($localeCode);
}
#------------------------------------------------------------------
# This method loads a XML file and compiles it into a PLDS file
# #should be written to use some e.g. XPATH XQUERY..
sub _compileXmlResourceFile {
  my ($obj, $locale) = @_;
  
  # setup the compiled path
  mkdir "$obj->{resourcePath}/compiled" unless -d "$obj->{resourcePath}/compiled";
  
  $locale =~ s/-/_/;
  my ($language, $territory, $dialect) = split /_/, $locale;
  
  die "_compileXmlResourceFile: invalid locale '$locale', must be on format language_region (e.g. nb_NO or nb-NO IS0639.1/2 + ISO 3166)" if !$language || !$territory;
  
  # search path
  #<root, de, de-DE, de-DE-xxx>
  #<root, nb, nb-DE, nb-NO-xxx>
  my $dataRef = {};
  $dataRef->{locale} = $locale;
  
  my @paths = (
    "$obj->{resourcePath}/main/$language.xml",
    "$obj->{resourcePath}/main/${language}_$territory.xml",
    "$obj->{resourcePath}/common/main/root.xml",
    "$obj->{resourcePath}/common/main/$language.xml",
    "$obj->{resourcePath}/common/main/${language}_$territory.xml",
  );
  require XML::XPath;
  my @xpaths = map { XML::XPath->new(filename => $_) }  grep { -e $_ } @paths;
  
  #building calendar struct
  $dataRef->{calendar} = $obj->_buildCalendarStruct(@xpaths);
  #building number struct
  $dataRef->{number} = $obj->_buildNumberStruct(@xpaths);
  # displayNames
  $dataRef->{displayNames} = $obj->_buildDisplayNamesStruct(@xpaths);

  #delimiters
  $dataRef->{delimiters} = {};
  foreach my $xp (reverse @xpaths) {
    my @nodes = $xp->find('//ldml/delimiters/*')->get_nodelist();
    foreach my $node (@nodes) {
      $dataRef->{delimiters}->{ $node->getName() } = $node->string_value();
    }
  }

  #characters
  $dataRef->{characters} = {};
  foreach my $xp (reverse @xpaths) {
    my @nodes = $xp->find('//ldml/characters/*')->get_nodelist();
    foreach my $node (@nodes) {
      next if ref $node ne 'XML::XPath::Node::Element';
      my $type = $node->getAttribute('type');
      $type  ||= 'standard';
      my $value = $node->string_value();
      $dataRef->{characters}->{$type} = $value if $value ne '[]' && $value;
    }
  }

  #territory and language
  foreach my $xp (@xpaths) {
    my @nodes = $xp->find('//ldml/identity/*')->get_nodelist();
    foreach my $node (@nodes) {
      my $name = $node->getName();
      next if $name !~ m/(territory|language)/;
      $dataRef->{$name} = $node->getAttribute('type');
    }
  }

  $obj->{iso3166iso4217} = $obj->_getISO3166toISO4217Map() unless $obj->{iso3166iso4217};
  # setting iso4217 code - Currency code
  $dataRef->{iso4217} = $obj->{iso3166iso4217}->{ $dataRef->{territory} }->[0]->{iso4217};
  
  my $localePath = "$obj->{resourcePath}/compiled/$locale.plds";
  open F, '>:utf8', $localePath or die "'$localePath': $!";
  print F $context->getSingleton('O2::Data')->dump($dataRef);
  close F;

  $obj->_installLocale($locale);
  return $dataRef;
}
#------------------------------------------------------------------
sub _buildDisplayNamesStruct {
  my ($obj, @xps) = @_;
  my $data = {};
  # languages
  foreach my $xp (@xps) {
    my @nodes = $xp->find('//ldml/localeDisplayNames/languages/*')->get_nodelist();
    foreach my $child (@nodes) {
      next if ref $child ne 'XML::XPath::Node::Element' || $child->getAttribute('alt') eq 'proposed';
      my $type  = $child->getAttribute('type');
      my $value = $child->string_value();
      $data->{languages}->{$type} = $value;
    }
  }

  # scripts
  foreach my $xp (@xps) {
    my @nodes = $xp->find('//ldml/localeDisplayNames/scripts/*')->get_nodelist();
    foreach my $child (@nodes) {
      next if ref $child ne 'XML::XPath::Node::Element' || $child->getAttribute('alt') eq 'proposed';
      my $type  = $child->getAttribute('type');
      my $value = $child->string_value();
      $data->{scripts}->{$type} = $value;
    }
  }
  
  # territories
  foreach my $xp (@xps) {
    my @nodes = $xp->find('//ldml/localeDisplayNames/territories/*')->get_nodelist();
    foreach my $child (@nodes) {
      next if ref $child ne 'XML::XPath::Node::Element' || $child->getAttribute('alt') eq 'proposed';
      my $type  = $child->getAttribute('type');
      my $value = $child->string_value;
      $data->{territories}->{$type} = $value;
    }
  }

  return $data;
}
#------------------------------------------------------------------
sub _buildNumberStruct {
  my ($obj, @xps) = @_;
  my $number;
 
  #numbers - currencies
  $number->{currencies} = {};
  foreach my $xp (@xps) {
    my @nodes = $xp->find('//ldml/numbers/currencies/currency')->get_nodelist();
    foreach my $node (@nodes) {
      my $type = $node->getAttribute('type');
      foreach my $child ( $node->getChildNodes() ) {
        next if ref $child ne 'XML::XPath::Node::Element';
        $number->{currencies}->{$type}->{ $child->getName() } = $child->string_value();
      }
    }
  }
  
  #numbers - symbols
  $number->{symbols} = {};
  foreach my $xp (@xps) {
    my @nodes = $xp->find('//ldml/numbers/symbols/*')->get_nodelist();
    foreach my $node (@nodes) {
      next if ref $node ne 'XML::XPath::Node::Element';
      $number->{symbols}->{ $node->getName() } = $node->string_value();
    }
  }

  #measurement
  $number->{measurement} = {};
  foreach my $xp (@xps) {
    my @nodes = $xp->find('//ldml/measurement/*')->get_nodelist();
    foreach my $node (@nodes) {
      if ($node->getName() eq 'measurementSystem') {
        $number->{measurement}->{measurementSystem} = $node->getAttribute('type');
      }
      else {
        $number->{measurement}->{ $node->getName() } = $obj->_simpleUnest( $node->toString() );
      }
    }
  }

  #misc Formats XXX todo
  #decimal
  $number->{decimalFormat} = {};
  foreach my $xp (@xps) {
    $number->{decimalFormat} = $obj->_getFormats( $xp, '//ldml/numbers/decimalFormats/*', $number->{decimalFormat} );
  }
  #scienticfic
  $number->{scientificFormat} = {};
  foreach my $xp (@xps) {
    $number->{scientificFormat} = $obj->_getFormats( $xp, '//ldml/numbers/scientificFormats/*', $number->{scientificFormat} );
  }
  #percent
  $number->{percentFormat} = {};
  foreach my $xp (@xps) {
    my $path = '//ldml/numbers/percentFormats/*';
    $number->{percentFormat} = $obj->_getFormats( $xp, $path, $number->{percentFormat} );
  }

  #currency
  $number->{currencyFormat} = {};
  foreach my $xp (@xps) {
    $number->{currencyFormat} = $obj->_getFormats( $xp, '//ldml/numbers/currencyFormats/*', $number->{currencyFormat} );
  }

  return $number;
}
#------------------------------------------------------------------------------------------------------------
sub _buildCalendarStruct {
  my ($obj, @xps) = @_;
  my $calendar;
  $calendar->{calendarType} = 'gregorian';
  
  #building dateFormat
  foreach my $xp (@xps) {
    my $path = '//ldml/dates/calendars/calendar[@type = "' . $calendar->{calendarType} . '"]/dateFormats';
    my @node = $xp->find($path)->get_nodelist();
    if ($node[0]) {
      foreach my $nodeChild ( $node[0]->getChildNodes ) {
        
        if ( $nodeChild->getLocalName() eq 'default') {
          $calendar->{dateFormat}->{default} = $nodeChild->getAttribute('type');
        }
        else {
          next if ref $nodeChild ne 'XML::XPath::Node::Element';
          my $type  = $nodeChild->getAttribute('type');
          my $value = $nodeChild->findvalue($path . '/dateFormatLength[@type = "' . $type . '"]/dateFormat/pattern[@alt != "proposed"]')->value();
          $calendar->{dateFormat}->{$type} = $value if $type && $value;
        }
      }
    }
  }

  #building timeFormat
  foreach my $xp (@xps) {
    my $path = '//ldml/dates/calendars/calendar[@type = "' . $calendar->{calendarType} . '"]/timeFormats';
    my @node = $xp->find($path)->get_nodelist();
    if ($node[0]) {
      foreach my $nodeChild ( $node[0]->getChildNodes() ) {

        if ($nodeChild->getLocalName() eq 'default') {
          $calendar->{timeFormat}->{default} = $nodeChild->getAttribute('type');
        }
        else {
          next if ref $nodeChild ne 'XML::XPath::Node::Element';
          my $type  = $nodeChild->getAttribute('type');
          my $value = $nodeChild->findvalue($path.'/timeFormatLength[@type = "'.$type.'"]/timeFormat/pattern[@alt != "proposed"]')->value();
          $calendar->{timeFormat}->{$type} = $value if $type && $value;
        }
      }
    }
  }

#  building weeks props
  foreach my $xp (@xps) {
    my $path = '//ldml/dates/calendars/calendar[@type = "' . $calendar->{calendarType} . '"]/week';
    my @node = $xp->find($path)->get_nodelist();
    if ($node[0]) {
      foreach my $nodeChild ( $node[0]->getChildNodes() ) {
        next if ref $nodeChild ne 'XML::XPath::Node::Element';
        # Was "ext" - typical typo.
        next if $nodeChild->getAttribute('alt') eq 'proposed';
        my $name = $nodeChild->getName();
        %{ $calendar->{week}->{$name} } = map { $_->getName() => $_->getData() } $nodeChild->getAttributes();
      }
    }
  }

  #am /pm 
  foreach my $xp (@xps) {
    my $path = '//ldml/dates/calendars/calendar[@type = "' . $calendar->{calendarType} . '"]';
    $calendar->{timeFormat}->{am} = $xp->findvalue("$path/am")->value();
    $calendar->{timeFormat}->{pm} = $xp->findvalue("$path/pm")->value();
  }
  
#  eras
  foreach my $xp (@xps) {
    my $path = '//ldml/dates/calendars/calendar[@type = "' . $calendar->{calendarType} . '"]/eras';
    my @node = $xp->find($path)->get_nodelist();
    if ($node[0]) {
      foreach my $nodeChild ( $node[0]->getChildNodes() ) {
        next unless ref $nodeChild eq 'XML::XPath::Node::Element';
        my $name = $nodeChild->getName();
        my @childs = $nodeChild->getChildNodes();
        foreach my $eraType (@childs) {
          next if ref $eraType ne 'XML::XPath::Node::Element' || $eraType->getAttribute('alt') eq 'proposed';
          my $type = $eraType->getAttribute('type');#->getData();
          $calendar->{eras}->{$name}->{ $eraType->getName() }->{$type} = $eraType->string_value();
        }
      }
    }
  }
  
#  Months
  $calendar->{months} = {};
  foreach my $xp (reverse @xps) {
    my $path = '//ldml/dates/calendars/calendar[@type = "' . $calendar->{calendarType} . '"]/months';
    my @node = $xp->find($path)->get_nodelist();
    $calendar->{months} = $obj->_getTypeKeyMapping( $node[0], $calendar->{months} ) if $node[0];
  }

  #Months
  $calendar->{days} = {};
  foreach my $xp (reverse @xps) {
    my $path = '//ldml/dates/calendars/calendar[@type = "' . $calendar->{calendarType} . '"]/days';
    my @node = $xp->find($path)->get_nodelist();
    $calendar->{days} = $obj->_getTypeKeyMapping( $node[0], $calendar->{days} ) if $node[0];
  }

#  timeZones 
  $calendar->{timeZones} = {};
  foreach my $xp (@xps) {
    my @nodes = $xp->find('//ldml/dates/timeZoneNames/*')->get_nodelist();
    foreach my $node (@nodes){
      next unless ref $node eq 'XML::XPath::Node::Element';
      if ($node->getName() eq 'zone') {
        $calendar->{timeZones}->{zones}->{ $node->getAttribute('type') } = $obj->_simpleUnest( $node->toString() );
      }
      else {
        $calendar->{timeZones}->{ $node->getName() } = $node->string_value();
      }
    }
  }

  return $calendar;
}
#------------------------------------------------------------------
sub _getFormats {
  my ($obj, $xp, $path, $data) = @_;
  my @nodes = $xp->find($path)->get_nodelist();
  foreach my $node (@nodes) {
    next unless ref $node eq 'XML::XPath::Node::Element';
    
    my $name = $node->getName();
    my $type = $node->getAttribute('type') || 'standard';
    my @kids = $node->getChildNodes();
    
    foreach my $kid (@kids) {
      next unless ref $node eq 'XML::XPath::Node::Element';
      
      my $value = $kid->findvalue('pattern')->value();
      $data->{$name}->{$type} = $value if $value;
    }
  }
  
  return $data;
}
#------------------------------------------------------------------
sub _getTypeKeyMapping {
  my ($obj, $parentNode, $data) = @_;
  $data ||= undef;
  
  foreach my $child ( $parentNode->getChildNodes() ) {
    next if ref $child ne 'XML::XPath::Node::Element' || $child->getAttribute('alt') eq 'proposed';
    
    if ( lc ($child->getName()) eq 'default') {
      $data->{default} = $child->getAttribute('type');
    }
    else {
      my $type = $child->getAttribute('type');
      $data->{$type} = $obj->_getTypeKeyMapping( $child , $data->{$type} )  ||  $child->string_value();
    }
    
  }
  return $data;
}
#------------------------------------------------------------------
sub _simpleUnest {
  my ($obj, $content) = @_;
  require XML::Simple;
  $obj->{xmlSimple} ||= XML::Simple->new();
  require Encode;
  $content = Encode::encode('utf8', $content); # xml simple expects utf8 text
  return $obj->{xmlSimple}->XMLin($content);
}
#------------------------------------------------------------------
# compile a ISO3166 to ISO4217 mapping file based supplementalData.xml
sub _getISO3166toISO4217Map {
  my ($obj) = @_;
  
  binmode ":utf8";
  my $dObj = $context->getSingleton('O2::Data');
  my $mapFile = "$obj->{resourcePath}/compiled/iso3166_to_iso4217.plds";
  return $dObj->load($mapFile) if -e $mapFile;

  my $file = "$obj->{resourcePath}/common/supplemental/supplementalData.xml";
  require XML::XPath;
  my $xp = XML::XPath->new(filename => $file);

  my @nodes = $xp->find('//supplementalData/currencyData/*')->get_nodelist();
  
  my $currMap;
  
  foreach my $node (@nodes) {
    next if $node->getName() !~ m{region};
    my $iso3166 = $node->getAttribute('iso3166');
    my @iso4217;
    foreach my $kid ($node->getChildNodes()) {
      my $iso4217 = $kid->getAttribute('iso4217') or next;
      my $from    = $kid->getAttribute('from');
      my $to      = $kid->getAttribute('to');
      $from  =~ s{-}{}gxms;
      $from .= '0' x (8 - length $from);
      $to    =~ s{-}{}gxms;
      $to   .= '0' x (8 - length $to);
      
      push @iso4217, {
        iso4217 => $iso4217,
        from    => $from,
        to      => $to,
      };
    }
    @iso4217 = sort { $b->{from} <=> $a->{from} } @iso4217;
    @iso4217 = sort { $a->{to}   <=> $b->{to}   } @iso4217;
    $currMap->{$iso3166} = \@iso4217;
  }
  
  $dObj->save($mapFile, $currMap);
  return $currMap;
}
#------------------------------------------------------------------
1;
