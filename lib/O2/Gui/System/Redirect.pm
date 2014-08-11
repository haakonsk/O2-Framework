package O2::Gui::System::Redirect;

use base 'O2::Gui';

use O2 qw($cgi);

#--------------------------------------------------------------------------------------------
sub redirectWithPost {
  my ($obj) = @_;
  my ($url, $paramsStr) = $obj->getParam('url') =~ m{ \A (.+) (?: \? (.*) ) \z }xms;
  $url = $cgi->urlDecode($url);
  my %params;
  my @nameValuePairs = split /&/, $paramsStr;
  foreach my $pair (@nameValuePairs) {
    my ($name, $value) = split /=/, $pair;
    $params{$name} = $value;
  }
  $obj->display(
    'redirectWithPost.html',
    url    => $url,
    params => \%params,
  );
}
#--------------------------------------------------------------------------------------------
1;
