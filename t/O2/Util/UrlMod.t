use strict;
use warnings;

use O2 qw($context);

my $host = $context->getHostname();
$ENV{SERVER_PROTOCOL} = 'HTTP/1.1';

use O2 qw($cgi);

# Add more tests here:
my $tests = [
  {
    currentUrl => '/',
    urlModParams => {
      setDispatcherPath => 'o2',
      setClass          => 'Newsletter-Letter',
      setMethod         => 'init',
      setParams         => 'objectId=2',
      setHash           => 'tab2',
    },
    resultUrl  => '/o2/Newsletter-Letter/init?objectId=2#tab2',
  },
  {
    currentUrl => '/someCategory/123.o2?objectId=2#tab',
    urlModParams   => {
      setDispatcherPath => 'o3',
      setClass          => 'Newsletter-Letter',
      setMethod         => 'init',
      removeParams      => 1,
    },
    resultUrl  => '/o3/Newsletter-Letter/init#tab',
  },
  {
    currentUrl => '/someCategory/123.o2?objectId=2#tab',
    urlModParams   => {
      setDispatcherPath => 'o3',
      setClass          => 'Newsletter-Letter',
      setMethod         => 'init',
      removeParams      => 1,
      setSecure         => 1,
    },
    resultUrl  => "https://$host/o3/Newsletter-Letter/init#tab",
  },
  {
    currentUrl => '/someCategory/someCategory2?a=1',
    urlModParams => {
      setDispatcherPath => 'o2',
      setClass          => 'Newsletter-Letter',
      setMethod         => 'init',
      setParam          => 'objectId=2',
    },
    resultUrl  => '/o2/Newsletter-Letter/init?a=1&objectId=2',
  },
  {
    currentUrl => '/someCategory/someCategory2?a=1',
    urlModParams => {
      setDispatcherPath => 'o2',
      setClass          => 'Newsletter-Letter',
      setMethod         => 'init',
      setParams         => 'objectId=2',
    },
    resultUrl  => '/o2/Newsletter-Letter/init?objectId=2',
  },
  {
    currentUrl => '/o2/User-Profile/loginForm#tab',
    urlModParams  => {
      setClass    => 'Newsletter-Letter',
      setMethod   => 'init',
      setParams   => 'objectId=2',
      absoluteURL => 1,
    },
    resultUrl  => "http://$host/o2/Newsletter-Letter/init?objectId=2#tab",
  },
  {
    currentUrl => '/o3/User-Profile/loginForm?a=2&b=6',
    urlModParams  => {
      setClass    => 'Newsletter-Letter',
      setMethod   => 'init',
      toggleParam => 'a=1|2|3,b=4|5|6',
    },
    resultUrl  => '/o3/Newsletter-Letter/init?a=3&b=4',
  },
  {
    currentUrl => '/o2/User-Profile/loginForm',
    urlModParams  => {
      setClass    => 'Newsletter-Letter',
      setMethod   => 'init',
      toggleParam => 'a=1|2|3,b=4|5|6',
    },
    resultUrl  => '/o2/Newsletter-Letter/init?a=1&b=4',
  },
  {
    currentUrl => '/o2/User-Profile/loginForm?a=2&b=6',
    urlModParams  => {
      setClass    => 'Newsletter-Letter',
      setMethod   => 'init',
      setParam    => 'a=1,b=2',
    },
    resultUrl  => '/o2/Newsletter-Letter/init?a=1&b=2',
  },
  {
    currentUrl => '/o2/User-Profile/loginForm?a=2&b=6',
    urlModParams  => {
      setClass    => 'Newsletter-Letter',
      setMethod   => 'init',
      setParam    => 'a=3,b=4',
    },
    resultUrl  => '/o2/Newsletter-Letter/init?a=3&b=4',
  },
  {
    currentUrl => '/o2/User-Profile/loginForm?a=2&b=6',
    urlModParams  => {
      setClass    => 'Newsletter-Letter',
      setMethod   => 'init',
      appendParam => 'a=3,b=4',
    },
    resultUrl  => '/o2/Newsletter-Letter/init?a=2&b=6&a=3&b=4',
  },
  {
    currentUrl => '/o2/InfoPage-InfoPageReports',
    urlModParams  => {
      setMethod => 'showReport',
    },
    resultUrl  => '/o2/InfoPage-InfoPageReports/showReport',
  },
  {
    currentUrl => '/o2cms',
    urlModParams  => {
      setClass  => 'User-Login',
      setMethod => 'login',
    },
    resultUrl  => '/o2cms/User-Login/login',
  },
  {
    currentUrl => '/o2cms/User-Login/login',
    urlModParams  => {
      setMethod => 'logout',
    },
    resultUrl  => '/o2cms/User-Login/logout',
  },
  { 
    currentUrl => '/o2/Shop-Order/init?offerId=154855&startDate=20080422',
    urlModParams  => {
      removeParam => 'startDate',
    },
    resultUrl  => '/o2/Shop-Order/init?offerId=154855',
  },
  { 
    currentUrl => '/o2/Shop-Order/init?offerId=154855&startDate=20080422&startDate=20080423',
    urlModParams  => {
      removeParam => 'startDate',
    },
    resultUrl  => '/o2/Shop-Order/init?offerId=154855',
  },
  { 
    currentUrl => '/lpReport/2?dates=20080417&logType=all&searchForFrom=&fromUrl=&searchForTo=&toUrl=&category=&accumulate=100&viewMode=month',
    urlModParams  => {
      setParam => 'viewMode=notAggregated',
    },
    resultUrl  => '/lpReport/2?dates=20080417&logType=all&searchForFrom=&fromUrl=&searchForTo=&toUrl=&category=&accumulate=100&viewMode=notAggregated',
  },
  { 
    currentUrl => 'http://www.vg.no?a=1',
    urlModParams  => {
      toggleParam => 'a=1|2',
    },
    resultUrl  => 'http://www.vg.no?a=2',
  },
  {
    currentUrl => 'http://lp1.linkpulse.com/lpReport/2?dates=20080502&logType=all&searchForFrom=&fromUrl=&searchForTo=&toUrl=&category=&accumulate=100&viewMode=month',
    urlModParams => {
      removeParam => "dates,viewMode,logType",
      appendParam => "viewMode=notAggregate,dates=20080502",
    },
    resultUrl  => 'http://lp1.linkpulse.com/lpReport/2?searchForFrom=&fromUrl=&searchForTo=&toUrl=&category=&accumulate=100&viewMode=notAggregate&dates=20080502',
  },
  {
    currentUrl => '/o2cms/Newsletter-Letter/testSend?listId=1314977',
    urlModParams => {
      setMethod => "testSend",
      setParams => "",
    },
    resultUrl  => '/o2cms/Newsletter-Letter/testSend',
  },
  {
    currentUrl => '/o2/Salmon-SalmonPool/listSearchResults?countyInput=17&riverSystemId=1446715&riverId=-1&skip=0',
    urlModParams => {
      setParam  => "skip=10",
    },
    resultUrl  => '/o2/Salmon-SalmonPool/listSearchResults?countyInput=17&riverSystemId=1446715&riverId=-1&skip=10',
  },
  {
    currentUrl => '/o2/Salmon-SalmonPool/listSearchResults',
    urlModParams => {
      setSecure => 1,
    },
    resultUrl  => "https://$host/o2/Salmon-SalmonPool/listSearchResults",
  },
];

use Test::More;
plan tests => scalar @{$tests} + 2;

require_ok('O2::Util::UrlMod');
my $urlMod = O2::Util::UrlMod->new();

&testGetParams;

foreach my $test (@{$tests}) {
  $cgi->setCurrentUrl( $test->{currentUrl} );
  my ($queryString) = $test->{currentUrl} =~ m{ [?] (.+) \z }xms;
  $ENV{QUERY_STRING} = $queryString if $queryString;
  my %q = $urlMod->_parseParams($queryString);
  $cgi->{params} = undef;
  foreach (keys %q) {
    $cgi->setParam( $_, $q{$_} );
  }
  my $generatedUrl = $urlMod->urlMod( %{ $test->{urlModParams} } );
  is( $generatedUrl, $test->{resultUrl} );
}


sub testGetParams {
  my $url= 'http://devlp1.linkpulse.com/lpReport/2?dates=20090730&siteIds=0&logType=all&logType=commercial&logType=editorial&logType=site&searchForFrom=url&fromUrl=&searchForTo=url&toUrl=&category=&accumulate=50&collapse=0&viewMode=month';

  my %wantedResult = (
    dates         => 20090730,
    siteIds       => 0,
    logType       => [qw(all commercial editorial site)],
    searchForFrom => 'url',
    fromUrl       => '',
    searchForTo   => 'url',
    toUrl         => '',
    category      => '',
    accumulate    => 50,
    collapse      => 0,
    viewMode      => 'month'
  );
  my %qsp = $urlMod->getParams($url);
  is_deeply( \%wantedResult, \%qsp, 'test of getParams' );    
}
