package O2::Context;

# This class is used on most objects to set them in a "site context".
# It will in other words figure out what config files to use, and give you access to common objects in that context.

use strict;

use O2::Util::List qw(upush);
use Locale::Util qw(parse_http_accept_language);

#------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  
  my $obj = bless {}, $pkg;
  
  $obj->{env}      = {};
  $obj->{dbhStack} = [];
  
  $obj->setEnv( 'O2ROOT',         delete $init{O2ROOT}         ) if exists $init{O2ROOT};
  $obj->setEnv( 'O2CMSROOT',      delete $init{O2CMSROOT}      ) if exists $init{O2CMSROOT};
  $obj->setEnv( 'O2CUSTOMERROOT', delete $init{O2CUSTOMERROOT} ) if exists $init{O2CUSTOMERROOT};
  $obj->setEnv( 'PERL5LIB',       delete $init{PERL5LIB}       ) if exists $init{PERL5LIB};
  
  foreach my $key (keys %init) {
    $obj->{$key} = $init{$key};
  }
  
  $obj->setHostname( $init{hostname} ) if $init{hostname};
  $main::context ||= $obj;
  
  $obj->loadPlugins();
  
  return $obj;
}
#------------------------------------------------------------------
sub loadPlugins {
  my ($obj) = @_;
  my $pluginsPath = $obj->getCustomerPath() . '/etc/conf/plugins.conf';
  $obj->{plugins} = -e $pluginsPath  ?  do $pluginsPath  :  [];
  foreach my $plugin (@{ $obj->{plugins} }) {
    unshift @INC, "$plugin->{root}/lib";
  }
  $obj->deleteRootPathCache();
}
#------------------------------------------------------------------
sub deleteRootPathCache {
  my ($obj) = @_;
  delete $obj->{rootPaths} if exists $obj->{rootPaths};
}
#------------------------------------------------------------------
sub getLang {
  my ($obj) = @_;
  return $obj->{lang} if $obj->{lang};
  
  my @resourcePaths = $obj->getResourcePaths();
  
  require O2::Lang::I18N;
  $obj->{lang} = O2::Lang::I18N->new(
    locale       => $obj->getLocaleCode(),
    resourcePath => join (';', @resourcePaths),
  );
  return $obj->{lang};
}
#------------------------------------------------------------------
sub getCgi {
  my ($obj) = @_;
  return $O2::cgi || $obj->{cgi};
}
#------------------------------------------------------------------
sub getBackendSession {
  my ($obj) = @_;
  return $obj->{backendSession} if $obj->{backendSession};
  
  return unless $obj->cmsIsEnabled();
  
  my $backendSessionCookieName = $obj->getConfig()->get('session.backend.cookieName');
  my $backendSessionId = $obj->getCgi()->getCookie($backendSessionCookieName) || $obj->getCgi()->getParam($backendSessionCookieName);
  return unless $backendSessionId;
  return $obj->{backendSession} = $obj->getSingleton('O2CMS::Backend::Session', $backendSessionId);
}
#------------------------------------------------------------------
sub setSession {
  my ($obj, $session) = @_;
  $obj->{session} = $O2::session = $session;
}
#------------------------------------------------------------------
sub getSession {
  my ($obj) = @_;
  return $obj->{session};
}
#------------------------------------------------------------------
sub getUserId {
  my ($obj) = @_;
  return $obj->{userId} if $obj->{userId};
  return if !$obj->{session} || !$obj->{session}->get('user');
  return $obj->{userId} = $obj->{session}->get('user')->{userId};
}
#------------------------------------------------------------------
sub getBackendUserId {
  my ($obj) = @_;
  return $obj->{backendUserId} if $obj->{backendUserId};
  
  my $session = $obj->getBackendSession();
  return if !$session || !$session->get('user');
  return $obj->{backendUserId} = $session->get('user')->{userId};
}
#------------------------------------------------------------------
sub getUser {
  my ($obj) = @_;
  my $userId = $obj->getUserId();
  return $userId ? $obj->getObjectById($userId) : undef;
}
#------------------------------------------------------------------
sub getBackendUser {
  my ($obj) = @_;
  my $userId = $obj->getBackendUserId();
  return $userId ? $obj->getObjectById($userId) : undef;
}
#------------------------------------------------------------------
sub setUserId {
  my ($obj, $userId) = @_;
  $obj->{userId} = $userId;
}
#------------------------------------------------------------------
# returns the userid for the admin user from db
sub getSystemUserId {
  my ($obj) = @_;
  return $obj->{systemUserId} if $obj->{systemUserId};
  
  # this allows us to specify it at the conf level key: o2.systemUserId
  $obj->{systemUserId} = $obj->getConfig()->get('o2.systemUserId');
  return $obj->{systemUserId} if $obj->{systemUserId};
  
  return unless $obj->cmsIsEnabled();
  return $obj->{systemUserId} = $obj->getSingleton('O2CMS::Mgr::AdminUserManager')->getSystemUserId();
}
#------------------------------------------------------------------
# returns database object
sub createDbh {
  my ($obj, %dbInfo) = @_;
  if (!%dbInfo) {
    %dbInfo = $obj->getConfig()->getHash('o2.database');
  }

  die 'Missing DB params' if !$dbInfo{username} || !$dbInfo{dataSource};

  require O2::DB;
  return $obj->{dbh} = O2::DB->new(%dbInfo);
}
#------------------------------------------------------------------
# Get a handle to the database of archived objects (objects that we don't need to sync from prod)
sub createArchiveDbh {
  my ($obj) = @_;
  my %dbInfo = $obj->getConfig()->getHash('o2.database');
  $dbInfo{dataSource} .= '_archive';
  return $obj->{archiveDbh} = $obj->createDbh(%dbInfo);
}
#------------------------------------------------------------------
sub getDbh {
  my ($obj) = @_;
  my $dbh = $obj->{dbh};
  $dbh  ||= $obj->{dbh} = $obj->{normalDbh} = $obj->createDbh();
  push @{ $obj->{dbhStack} }, $dbh unless @{ $obj->{dbhStack} };
  return $dbh;
}
#------------------------------------------------------------------
sub useNormalDbh {
  my ($obj) = @_;
  $obj->{normalDbh} ||= $obj->createDbh();
  $obj->{dbh} = $obj->{normalDbh};
  push @{ $obj->{dbhStack} }, $obj->{dbh};
}
#------------------------------------------------------------------
sub useArchiveDbh {
  my ($obj) = @_;
  $obj->{archiveDbh} ||= $obj->createArchiveDbh();
  $obj->{dbh} = $obj->{archiveDbh};
  push @{ $obj->{dbhStack} }, $obj->{dbh};
}
#------------------------------------------------------------------
sub usePreviousDbh {
  my ($obj) = @_;
  pop @{ $obj->{dbhStack} };
  return $obj->{dbh} = $obj->{dbhStack}->[-1];
}
#------------------------------------------------------------------
sub getConsole {
  my ($obj) = @_;
  return $obj->{console} if $obj->{console};
  require O2::Util::ConsoleLogger;
  return $obj->{console} = O2::Util::ConsoleLogger->new();
}
#------------------------------------------------------------------
sub getFwPath {
  my ($obj) = @_;
  return $obj->getEnv('O2ROOT');
}
#------------------------------------------------------------------
sub isFwPath {
  my ($obj, $path) = @_;
  require Cwd;
  $path = Cwd::realpath($path);
  my $fwPath = $obj->getFwPath();
  $fwPath    = Cwd::abs_path($fwPath) || $fwPath;
  return $path eq $fwPath;
}
#------------------------------------------------------------------
sub getCmsPath {
  my ($obj) = @_;
  return $obj->{plugins} && $obj->pluginIsEnabled('CMS')  ?  $obj->getPlugin('CMS')->{root}  :  '';
}
#------------------------------------------------------------------
sub getCustomerPath {
  my ($obj) = @_;
  return $obj->getEnv('O2CUSTOMERROOT');
}
#------------------------------------------------------------------
sub getSitePath {
  my ($obj) = @_;
  return $obj->getEnv('O2SITEROOT') || $obj->getCustomerPath();
}
#------------------------------------------------------------------
sub getRootPaths {
  my ($obj, %params) = @_;
  return @{ $obj->{rootPaths} } if $obj->{rootPaths};
  
  my @paths;
  push  @paths, $obj->getSitePath();
  upush @paths, $obj->getCustomerPath();
  push  @paths, $obj->getCmsPath() if $obj->pluginIsEnabled('CMS');
  
  if (!$params{ignorePlugins}) {
    foreach my $plugin (@{ $obj->{plugins} }) {
      unshift @paths, $plugin->{root} if $plugin->{name} ne 'CMS' && $plugin->{enabled};
    }
  }
  
  push @paths, $obj->getFwPath();
  $obj->{rootPaths} = \@paths;
  return wantarray ? @paths : \@paths;
}
#------------------------------------------------------------------
sub getResourcePaths {
  my ($obj) = @_;
  return map { "$_/var/resources" } $obj->getRootPaths();
}
#------------------------------------------------------------------
sub getConfig {
  my ($obj) = @_;
  return $obj->{config} if $obj->{config};
  
  require O2::Config;
  $obj->{config} = O2::Config->new();
  return $obj->{config};
}
#------------------------------------------------------------------
# Returns name of locale i.e. en_US
sub getLocaleCode {
  my ($obj) = @_;
  return $obj->{localeCode} if $obj->{localeCode};
  
  my $session = $obj->getSession();
  my $isFrontend = !ref $session || $session->isFrontend();
  my $isBackend  = !$isFrontend;
  
  my $localeCode;
  if ($isFrontend) {
    # Can't instantiate user here since this code might have been called during instantiation of the same user object,
    # which would lead to infinite recursion. So querying the database directly instead of calling $user->getAttribute('locale'):
    $localeCode   = $obj->getDbh()->fetch( "select value from O2_OBJ_OBJECT_VARCHAR where objectId = ? and name = 'locale'", $obj->getUserId() ) if $obj->getUserId();
    $localeCode ||= $obj->{session}->get('locale') if $obj->{session};
  }
  elsif ($obj->{session}) {
    my $userData = $obj->{session}->get('user');
    $localeCode = $userData->{locale} if $userData->{locale};
  }
  
  if (!$localeCode) {
    my @locales          = map { $_ =~ s{-}{_}xmsg; $_ } parse_http_accept_language( $ENV{HTTP_ACCEPT_LANGUAGE} );
    my @availableLocales = @{ $obj->getConfig()->get('o2.locales') };
    my %availableLocales = map { $_ => 1 } @availableLocales;
    
    my $foundLocale = 0;
  LOCALE:
    foreach my $locale (@locales) {
      if ($availableLocales{$locale}) {
        $localeCode = $locale;
        $foundLocale = 1;
        last;
      }
      foreach my $availableLocaleCode (@availableLocales) {
        if (substr ($availableLocaleCode, 0, 2) eq substr ($locale, 0, 2)) {
          $localeCode = $availableLocaleCode; # User's language is the same as a language in available locales
          $foundLocale = 1;
          last LOCALE;
        }
      }
    }
    $localeCode ||= $availableLocales[0] unless $foundLocale;
  }
  elsif (!$localeCode && $isBackend) {
    if ($session) {
      # Can't instantiate user here since this code might have been called during instantiation of the same user object,
      # which would lead to infinite recursion. So querying the database directly instead of calling $user->getAttribute('locale'):
      $localeCode = $obj->getDbh()->fetch( "select value from O2_OBJ_OBJECT_VARCHAR where objectId = ? and name = 'locale'", $obj->getUserId() ) if $obj->getUserId();
    }
    $localeCode ||= [ $obj->getBackendLocales() ]->[0];
  }
  
  if ($isBackend) {
    # Make sure the locale is among the available locales for the backend
    my @availableBackendLocales = $obj->getBackendLocales();
    my %availableBackendLocales = map { $_ => 1 } @availableBackendLocales;
    $localeCode = $availableBackendLocales[0] unless $availableBackendLocales{$localeCode};
  }
  
  $localeCode ||= $obj->getConfig()->get('o2.defaultLocale');
  return $obj->{localeCode} = $localeCode;
}
#------------------------------------------------------------------
sub getBackendLocales {
  my ($obj) = @_;
  return @{ $obj->getConfig()->get('o2.backendLocales') };
}
#------------------------------------------------------------------
sub setLocale {
  my ($obj, $locale) = @_;
  $obj->{locale}     = $locale;
  $obj->{localeCode} = $locale->getLocale();
}
#------------------------------------------------------------------
sub setLocaleCode {
  my ($obj, $localeCode) = @_;
  $obj->{localeCode} = $localeCode;
  $obj->{locale}     = undef;
}
#------------------------------------------------------------------
sub getLocale {
  my ($obj) = @_;
  return $obj->{locale} if $obj->{locale};
  return $obj->{locale} = $obj->getSingleton('O2::Lang::LocaleManager')->getLocale( $obj->getLocaleCode() );
}
#------------------------------------------------------------------
sub getUniversalManager {
  my ($obj) = @_;
  return $obj->getSingleton('O2::Mgr::UniversalManager');
}
#------------------------------------------------------------------
sub getUniversalMgr {
  my ($obj) = @_;
  return $obj->getUniversalManager();
}
#------------------------------------------------------------------
sub getObjectById {
  my ($obj, $objectId) = @_;
  die "getObjectById() called without objectId" unless $objectId;
  return $obj->getUniversalManager()->getObjectById($objectId);
}
#------------------------------------------------------------------
sub getObjectsByIds {
  my ($obj, @objectIds) = @_;
  return $obj->getUniversalManager()->getObjectsByIds(@objectIds);
}
#------------------------------------------------------------------
sub getHostname {
  my ($obj) = @_;
  return $obj->{hostname} if $obj->{hostname};
  
  my $config = $obj->getConfig();
  return $obj->{hostname} = $config->get( 'servers.' . $config->getServerId() );
}
#------------------------------------------------------------------
sub setHostname {
  my ($obj, $hostname) = @_;
  $obj->{hostname} = $hostname;
}
#------------------------------------------------------------------
sub isBackend {
  my ($obj) = @_;
  return $obj->{isBackend} if exists $obj->{isBackend};
  
  my $userId = $obj->getUserId();
  return $obj->{isBackend} = 0 unless $userId;
  
  my $user = $obj->getObjectById($userId);
  return $obj->{isBackend} = ref $user eq 'O2CMS::Obj::AdminUser';
}
#------------------------------------------------------------------
sub isFrontend {
  my ($obj) = @_;
  return !$obj->isBackend();
}
#------------------------------------------------------------------
sub getSingleton {
  my ($obj, $module, @params) = @_;
  $obj->{singletons} = {} unless $obj->{singletons};
  my $key = $obj->_getSingletonKey($module, @params);
  return $obj->{singletons}->{$key} if $obj->{singletons}->{$key};
  
  my $object = $obj->_instantiate( _className => $module, @params );
  die "Couldn't instantiate $module" unless $object;
  
  return $obj->{singletons}->{$key} = $object;
}
#------------------------------------------------------------------
sub _getSingletonKey {
  my ($obj, $module, @params) = @_;
  return $module unless @params;
  
  my $key = $module;
  $key   .= ',' . shift @params if @params % 2 == 1;
  
  while (ref $params[0]) { # Obviously not a hash key
    $key .= ',' . shift (@params) . ',' . shift @params;
  }
  
  my %params = @params;
  foreach (sort keys %params) {
    $key .= ",$_:$params{$_}";
  }
  return $key;
}
#------------------------------------------------------------------
sub _instantiate {
  my ($obj, @params) = @_;
  my ($constructorName, $className, @newParams) = ('new');
  while (@params) {
    my $param = shift @params;
    if ($param eq 'constructorName') {
      $constructorName = shift @params;
      next;
    }
    if ($param eq '_className') {
      $className = shift @params;
      next;
    }
    push @newParams, $param;
  }
  
  my $classNameAsPath = $className;
  $classNameAsPath    =~ s{::}{/}g;
  $classNameAsPath   .= '.pm';

  eval {
    require $classNameAsPath;
  };
  die "Could not require '$classNameAsPath': $@" if $@;
  die "Could not find constructor '$constructorName' in '$className'" unless $className->can($constructorName);
  
  my $class = $className->$constructorName(@newParams);
  die "Constructor did not return an object when called with 'className"."->$constructorName( .. )'" unless ref $class;
  
  return $class;
}
#------------------------------------------------------------------
sub getDateFormatter {
  my ($obj) = @_;
  return $obj->getSingleton( 'O2::Util::DateFormat', $obj->getLocale() );
}
#------------------------------------------------------------------
sub getTrashcan {
  my ($obj) = @_;
  my $trashcanId = $obj->getTrashcanId();
  return $obj->getObjectById($trashcanId) if $trashcanId;
}
#------------------------------------------------------------------
sub getTrashcanId {
  my ($obj) = @_;
  my $trashcanId = $obj->getDbh()->fetch("select max(objectId) from O2_OBJ_OBJECT where className = 'O2CMS::Obj::Trashcan' and status not in ('trashed', 'trashedAncestor', 'deleted')");
  return $trashcanId if $trashcanId;
  die "Couldn't find trashcan"; # Serious error
}
#------------------------------------------------------------------
sub isAjaxRequest {
  my ($obj) = @_;
  return $obj->getCgi()->getParam('isAjaxRequest');
}
#------------------------------------------------------------------
sub getObjectCacher {
  my ($obj) = @_;
  return $obj->getMemcached();
}
#------------------------------------------------------------------
sub getFileCacher {
  my ($obj) = @_;
  return $obj->{__fileCacher} if $obj->{__filerCacher};
  return $obj->{__fileCacher} = $obj->getSingleton('O2::Util::SimpleCache', dataStore => 'files');
}
#------------------------------------------------------------------
# Returns a cache object with standard API. Which object you actually get depends on cache.conf
sub getMemcached {
  my ($obj, $reloadCacheHandler) = @_;
  return $obj->{__memcached} if $obj->{__memcached} && !$reloadCacheHandler;
  
  require O2::Cache::Init;
  return $obj->{__memcached} = O2::Cache::Init::initCacheHandler();
}
#------------------------------------------------------------------
# If, for example, caching has been turned on after getMemcached was called, we don't want the Dummy handler anymore
sub reloadCacheHandler {
  my ($obj) = @_;
  return $obj->getMemcached(1);
}
#------------------------------------------------------------------
sub enableCache {
  my ($obj) = @_;
  $obj->getMemcached()->enableCache();
}
#------------------------------------------------------------------
sub enableObjectCache {
  my ($obj) = @_;
  $obj->getMemcached()->enableObjectCache();
}
#------------------------------------------------------------------
sub enableDbCache {
  my ($obj) = @_;
  $obj->getMemcached()->enableSQLCache();
}
#------------------------------------------------------------------
sub disableCache {
  my ($obj) = @_;
  $obj->getMemcached()->disableCache();
}
#------------------------------------------------------------------
sub disableObjectCache {
  my ($obj) = @_;
  $obj->getMemcached()->disableObjectCache();
}
#------------------------------------------------------------------
sub disableDbCache {
  my ($obj) = @_;
  $obj->getMemcached()->disableSQLCache();
}
#------------------------------------------------------------------
sub cacheIsEnabled {
  my ($obj) = @_;
  return $obj->{__memcached}->canCache() if $obj->{__memcached};
  return; # Don't know, so returning undef instead of 0
}
#------------------------------------------------------------------
sub objectCacheIsEnabled {
  my ($obj) = @_;
  return $obj->{__memcached}->canCacheObject() if $obj->{__memcached};
  return; # Don't know, so returning undef instead of 0
}
#------------------------------------------------------------------
sub dbCacheIsEnabled {
  my ($obj) = @_;
  return $obj->{__memcached}->canCacheSQL() if $obj->{__memcached};
  return; # Don't know, so returning undef instead of 0
}
#------------------------------------------------------------------
sub getEnv {
  my ($obj, $name) = @_;
  if (!$name) { # Return all environment variables as a hash
    return (
      %ENV,
      %{ $obj->{env} },
    );
  }
  return $obj->{env}->{$name} if $obj->{env}->{$name};
  return $obj->{env}->{$name} = $ENV{$name};
}
#------------------------------------------------------------------
sub setEnv {
  my ($obj, $name, $value) = @_;
  $obj->{env}->{$name} = $value;
}
#------------------------------------------------------------------
sub cmsIsEnabled {
  my ($obj) = @_;
  return $obj->pluginIsEnabled('CMS');
}
#------------------------------------------------------------------
sub pluginIsEnabled {
  my ($obj, $pluginName) = @_;
  foreach my $plugin (@{ $obj->{plugins} }) {
    return $plugin->{enabled} if $plugin->{name} eq $pluginName;
  }
  return 0;
}
#------------------------------------------------------------------
sub getPlugins {
  my ($obj) = @_;
  return @{ $obj->{plugins} };
}
#------------------------------------------------------------------
sub getPlugin {
  my ($obj, $name) = @_;
  foreach my $plugin (@{ $obj->{plugins} }) {
    return $plugin if $plugin->{name} eq $name;
  }
  die "Didn't find plugin '$name'";
}
#------------------------------------------------------------------
sub getPluginPath {
  my ($obj, $pluginName) = @_;
  return $obj->getPlugin($pluginName)->{root};
}
#------------------------------------------------------------------
sub toggleEnablePlugin {
  my ($obj, $pluginName) = @_;
  foreach my $plugin (@{ $obj->{plugins} }) {
    if ($plugin->{name} eq $pluginName) {
      $plugin->{enabled} = !$plugin->{enabled};
      $obj->getSingleton('O2::Data')->save( $obj->getCustomerPath() . '/etc/conf/plugins.conf', $obj->{plugins} );
      return;
    }
  }
  die "Didn't find plugin $pluginName";
}
#------------------------------------------------------------------
sub setProfilingOn {
  my ($obj) = @_;
  $obj->{profiling} = 1;
}
#------------------------------------------------------------------
sub setProfilingOff {
  my ($obj) = @_;
  $obj->{profiling} = 0;
}
#------------------------------------------------------------------
sub isProfiling {
  my ($obj) = @_;
  return $obj->{profiling};
}
#------------------------------------------------------------------
sub getClientIp {
  my ($obj) = @_;
  return $obj->getEnv('HTTP_X_FORWARDED_FOR') || $obj->getEnv('REMOTE_ADDR');
}
#------------------------------------------------------------------
sub startTransaction {
  my ($obj) = @_;
  $obj->getDbh()->startTransaction();
  $obj->getSingleton('O2::File')->startTransaction();
  return 1;
}
#-----------------------------------------------------------------------------
sub rollback {
  my ($obj) = @_;
  $obj->getDbh()->rollback();
  $obj->getSingleton('O2::File')->rollback();
  return 1;
}
#-----------------------------------------------------------------------------
sub endTransaction {
  my ($obj) = @_;
  $obj->getDbh()->endTransaction();
  $obj->getSingleton('O2::File')->endTransaction();
  return 1;
}
#-----------------------------------------------------------------------------
# set general parameters for the display methods
sub getDisplayParams {
  my ($obj, %params) = @_;
  $params{context} = $obj;
  $params{config}  = $obj->getConfig();
  $params{session} = $obj->getSession();
  $params{user}    = $obj->getUser();
  $params{q}       = { $obj->getCgi()->getParams() };
  $params{ENV}     = { $obj->getEnv()              };
  $params{locale}  = $obj->getLocale();
  $params{lang}    = $obj->getLang();
  return %params;
}
#-----------------------------------------------------------------------------
1;
