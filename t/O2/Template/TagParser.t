use Test::More qw(no_plan);

require O2::Template::TagParser;
my $tagParser = O2::Template::TagParser->new();

my @variables = (
  '$a',
  '$a->{ $b->{c} }',
  '$a->[ $b->[0] ]',
  '$lang->getLocale',
  '$lang->getLocale()',
  '$a->b(  $c->d( $e->{$f}, $g->[$h] )  )',
  '$a->{$b}->{  $c->{ $d->{e} }  }',
  '$a->{"\{"}',
  '$context->getConfig->get("o2.root")',
  '$context->getConfig()->get("o2.root")',
);
my @notVariables = (
  '$',
  '$lang->getLocale ',
  '$a{0}',
);

foreach my $variable (@variables) {
  my ($variableStr, $ignoreError) = $tagParser->matchVariable($variable);
  is( $variableStr, $variable, "Is variable: \t'$variable'" );
}
foreach my $str (@notVariables) {
  my ($variableStr, $ignoreError) = $tagParser->matchVariable($str);
  isnt( $variableStr, $str, "Not variable: \t'$str'" );
}
