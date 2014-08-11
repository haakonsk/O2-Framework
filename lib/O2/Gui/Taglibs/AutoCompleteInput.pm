package O2::Gui::Taglibs::AutoCompleteInput;

use strict;

use base 'O2::Gui';

use O2 qw($context);

#------------------------------------------------------------------
sub getSuggestions {
  my ($obj) = @_;
  my $method    = $obj->getParam('method');
  my $guiModule = $context->getSingleton( $obj->getParam('guiModule') );
  return print 'errorAuthenticationFailure' if !$context->isBackend() && $guiModule->needsAuthentication($method) && !$guiModule->authenticate($method);
  
  my $results = $guiModule->$method();
  
  my @htmlResults;
  foreach my $result ( @{$results} ) {
    my $contentHtml = $result->{contentHtml} || $result->{value};
    my $class       = $result->{class} ? qq{class="$result->{class}"} : '';
    my $onClick     = $result->{onClick} || '';
    $onClick        =~ s{ " }{&quot;}xmsg;
    print qq{<div $class onClick="$onClick" value="$result->{value}">$contentHtml</div>\n};
  }
  print ' ' unless @{$results}; # Just to avoid Internal Server Error if there are no results.
}
#------------------------------------------------------------------
1;
