use strict;

use Test::More qw(no_plan);
use O2 qw($context);

my %results = (
  'nb_NO' => {
    'D' => '36',
    'E' => '4',
    'EE' => '04',
    'EEE' => 'ons.',
    'EEEE' => 'onsdag',
    'EEEEE' => 'O',
#    'G' => undef, # XXX what is "G" supposed to do?
    'H' => '16',
    'HH' => '16',
    'K' => '4',
    'M' => '2',
    'MM' => '02',
    'MMM' => 'feb.',
    'MMMM' => 'februar',
    'MMMMM' => 'F',
    'Y' => '2008',
    'a' => '',
    'd' => '6',
    'dd' => '06',
    'e' => '3',
    'ee' => '03',
    'eee' => 'ons.',
    'eeee' => 'onsdag',
    'eeeee' => 'O',
    'h' => '4',
    'k' => '16',
    'm' => '29',
    'mm' => '29',
    's' => '29',
    'ss' => '29',
    'y' => '2008',
    'yy' => '08',
    'yyy' => '2008',
    'yyyy' => '2008',
    'yyyyy' => '02008',
  },
  en_US => {
    'D' => '36',
    'E' => '5',
    'EE' => '05',
    'EEE' => 'Wed',
    'EEEE' => 'Wednesday',
    'EEEEE' => 'Wednesday',
    'H' => '16',
    'HH' => '16',
    'K' => '4',
    'M' => '2',
    'MM' => '02',
    'MMM' => 'Feb',
    'MMMM' => 'February',
    'MMMMM' => 'F',
    'Y' => '2008',
    'a' => '',
    'd' => '6',
    'dd' => '06',
    'e' => '4',
    'ee' => '04',
    'eee' => 'Wed',
    'eeee' => 'Wednesday',
    'eeeee' => 'Wednesday',
    'h' => '4',
    'k' => '16',
    'm' => '29',
    'mm' => '29',
    's' => '29',
    'ss' => '29',
    'y' => '2008',
    'yy' => '08',
    'yyy' => '2008',
    'yyyy' => '2008',
    'yyyyy' => '02008',
  },
);

my $epoch = 1202311769;
foreach my $locale (sort keys %results) {
  my $dateFormat = $context->getSingleton('O2::Util::DateFormat', $locale);
  foreach my $format (sort keys %{ $results{$locale} }) {
    my $formatted = $dateFormat->dateFormat($epoch, $format);
    is( $formatted, $results{$locale}->{$format}, "Format $format=$formatted" );
  }
}

# DateFormat should be able to handle dates before 1970 as well.
my $dateFormatter = $context->getDateFormatter();
my $dateTime = $context->getSingleton('O2::Mgr::DateTimeManager')->newObject();
$dateTime->setDateTime('01/02/1950');
is( $dateFormatter->dateFormat($dateTime, 'yyyy.MM.dd'), '1950.02.01', 'Date before 1970 handled correctly' );
