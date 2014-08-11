package O2::Template::Taglibs::Html::Form::Input::AutoComplete;

use strict;

use base 'O2::Template::Taglibs::Html::Form';
use base 'O2::Template::Taglibs::JqueryUi';
use base 'O2::Role::Template::Taglibs::Html::Jquery';

#------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my $obj = bless { parser => $params{parser} }, $package;
  $obj->{parser}->registerTaglib('Html::Form');
  my %methods = (
    autoCompleteInput => 'postfix',
  );
  return ($obj, %methods);
}
#------------------------------------------------------------------
sub autoCompleteInput {
  my ($obj, %params) = @_;
  die      'name attribute is required' unless $params{name};
  die 'guiModule attribute is required' unless $params{guiModule};
  die    'method attribute is required' unless $params{method};
  
  $params{_type} = 'AutoCompleteInput';
  my $id = $params{id} ||= 'autoCompleteInput' . $obj->_getRandomId(); # Using a random ID, so we won't get elements with identical IDs when we're using ajax.
  $params{formatResultsMethod} ||= 'o2.autoCompleteInput.formatResult';
  $obj->addJsFile(  file => 'ajax'                                                          );
  $obj->addJsFile(  file => 'jquery/1.10.2/plugins/jquery-autocomplete/jquery.autocomplete' );
  $obj->addJsFile(  file => 'taglibs/html/form/input/autoComplete'                          );
  $obj->addJsFile(  file => 'jquery-migrate'                                                ); # Our version of autocomplete is not quite compatible with newer versions of jquery
  $obj->addCssFile( file => 'jquery/autocomplete'                                           );

  my $paramsString = "guiModule=$params{guiModule}&method=$params{method}&autoCompleteInputName=$params{name}";
  $paramsString   .= "&$params{params}" if $params{params};

  my $url = $obj->urlMod(
    setDispatcherPath => 'o2',
    setClass          => 'Taglibs-AutoCompleteInput',
    setMethod         => 'getSuggestions',
    setParams         => $paramsString,
  );
  my $jqueryParams = $obj->_getJqueryParamsAsString(\%params);
  my ($pre, $post) = $obj->_getPrePostForInputFieldsWithLabel(\%params);
  my %inputParams  = %params;
  $obj->_deleteJqueryParams(\%inputParams);
  delete @inputParams{qw(_type formatResultsMethod guiModule method label onClick onChange)};
  my $packedParams = $obj->_packTagAttribs(%inputParams);
  $params{hiddenValue} = '' unless length $params{hiddenValue};
  $params{onChange}    = '' unless length $params{onChange};
  return qq{<input type="hidden" name="$params{name}-hidden" value="$params{hiddenValue}" id="$id-hidden">
$pre<input $packedParams>$post
<script type="text/javascript">
  \$("#$id").autocomplete("$url", {
    formatResult : $params{formatResultsMethod},
    $jqueryParams
  }).result(function(event, row, formatted) {
    var html = row[0];
    var matches = html.match(/value=\"(.*?)\"/);
    if (matches) {
      document.getElementById("$id-hidden").value = matches[1];
    }
    eval("$params{onChange}");
  });
</script>};
}
#------------------------------------------------------------------
sub _getJqueryParams {
  return (
    # Name            -  default (undef means same default as in jquery)
    autoFill          => undef,
    cacheLength       => undef,
    delay             => undef,
    extraParams       => undef,
    formatItem        => undef,
    formatMatch       => undef,
    formatResult      => undef,
    highlight         => undef,
    matchCase         => undef,
    matchContains     => undef,
    matchSubset       => undef,
    max               => undef,
    minChars          => undef,
    multiple          => undef,
    multipleSeparator => undef,
    mustMatch         => undef,
    scroll            => undef,
    scrollHeight      => undef,
    selectFirst       => undef,
    width             => undef,
  );
}
#------------------------------------------------------------------
1;
