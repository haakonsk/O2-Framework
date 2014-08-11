package O2::Setup::IndexHtml;

use strict;

use base 'O2::Setup';

use O2 qw($context);

#-------------------------------------------------------------------------
sub install {
  my ($obj) = @_;
  print "Creating index.html\n" if $obj->verbose();
  my $setupConf = $obj->getSetupConf();
  my $hostname = $setupConf->{hostname};
  my $indexHtmlPath = "$setupConf->{customersRoot}/$setupConf->{customer}/$hostname/index.html";
  
  my $o2ml = <<"END";
<o2 use Html />
<o2 header title="$hostname" />
<h1>$hostname</h1>
<o2 footer />
END
  
  require O2::Template;
  my $template = O2::Template->newFromString($o2ml);
  my $html = ${ $template->parse() };
  $context->getSingleton('O2::File')->writeFile($indexHtmlPath, $html);
  
  return 1;
}
#-------------------------------------------------------------------------
1;
