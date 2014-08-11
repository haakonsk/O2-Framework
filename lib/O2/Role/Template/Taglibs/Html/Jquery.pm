package O2::Role::Template::Taglibs::Html::Jquery;

use strict;

#------------------------------------------------------------------
sub _getJqueryParamsAsString {
  my ($obj, $params) = @_;
  my $paramsStr = '';
  my %jqueryParams = $obj->_getJqueryParams();
  foreach my $paramName (keys %jqueryParams) {
    my $value = delete $params->{$paramName};
    $value    = $jqueryParams{$paramName} if !defined $value || length $value == 0;
    $value    = "'$value'" if $value && $value =~ m{ \w }xms && $value !~ m{ \A \d+ \z }xms && $value ne 'true' && $value ne 'false';
    $paramsStr .= sprintf "$paramName : %s,\n", $value if length $value;
  }
  if ($paramsStr) {
    $paramsStr = substr $paramsStr, 0, -2; # Remove last comma to suit IE
  }
  return $paramsStr;
}
#------------------------------------------------------------------
sub _deleteJqueryParams {
  my ($obj, $params) = @_;
  my %jqueryParams = $obj->_getJqueryParams();
  foreach (keys %jqueryParams) {
    delete $params->{$_} if exists $jqueryParams{$_};
  }
  return 1;
}
#------------------------------------------------------------------
1;
