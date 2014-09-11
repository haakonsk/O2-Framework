package O2::Template::Taglibs::Html;

use strict;

use constant DEBUG => 0;
use O2 qw($context $cgi $config);

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my %methods = (
    urlMod           => '',
    link             => 'postfix',
    popupWindow      => '',
    makeFlipper      => 'postfix',
    header           => 'macro + postExecution',
    footer           => 'macro + postExecution',
    incJavascript    => 'macro + postExecution',
    postJavascript   => 'macro + postExecution',
    incStylesheet    => 'macro + postExecution',
    incMetaHeader    => 'macro + postExecution',
    incLinkTags      => 'macro + postExecution',
    addJsFile        => 'postfix',
    addJsFromFile    => 'postfix',
    addCssFile       => 'postfix',
    addCssFromFile   => 'postfix',
    addJs            => 'postfix',
    addCss           => 'postfix + singularParam',
    addMetaHeader    => 'postfix',
    addLinkTag       => 'postfix',
    pldsDump         => 'singularParam + postfix',
    objectDump       => 'singularParam + postfix',
    contentGroup     => '',
    pageBreak        => 'postfix',
    webOnly          => '',
    printOnly        => '',
    div              => '',
    allowHtml        => 'postfix',
    encodeEntities   => 'postfix + singularParam',
    backlink         => '',
    table            => 'postfix',
    img              => '',
    openingTag       => 'singularParam',
    closingTag       => 'singularParam',
    iconUrl          => '',
    pagination       => 'postfix',
    temporaryMessage => '',
  );

  my $obj = bless { parser => $params{parser} }, $package;
  $obj->{isHtmlTaglib} = 1;
  $obj->addJSFile( file => 'jquery'  );
  $obj->addJsFile( file => 'require' );
  $obj->addJsFile( file => 'base'    );

  if (!$obj->{parser}->getProperty('o2Version')) {
    my $o2Version = $config->get('version.version');
    $obj->{parser}->setProperty('o2Version', $o2Version);
  }

  $obj->{flippers}   = {};
  $obj->{stylesheet} = '';
  $obj->{cssFiles}   = {};

  $obj->{parser}->setProperty( 'charactersToEncode', $config->get('o2.encodeEntities') ? [ qw(< & > ' ") ] : [] );
  return ($obj, %methods);
}
#----------------------------------------------------
sub div {
  my ($obj, %params) = @_;
  my $timeoutSeconds = delete $params{timeout} || 1;
  my $content        = delete $params{content};
  my $src            = delete $params{src};
  $src               = 'http://' . $context->getEnv('SERVER_NAME') . $src if substr ($src, 0, 1) eq '/';
  return '<div ' . $obj->_packTagAttribs(%params) . ">$content</div>" unless $src;
  
  my $paramsStr = '';
  foreach my $key (keys %params) {
    $paramsStr .= "$key='$params{$key}' ";
  }
  $paramsStr = substr $paramsStr, 0, -1;
  require LWP::UserAgent; # XXX Maybe use HTTP::Lite instead of LWP.
  require HTTP::Request;
  my $userAgent = LWP::UserAgent->new();
  $userAgent->timeout($timeoutSeconds);
  my $request = HTTP::Request->new(GET => $src);
  $request->header( 'Cookie',     $context->getEnv('HTTP_COOKIE')     );
  $request->header( 'User-Agent', $context->getEnv('HTTP_USER_AGENT') );
  my $response = $userAgent->request($request);
  my $divContent = '';
  $divContent    = $response->content() if $response->is_success();
  return "<div $paramsStr>$divContent</div>";
}
#----------------------------------------------------
sub webOnly {
  my ($obj, %params) = @_;
  $obj->addCss(
    global => 'yes',
    class  => '@media print',
    style  => '  .o2NoPrint { display:none; }',
  );
  return qq{<span class="o2NoPrint">$params{content}</span>};
}
#----------------------------------------------------
sub printOnly {
  my ($obj, %params) = @_;
  $obj->addCss(
    global => 'yes',
    class  => '@media screen',
    style  => '  .o2NoScreen { display:none; }',
  );
  return qq{<span class="o2NoScreen">$params{content}</span>};
}
#----------------------------------------------------
sub pageBreak {
  return '<div style="page-break-before:always"></div>';
}
#----------------------------------------------------
sub contentGroup {
  my ($obj, %params) = @_;

  my $cgClass = 'contentGroup';
  my $cgStyle = 'padding: 10px;';
  my $style   = '';
  $style      = " style='background:$params{bgColor};'" if $params{bgColor};
  my $onClick = '';

  $cgStyle .= "width:$params{width};" if $params{width};

  if ($params{disabled}) {
    $cgClass = 'contentGroupDisabled';
    $cgStyle = "$cgStyle filter:alpha(opacity=40); -moz-opacity:0.4";
    $onClick = qq{ onClick="alert('This contentgroup is disabled'); return false;"};
  }
  $cgClass .= " $params{class}" if $params{class};
  $obj->addCss(
    class => $cgClass,
    style => $cgStyle,
  );
  $obj->addCss(
    class => 'contentGroupHeading',
    style => 'font-color: #000000; font-weight: bold; letter-spacing: 2px; font-family: verdana,arial,helvetica;',
  );
  return <<"END";
<fieldset class='$cgClass'$onClick$style>
  <legend class='contentGroupHeading'>$params{title}</legend>
  $params{content}
</fieldset>
END
}
#----------------------------------------------------
sub pldsDump {
  my ($obj, %params) = @_;
  require O2::Data;
  my $ref = $params{content} || $params{param};
  return "<pre>" . O2::Data::dump( $obj->{parser}->findVar($ref) ) . "</pre>"; # Emacs-trouble)
}
#----------------------------------------------------
sub objectDump {
  my ($obj, %params) = @_;
  my $variableName = $params{param};
  $variableName    =~ s{ \$ }{&\#36;}xmsg;
  my $object = $obj->{parser}->findVar( $params{param} );
  return "<font color='red'>Didn't find the object $variableName</font>" unless $object;
  
  if ($object->isSerializable()) {
    require O2::Util::Serializer;
    my $serializer = O2::Util::Serializer->new();
    return "<pre>$variableName = " . $serializer->serialize($object) . '</pre>';
  }
  if ($object->{data}->{serializedObject}) {
    return "<pre>$variableName = " . $object->{data}->{serializedObject} . '</pre>';
  }
  if ($object->can('getObjectPlds')) {
    require Data::Dumper;
    return "<pre>$variableName = " . Data::Dumper::Dumper($object->getObjectPlds()) . '</pre>';
  }
  return
      "<font color='red'>objectDump: Error dumping object $variableName.\n"
    . "Tried &#36;serializer->serialize($variableName), $variableName" . "->{data}->{serializedObject} and $variableName->getObjectPlds()</font>";
}
#----------------------------------------------------
sub header {
  my ($obj, %params) = @_;
  return if $obj->{parser}->getProperty('o2HeaderCalled'); # <o2 header> should only be run once
  $obj->{parser}->setProperty('o2HeaderCalled', 1);
  
  %params = (
    title   => 'No title',
    bgColor => 'white',
    %params
  );
  
  delete $params{bgColor} if delete $params{omitBgColor};
  
  my $title    = delete $params{title};
  my $noStyle  = delete $params{noStyle};
  my $omitBody = delete $params{omitBody};
  
  if ($params{cssReset} && $params{cssReset} > 0) {
    $obj->addCssFile(
      file         => 'reset',
      includeFirst => 1,
    );
  }
  $obj->addCssFile( file => 'defaultStyle' ) if $context->isBackend() && !$noStyle;
  
  $params{style} = "overflow : hidden; $params{style}" if delete $params{disableScrollbars};
  
  if ($params{onLoad}) {
    $obj->addJs(
      where   => 'onLoad',
      content => $params{onLoad},
    );
    delete $params{onLoad};
  }
  
  my $bodyParams = $obj->_packTagAttribs(%params);
  my $body = $omitBody ? '' : "<body $bodyParams>";
  
  my $doctype = delete $params{doctype} || '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01' . ($params{quirksMode} ? ' Transitional' : '') . '//EN">';
  my $charset = ' charset=' . $cgi->getCharacterSet();
  
  my $header .= <<EOHEADER;
$doctype
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;$charset">
<meta name="generator" content="O2 Framework">
<title>$title</title>
<o2 incMetaHeader /><o2 incLinkTags /><o2 incJavascript includeOnLoadJs="1" /><o2 incStylesheet />
$params{content}
</head>$body
EOHEADER
  
  $obj->{parser}->_parse(\$header);
  return $header;
}
#----------------------------------------------------
sub footer {
  my ($obj) = @_;
  my $footer = <<EOFOOTER;
<o2 postJavascript />
</body>
</html>
EOFOOTER
  $obj->{parser}->_parse(\$footer);
  return $footer;
}
#----------------------------------------------------
sub urlMod {
  my ($obj, %params) = @_;
  my $urlMod = $context->getSingleton('O2::Util::UrlMod');
  return $urlMod->urlMod(%params);
}
#----------------------------------------------------
sub iconUrl {
  my ($obj, %params) = @_;
  $obj->{_iconMgr} ||= $context->getSingleton('O2::Image::IconManager');
  $params{size}    ||= 16;
  if ($params{object} && $params{object}->can('getIconUrl')) {
    return $params{object}->getIconUrl( $params{size} );
  }
  return $obj->{_iconMgr}->getIconUrl( $params{action}||$params{class}||$params{content}, $params{size} ); 
}
#----------------------------------------------------
sub popupWindow {
  my ($obj, %params) = @_;
  $params{type} = '' unless exists $params{type};
  my $linkText = delete $params{content};
  
  my $url = delete $params{href} || $obj->urlMod(%params);
  $params{content} = $linkText;
  
  my $linkTitle = $params{title};
  $params{title} = $params{windowTitle};
  
  my @winParams = "url:'$url'";
  foreach my $winParam (qw/title toolbar location directories status menubar scrollbars resizable width height/) {
    if (defined $params{$winParam}) {
      $params{$winParam} ||= 'no';
      push @winParams, "$winParam:'$params{$winParam}'" ;
      delete $params{$winParam};
    }
  }

  my $onClick = "o2.openWindow.openWindow({" . join (',', @winParams) . "})";

  if ($params{onDblClick} && $params{ignoreSingleClickOnDblClick}) {
    $onClick =~ s{ \' }{\\\'}xmsg;
    $params{onClick}    = "if (!window.popupWindowTimers) { window.popupWindowTimers = []; } popupWindowTimers.push( setTimeout('$onClick', 300) ); return false;";
    $params{onDblClick} = "clearTimeout( popupWindowTimers.pop() ); clearTimeout( popupWindowTimers.pop() ); $params{onDblClick}";
  }

  if ($params{type} eq 'image' || $params{type} eq 'button') {
    $params{onClick} = $onClick;
  }
  elsif (!$params{ignoreSingleClickOnDblClick}) {
    $params{onClick} = "$onClick; return false;";
  }

  $obj->addJsFile(file => 'openwindow');

  return $obj->link(%params, title => $linkTitle);
}
#----------------------------------------------------
sub link {
  my ($obj, %params) = @_;

  my $linkTitle = delete $params{content};
  $obj->{parser}->_parse( \$linkTitle );

  my $type     = delete $params{type} || '';
  my $imageSrc = delete $params{src};

  my $url = $params{url} || $obj->urlMod(%params);
  
  if ( ($type eq 'button' || $type eq 'image') && !$params{onClick} ) {
    $params{onClick} = "location.href='$url';";
    $params{onClick} = "window.frames['$params{target}'].$params{onClick}" if $params{target};
  }

  $params{href} ||= $url;

  delete @params{qw/type src remove append appendX alter url setClass setMethod setParams setParam removeParams removeParam appendParam toggleParam absoluteURL setDispatcherPath/};
  delete $params{href} if $type eq 'button';

  if ($type eq 'image') {
    $params{border} ||= 0;
    $params{alt}    ||= $linkTitle;
  }
  my $confirmMsg = delete $params{confirmMsg} || '';
  $confirmMsg    =~ s{ \" }{&quot;}xmsg;
  $confirmMsg    =~ s{ \' }{\\\'}xmsg;
  $params{onClick} = "if (!confirm('$confirmMsg')) { return false; };" . $params{onClick} if $confirmMsg;

  # Append params{activeClass} to params{class} if current url equals link url
  my $class;
  $class = $params{activeClass} if $params{activeClass} && $url eq $cgi->getCurrentUrl();
  $params{class} = $params{class} ? "$params{class} $class" : $class if $class;
  delete $params{activeClass};

  my $attribs = $obj->_packTagAttribs(%params);

  return "<input type=button $attribs value='$linkTitle' class='button'>" if $type eq 'button';
  return "<img src='$imageSrc' $attribs>"                                 if $type eq 'image';
  return "<a $attribs>$linkTitle</a>";
}
#----------------------------------------------------
sub makeFlipper {
  my ($obj, %params) = @_;
  $params{var} =~ s{ \A \$ }{}xms;
  die "No variable-name supplied at makeFlipper" unless $params{var};
  my $color;
  require O2::Template::Taglibs::Html::Flipper;
  tie $color, 'O2::Template::Taglibs::Html::Flipper', split /\s*,\s*/, $params{values};
  $obj->{parser}->setVar( $params{var} => \$color );
  return '';
}
#----------------------------------------------------
sub postJavascript {
  my ($obj, %params) = @_;
  my $html = $obj->_getJavascripts('post', %params);
  $obj->_deleteJavascripts('post');
  return $html;
}
#----------------------------------------------------
sub _deleteJavascripts {
  my ($obj, $where) = @_;
  my $javascripts = $obj->{parser}->getProperty('javascript');
  $javascripts->{$where} = {};
  $obj->{parser}->setProperty('javascript', $javascripts);
}
#----------------------------------------------------
sub incJavascript {
  my ($obj, %params) = @_;
  $obj->_includeOnLoadJs() if $params{includeOnLoadJs};
  my $html = $obj->_getJavascripts('pre', %params);
  $obj->_deleteJavascripts('pre');
  return $html;
}
#----------------------------------------------------
sub _includeOnLoadJs {
  my ($obj, %params) = @_;
  my $storedJavascripts = $obj->{parser}->getProperty('javascript') || {};
  if ( $storedJavascripts->{onLoad} ) {
    my $initJavascript = $obj->_getPrioritizedJavascript('onLoad') . ';';
    $initJavascript    = "\nfunction _o2Init() {\n$initJavascript\nreturn;\n}\n\no2.addLoadEvent(_o2Init);" unless $context->isAjaxRequest();
    $obj->addJs(
      where   => 'post',
      content => $initJavascript,
    );
  }
}
#----------------------------------------------------
# returns javascript for "pre", "post" or "onLoad".
# statements are sorted with the priority attribute 
sub _getPrioritizedJavascript {
  my ($obj, $where) = @_;
  my $js = $obj->{parser}->getProperty('javascript');
  return '' if !$js || !exists $js->{$where};
  my %javascript = %{ $js->{$where} };

  my $javascript = '';
  foreach my $priority (sort { $a <=> $b } keys %javascript) {
    $javascript .= " // $where-priority $priority:\n";
    $javascript .= $javascript{$priority};
  }
  return $javascript;
}
#----------------------------------------------------
sub _isO2JsUrl {
  my ($obj, $url) = @_;
  return $url =~ m{ /o2 (?: www|cms ) / }xms;
}
#----------------------------------------------------
sub _getJavascripts {
  my ($obj, $where, %params) = @_;
  
  my $javascriptFiles = $obj->{parser}->getProperty('javascriptFiles');
  
  # build <script src="..."> statements
  my ($javascripts, $incJavascripts, $preJavascripts) = ('', '', '');
  if ($javascriptFiles) {
    $preJavascripts = $where eq 'pre' && !$context->isAjaxRequest() ? "if (!window.includedUrls) { window.includedUrls = new Array(); }\n" : '';
    foreach my $jsUrl (sort {$javascriptFiles->{$where}->{$a}->{index} <=> $javascriptFiles->{$where}->{$b}->{index}} keys %{$javascriptFiles->{$where}}) {
      if ($jsUrl =~ m{\ANot found:}ms) {
        my ($jsFile) = $jsUrl =~ m{\ANot found:\s*(.+)\z}ms;
        $incJavascripts .= "<!-- Didn't find javascript: $jsFile -->\n";
        warning "Didn't find javascript: $jsFile";
        next;
      }
      
      if ( $javascriptFiles->{$where}->{$jsUrl}->{browser} ) {
        my %browserMap = (
          ie  => 'IE',
          ie6 => 'IE 6',
          ie7 => 'IE 7',
        );
        my $browser = $browserMap{ lc $javascriptFiles->{$where}->{$jsUrl}->{browser} };
        $incJavascripts .= "<!--[if $browser]>\n";
      }
      my $version = $obj->{parser}->getProperty('o2Version');
      my $jsUrlWithParams = $jsUrl;
      $jsUrlWithParams   .= ($jsUrl =~ m{ [?] }xms  ?  '&amp;'  :  '?') . "v=$version" if $version;
      
      my $newIncJs = qq{<script type="text/javascript" src="$jsUrlWithParams"></script>\n};
      my $newPreJs = "includedUrls['$jsUrl'] = true;\n";
      
      if ($context->isAjaxRequest()) {
        $incJavascripts .= $newIncJs;
      }
      else {
        if ($jsUrl =~ m{ \b jquery (-\d+[.]\d+[.]\d+)? ([.]min)? [.]js \b }xms) {
          if (!$obj->{jqueryIncluded}) {
            $preJavascripts .= "includedUrls.jquery = true;\n";
            $obj->{jqueryIncluded} = 1;
            $preJavascripts .= $newPreJs;
            $incJavascripts .= $newIncJs;
          }
        }
        elsif ($jsUrl =~ m{ \b jquery-ui (-\d+[.]\d+[.]\d+)? ([.]\w+)? ([.]min)? [.]js \b }xms) {
          if (!$obj->{jqueryUiIncluded}) {
            $preJavascripts .= "includedUrls.jqueryUi  = true;\n";
            $obj->{jqueryUiIncluded} = 1;
            $preJavascripts .= $newPreJs;
            $incJavascripts .= $newIncJs;
          }
        }
        else {
          $preJavascripts .= "includedUrls['$jsUrl'] = true;\n";
          $incJavascripts .= $newIncJs;
        }
      }
      
      $incJavascripts .= "<![endif]-->\n" if $javascriptFiles->{$where}->{$jsUrl}->{browser};
    }
    $preJavascripts .= sprintf "var _o2Version = %d;\n", $obj->{parser}->getProperty('o2Version') if $where eq 'pre';
  }
  
  # build <script> inline-javascript here... </script> statements
  my $storedJavascripts = $obj->{parser}->getProperty('javascript');
  $javascripts .= $obj->_getPrioritizedJavascript($where) if $storedJavascripts;
  
  return ($preJavascripts ? "<script type='text/javascript'>\n$preJavascripts</script>\n" : '') . $incJavascripts unless $javascripts;
  return <<EOJS;
<script type='text/javascript'>$preJavascripts</script>
$incJavascripts
<script type="text/javascript">
//<!-- 
  $javascripts
//-->
</script>
EOJS
}
#----------------------------------------------------
sub incStylesheet {
  my ($obj, %params) = @_;
  my $styleSheets = '';
  my $js;
  $js = "if (!window.includedUrls) { window.includedUrls = new Array(); }\n" unless $context->isAjaxRequest();
  
  my $cssFiles = $obj->{parser}->getProperty('cssFiles');
  $obj->{parser}->setProperty('cssFiles', []); # Deleting cssFiles property
  
  my $ie6FileContent;
  my $fileMgr = $context->getSingleton('O2::File');
  my @cssFilePaths;
  if ($cssFiles) {
    foreach my $cssFile (@{$cssFiles}) {
      my $cssUrl = $obj->getCustOrO2Url($cssFile->{file}, 'css');
      if ($config->get('o2.enableIe6Support')) {
        # Ie6 can't handle more than 15 css files, so let's just find all the css and put it in one giant file. We have to do this to avoid even worse hacks.
        # Because the page may have been cached, all info must be available on the client side.
        my $filePath = $obj->_getFilePath( $cssFile->{file}, 'css' );
        next if $filePath !~ m{ / [^./]+ [.]css \z }xms && $filePath !~ m{ / [^./]+ [.]ie 6? [.]css \z }xms;
        
        if (!-e $filePath) {
          warn "$filePath does not exist";
          next;
        }
        push @cssFilePaths, $filePath;
        $ie6FileContent .= "\n\n/* $cssUrl */\n\n" . $fileMgr->getFile($filePath);
      }
      $styleSheets .= $cssFile->{html};
      $js          .= "includedUrls['$cssUrl'] = true;\n" unless $context->isAjaxRequest();
    }
    if ($ie6FileContent) {
      my $dir = $context->getCustomerPath() . '/var/www/css/ie6Tmp';
      $fileMgr->mkPath($dir) unless -e $dir;
      require Digest::MD5;
      my $fileName = Digest::MD5->md5_hex(join ' ', @cssFilePaths);
      $fileMgr->writeFile("$dir/$fileName.css", $ie6FileContent);
      $styleSheets = "<!--[if IE 6]><link rel='stylesheet' type='text/css' href='/css/ie6Tmp/$fileName.css'><![endif]-->\n" . $styleSheets;
    }
  }
  
  my $css = $obj->{parser}->getProperty('css');
  $obj->{parser}->setProperty('css', {}); # Deleting css property
  
  if ($css) {
    $styleSheets .= "\n<style type=\"text/css\">\n";
    foreach my $class (keys %{$css}) {
      next if $class eq '_plainCss';
      
      my $class = $class;
      my $style = $css->{$class} || '';
      $class    = ".$class" if $class !~ s/^_o2GlobalCSS//;
      $styleSheets .= " $class {$style}\n";
    }
    foreach my $_css (@{ $css->{_plainCss} }) {
      $styleSheets .= "$_css\n";
    }
    $styleSheets .= "\n</style>\n";
  }
  
  return '' unless $styleSheets;
  return "$styleSheets\n" . ($js ? "<script type='text/javascript'>$js</script>" : '');
}
#----------------------------------------------------
sub addCss {
  my ($obj, %params) = @_;

  $obj->{parser}->_parse( \$params{content} ) if $params{content};

  $params{class} ||= $params{param};
  $params{style} ||= $params{content};

  my $css = $obj->{parser}->getProperty('css') || {};

  if (!$params{class} || $params{class} =~ m{ \A \s* \z }xms) {
    push @{ $css->{_plainCss} }, $params{content};
  }
  else {
    my $className = ($params{global} ? '_o2GlobalCSS' : '') . $params{class};
    my $style = $params{style};
    $css->{$className} = $style;
  }
  $obj->{parser}->setProperty(css => $css);

  return '';
}
#----------------------------------------------------
# This method was added to allow to include CSS files directly into the resulting html file
# the file params must be an absolute path to the including file.
sub addCssFromFile {
  my ($obj, %params) = @_;
  my $fileMgr = $context->getSingleton('O2::File');
  $obj->{parser}->_parse( \$params{file} );
  my $path = $fileMgr->resolvePath("o2://var/www/css/$params{file}.css");
  die "No such CSS-file: $params{file}" unless $path;
  
  $params{where} ||= 'pre';
  $params{content} = $fileMgr->getFile($path);
  delete $params{file};
  $obj->addCss(%params);
  return '';
}
#----------------------------------------------------
sub addMetaHeader {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params);
  
  my $metaHeaders;
  $metaHeaders = $obj->{parser}->getProperty('metaHeaders') if $obj->{parser}->getProperty('metaHeaders');
  $metaHeaders->{ $params{httpEquiv} || $params{name} } = {
    key   => $params{httpEquiv}    ? 'httpEquiv'    : 'name',
    value => length $params{value} ? $params{value} : $params{content},
  };
  $obj->{parser}->setProperty('metaHeaders', $metaHeaders);
  return '';
}
#----------------------------------------------------
sub incMetaHeader {
  my ($obj, %params) = @_;
  my $headers = '';

  my $metaHeaders = $obj->{parser}->getProperty('metaHeaders');
  foreach my $name (keys %{$metaHeaders}) {
    my $key = $metaHeaders->{$name}->{key};
    $key    = 'http-equiv' if $key eq 'httpEquiv';
    $headers .= "<meta $key='$name' content='$metaHeaders->{$name}->{value}'>\n";
  }
  return $headers;
}
#----------------------------------------------------
sub addLinkTag {
  my ($obj, %params) = @_;
  $obj->_setupParams(\%params);
  delete $params{content};
  my $headerLinkTags = $obj->{parser}->getProperty('headerLinkTags');
  my @linkTags = $headerLinkTags ? @{$headerLinkTags} : ();
  push @linkTags, \%params;
  $obj->{parser}->setProperty('headerLinkTags', \@linkTags);
  return '';
}
#----------------------------------------------------
sub incLinkTags {
  my ($obj, %params) = @_;
  my $tags = '';
  my $linkTags = $obj->{parser}->getProperty('headerLinkTags');
  foreach my $params (@{$linkTags}) {
    $tags .= '<link ' . $obj->_packTagAttribs(%{$params}) . ">\n";
  }
  return $tags;
}
#----------------------------------------------------
sub addJs {
  my ($obj, %params) = @_;
  $params{where} ||= 'pre';
  my $content = $params{content};
  $content    = ${  $obj->{parser}->_parse( \$params{content} )  } unless $params{noParse};

  return "<script type=\"text/javascript\">$content</script>" if $params{where} eq 'here';

  my $javascript = $obj->{parser}->getProperty('javascript') || {};
  my $priority = $params{priority} || 5;
  $javascript->{ $params{where} }->{$priority} .= "$content\n";
  $obj->{parser}->setProperty(javascript => $javascript);
  return '';
}
#----------------------------------------------------
# This method was added to allow to include js files directly into the resulting html file
# the file params must be an absolute path to the included file.
sub addJsFromFile {
  my ($obj, %params) = @_;
  my $fileMgr = $context->getSingleton('O2::File');
  $obj->{parser}->_parse( \$params{file} );
  my $path = $fileMgr->resolvePath("o2://var/www/js/$params{file}.js");
  die "No such JS-file: $params{file}" unless $path;
  
  $params{where} ||= 'pre';
  $params{content} = $fileMgr->getFile($path);
  delete $params{file};
  $obj->addJs(%params);
  return '';
}
#----------------------------------------------------
sub addJsFile {
  my ($obj, %params) = @_;
  $params{where} ||= 'pre';

  my $file = ${ $obj->{parser}->_parse( \$params{file} ) };
  my $jsUrl = $obj->getCustOrO2Url($file, 'js');
  $jsUrl    = "Not found: $file" unless $jsUrl;
  my $javascripts = $obj->{parser}->getProperty('javascriptFiles') || {};
  return if exists $javascripts->{ $params{where} }->{$jsUrl};

  if ($params{where} eq 'here') {
    if (!$jsUrl) {
      warning "Didn't find javascript: $file";
      return "<!-- Didn't find javascript: $file -->\n";
    }
    my $version = $obj->{parser}->getProperty('o2Version');
    my $html = "<script type='text/javascript'>includedUrls['$jsUrl'] = true;</script>\n";
    $html   .= qq{<script type="text/javascript" src="$jsUrl?v=$version"></script>};
    if ($params{browser}) {
      $html = "<!--[if lt $params{browser}]>\n$html\n<![endif]-->";
    }
    $javascripts->{ $params{where} }->{$jsUrl} = 1;
    $obj->{parser}->setProperty(javascriptFiles => $javascripts);
    return $html;
  }

  # Need to be able to add JS files in a certain order. And be able to get the js includes rendered in the same order
  $javascripts->{ $params{where} }->{$jsUrl} = {
    index   => scalar keys %{  $javascripts->{ $params{where} }  },
    browser => $params{browser},
  };
  $obj->{parser}->setProperty(javascriptFiles => $javascripts);
  return '';
}
#----------------------------------------------------
sub replaceJsFile {
  my ($obj, $oldFile, $newFile) = @_;
  
  $oldFile = ${ $obj->{parser}->_parse(\$oldFile) };
  $oldFile = $obj->getCustOrO2Url($oldFile, 'js');
  $newFile = ${ $obj->{parser}->_parse(\$newFile ) };
  $newFile = $obj->getCustOrO2Url($newFile, 'js');
  
  my $jsFiles = $obj->{parser}->getProperty('javascriptFiles');
  while (my ($where, $files) = each %{$jsFiles}) {
    while (my ($file, $info) = each $files) {
      if ($file eq $oldFile) {
        $files->{$newFile} = $info;
        delete $files->{$oldFile};
      }
    }
  }
}
#----------------------------------------------------
sub addCssFile {
  my ($obj, %params) = @_;
  my $cssFiles     = $obj->{parser}->getProperty('cssFiles')     || [];
  my $seenCssFiles = $obj->{parser}->getProperty('seenCssFiles') || {};
  $obj->{parser}->_parse( \$params{file} ); # Allow o2 variables in file includes
  my $cssUrl = $obj->getCustOrO2Url($params{file}, 'css');
  return if $seenCssFiles->{$cssUrl};
  
  my $html = '';
  if ($cssUrl) {
    my $ieVersion = $obj->_getIeVersionForFile($cssUrl);
    my $version   = $obj->{parser}->getProperty('o2Version');
    my $url = $cssUrl . ($cssUrl =~ m{ [?] }xms ? '&amp;' : '?') . "v=$version";
    $html .= "<!--[if IE $ieVersion]>"   if $ieVersion != -1;
    $html .= '<link rel="stylesheet" type="text/css" href="' . $url . '"';
    $html .= " media=\"$params{media}\"" if $params{media};
    $html .= '>';
    $html .= '<![endif]-->'              if $ieVersion != -1;
    $html .= "\n";
  }
  else {
    $html = "<!-- Didn't find stylesheet: $params{file} -->\n";
    warning "Didn't find stylesheet: $params{file}";
  }
  return "<script type='text/javascript'>includedUrls['$cssUrl'] = true;</script>\n$html" if $params{where} && $params{where} eq 'here';
  
  $seenCssFiles->{$cssUrl} = 1;
  my $cssFileInfo = {
    file => $params{file},
    html => $html,
  };
  unshift @{$cssFiles}, $cssFileInfo     if $params{includeFirst};
  push    @{$cssFiles}, $cssFileInfo unless $params{includeFirst};
  
  $obj->{parser}->setProperty( 'cssFiles',     $cssFiles     );
  $obj->{parser}->setProperty( 'seenCssFiles', $seenCssFiles );
  
  if ($params{file} !~ m{ [.]ie }xms) {
    my @ieFiles = $obj->_getCssIeFiles( $params{file} );
    foreach my $file (@ieFiles) {
      $obj->addCssFile(
        file  => $file,
        media => $params{media},
      );
    }
  }
  return '';
}
#----------------------------------------------------
sub replaceCssFile {
  my ($obj, $oldFile, $newFile) = @_;
  
  $oldFile = ${ $obj->{parser}->_parse(\$oldFile) };
  $oldFile = $obj->getCustOrO2Url($oldFile, 'css');
  $newFile = ${ $obj->{parser}->_parse(\$newFile ) };
  $newFile = $obj->getCustOrO2Url($newFile, 'css');
  
  my $cssFiles = $obj->{parser}->getProperty('cssFiles');
  foreach my $fileInfo (@{$cssFiles}) {
    if ($fileInfo->{file} eq $oldFile) {
      $fileInfo->{file} = $newFile;
      $fileInfo->{html} =~ s{ \Q$oldFile\E }{$newFile}xms;
    }
  }
}
#----------------------------------------------------
sub temporaryMessage {
  my ($obj, %params) = @_;
  return unless $params{message};
  $obj->addJsFile(  file => 'temporaryMessage' );
  $obj->addCssFile( file => 'temporaryMessage' );
  my $type     = $params{type}     || 'info'; # or warning or error
  my $duration = $params{duration} || 5;      # seconds
  my $id       = $params{id}       || 'tmpMsg' . (int 1_000_000*rand);
  my $message  = $params{message};
  $message     =~ s{ \' }{\\\'}xmsg;
  $obj->addJs(
    where   => 'onLoad',
    content => "o2.temporaryMessage.setMessage({ type : '$type', duration : '$duration', message : '$message', id : '$id' });",
  );
  return $params{id} ? '' : "<p id='$id'></p>";
}
#----------------------------------------------------
sub _getIeVersionForFile {
  my ($obj, $file) = @_;
  if ($file =~ m{ [.]ie(.+) [.] }xms) {
    return $1;
  }
  return  0 if $file =~ m{ [.]ie }xms;
  return -1;
}
#----------------------------------------------------
sub _getCssIeFiles {
  my ($obj, $file) = @_;
  my $dir;
  ($dir, $file) = $file =~ m{ \A  (?: (.+) / )?  ([^/]+)  \z }xms;
  
  my @files = $context->getSingleton('O2::File')->scanDir('o2://var/www/css', "$file.ie*.css\$", scanAllO2Dirs => 1);
  @files    = map { $_ =~ s{ \A / .*? /css/ (.*) (?:[.]css)  }{$1}xms; $_ } @files;
  return @files;
}
#----------------------------------------------------
sub encodeEntities {
  my ($obj, %params) = @_;
  my $oldCharactersToEncode = $obj->{parser}->getProperty('charactersToEncode');
  my @newCharactersToEncode
    = lc $params{param} eq 'off' ? ()
    : lc $params{param} eq 'on'  ? qw(< & > ' ")
    :                              split //, $params{param};
  push @newCharactersToEncode, '$' if $params{encodeDollars};
  $obj->{parser}->setProperty('charactersToEncode', \@newCharactersToEncode);
  
  if ($params{content}) {
    $obj->{parser}->_parse( \$params{content} );
    $obj->{parser}->setProperty('charactersToEncode', $oldCharactersToEncode);
    return $params{content};
  }
}
#----------------------------------------------------
sub backlink {
  my ($obj, %params) = @_;
  my $text = $params{text} || 'Back';
  my $url  = $context->getEnv('HTTP_REFERER');
  return "<a href='$url' onclick='history.back(1); return false;'>$text</a>";
}
#----------------------------------------------------
sub table {
  my ($obj, %params) = @_;
  
  my $sortable = delete $params{sortable};
  if ($sortable) {
    $obj->addJsFile(  file => 'tableSortable' );
    $obj->addCssFile( file => 'tableSortable' );
  }
  
  $obj->{parser}->_parse( \$params{content} );
  
  my $id = $params{id} ||= 'o2table_' . $obj->_getRandomId();
  $params{class}        .= ' sortable' if $sortable;
  
  if (delete $params{rearrangeableRows}) {
    $obj->addJsFile( file => 'jquery'    );
    $obj->addJsFile( file => 'jquery-ui' );
    $obj->addJs(
      where   => 'post',
      content => qq{
        // Make sure we have one empty input field before any sorting is done, so that getParam will return an empty array instead of an array containing an undef element:
        var inputWrapper = document.createElement("div");
        inputWrapper.setAttribute("id", "inputWrapperFor_newRowOrderForTable_$id");
        var input = document.createElement("input");
        input.setAttribute("name", "newRowOrderForTable_${id}[]");
        input.setAttribute("type", "hidden");
        inputWrapper.appendChild(input);
        \$("#$id")[0].parentNode.appendChild(inputWrapper);
        
        \$("#$id tbody").sortable({
          cursor : "move",
          stop   : function(event, ui) {
            var inputWrapper = \$("#inputWrapperFor_newRowOrderForTable_$id")[0];
            // Delete content from inputWrapper:
            for (var i = inputWrapper.childNodes.length-1; i >= 0; i--) {
              inputWrapper.removeChild( inputWrapper.childNodes[i] );
            }
            // Create one input field for each plugin:
            \$("#$id tr").each( function(i) {
              var input = document.createElement("input");
              input.setAttribute("name", "newRowOrderForTable_${id}[]");
              input.setAttribute("type", "hidden");
              input.value += \$(this)[0].id;
              inputWrapper.appendChild(input);
            } );
          }
        });
        \$("#$id").disableSelection();
      },
    );
  }
  
  return "<table " . $obj->_packTagAttribs(%params) . ">\n$params{content}\n</table>";
}
#----------------------------------------------------
sub img {
  my ($obj, %params) = @_;
  
  my $id = delete $params{id} or die 'Required attribute "id" missing';
  
  my $image = $context->getObjectById($id);
  die "Didn't find image with id $id. It may have been deleted."           unless $image;
  die "Object with id $id is not an image. It is of class " . ref ($image) unless $image->isa('O2::Obj::Image');
  
  my $width           = delete $params{width}      || 0;
  my $height          = delete $params{height}     || 0;
  my $onTooBig        = delete $params{onTooBig}   || 'resize';
  my $onTooSmall      = delete $params{onTooSmall} || 'resize';
  my $keepAspectRatio = exists $params{keepAspectRatio} && delete $params{keepAspectRatio} eq '0' ? 0 : 1;
  debug "width: $width, height: $height, onTooBig: $onTooBig, onTooSmall: $onTooSmall, keepAspectRatio: $keepAspectRatio";
  
  my $url;
  if (   (!$width && !$height)
      || (  $image->getWidth() == $width && $image->getHeight() == $height)
      || ( ($image->getWidth() <= $width && $image->getHeight() <= $height)   &&   $onTooSmall eq 'ignore')) {
    $url = $image->getFileUrl();
    $params{width}  = $image->getImage()->getWidth();
    $params{height} = $image->getImage()->getHeight();
  }
  elsif (!$keepAspectRatio) {
    $url = $image->getScaledUrlNoAspectRatio($width, $height);
  }
  elsif ($width && $height && $width > $image->getWidth() && $height > $image->getHeight() && $onTooSmall eq 'resize') {
    $url = $image->getScaledUrl($width, $height);
  }
  elsif ($onTooBig eq 'crop') {
    $url = $image->getCroppedUrl(
      width      => $width,
      height     => $height,
      onTooBig   => $onTooBig,
      onTooSmall => $onTooSmall,
    );
  }
  else {
    $url = $image->getScaledUrl($width, $height);
  }
  
  die 'Unable to generate image url. Probably an error in your parameters, check the documentation.' unless $url;
  
  # XXX Find actual width and height of image and assign to params{width} / params{height}
  
  my $alt = delete $params{alt} || $image->getAlternateText() || '';
  $url =~ s{ \A http:// }{//}xms;
  
  return "<img src='$url' alt='$alt' " . $obj->_packTagAttribs(%params) . '>';
}
#----------------------------------------------------
sub openingTag {
  my ($obj, %params) = @_;
  my $tagName = delete $params{param};
  return "<$tagName " . $obj->_packTagAttribs(%params) . '>';
}
#----------------------------------------------------
sub closingTag {
  my ($obj, %params) = @_;
  my $tagName = delete $params{param};
  $tagName    =~ s{o2\s+}{o2:}xms;
  return "</$tagName>";
}
#----------------------------------------------------
sub pagination {
  my ($obj, %params) = @_;
  my $pagination = $obj->{parser}->getTaglibByName('Html::Pagination');
  return $pagination->pagination(%params);
}
#----------------------------------------------------
sub _packTagAttribs {
  my ($obj, @params) = @_;
  my ($i, @packedAttribs);
  for ($i = 0; $i < $#params; $i += 2) {
    next if $params[$i] eq 'content';
    my $value = $params[$i+1];
    $value    = '' unless length $value;
    $obj->{parser}->parseVars(\$value) if $value =~ m{ \$ }xms; # Stringify variables
    my $quote = $value =~ m{ [^\\] ' }xms ? '"' : "'" ;
    push @packedAttribs, "$params[$i]=$quote$value$quote";
  }
  return join ' ', @packedAttribs;
}
#----------------------------------------------------
# Parses all params and evaluetes the vars (if any)
sub _setupParams {
  my ($obj, $paramsRef) = @_;
  $obj->{rawParams} = { %{$paramsRef} };

  foreach my $key (keys %{$paramsRef}) {
    my ($matchedVariable, $ignoreError) = $obj->{parser}->matchVariable( $paramsRef->{$key} );
    if ($matchedVariable  &&  ($matchedVariable eq $paramsRef->{$key} || "^$matchedVariable" eq $paramsRef->{$key})) { # The parameter is exactly one variable (f ex: obj="$obj->getParent()")
      eval {
        $paramsRef->{$key} = $obj->{parser}->findVar($matchedVariable);
      };
      if ($@) {
        die $@ unless $ignoreError;
        $paramsRef->{$key} = undef;
      }
    }
    elsif ($matchedVariable && $paramsRef->{$key} =~ m{ \A \s* ! \s* \^? \Q$matchedVariable\E \s* \z }xms) {
      my $value;
      eval {
        $value = $obj->{parser}->findVar($matchedVariable);
      };
      die $@ if $@ && !$ignoreError;
      
      $value = eval "!$value";
      if ($@) {
        die "_setupParams: Couldn't eval '!$value': $@" unless $ignoreError;
        $value = undef;
      }
      
      $paramsRef->{$key} = $value;
    }
    elsif ( ($key eq 'content' && $paramsRef->{$key} =~ m{ \A !? \$ }xms)  ||  ($key ne 'content' && defined $paramsRef->{$key} && $paramsRef->{$key} =~ m{ \$ }xms) ) {
      $obj->{parser}->parseVars( \$paramsRef->{$key} );
    }
  }
}
#----------------------------------------------------
sub getCustOrO2Url {
  my ($obj, $file, $type) = @_;
  if ($file =~ m{ \A /o2 (?: cms )? / }xms) {
    if ($file =~ m{ \A /o2 (?: cms )? /Js-Lang }xms) {
      $obj->addJsFile(
        file  => 'O2Lang',
        where => 'here',
      );
    }
    return $file;
  }
  if ($file !~ m{ [.]$type \z }xms) {
    my $path;
    my $fileMgr = $context->getSingleton('O2::File');
    my $serverType = $config->get('o2.serverType');
    if ($serverType eq 'stage' || $serverType eq 'prod') { # Look for minified file
      $path = eval { $fileMgr->resolvePath("o2://var/www/$type/$file.min.$type") };
      $path = '' if $path && !-e $path;
      return "/$type/$file.min.$type" if $path;
    }
    $path = $fileMgr->resolvePath("o2://var/www/$type/$file.$type");
    return "/$type/$file.$type" if $path && -e $path;
  }
  return $file;
}
#----------------------------------------------------
sub _getFilePath {
  my ($obj, $file, $type) = @_;
  
  if ($file =~ m{ \A /o2 (?: www )? /(js|css)/(.*) [.]$type \z }xms) {
    my $typeDir = $1;
    $file       = $2;
    if ($typeDir ne $type) { # If there's a css file under /js, for example, which is actually the case for dateSelect css files.
      foreach my $dir ($context->getRootPaths()) {
        return "$dir/var/www/$typeDir/$file.$type" if -e "$dir/var/www/$typeDir/$file.$type";
      }
      return;
    }
  }
  
  return if $file =~ m{ \A /o2 }xms;
  
  foreach my $dir ($context->getRootPaths()) {
    return "$dir/var/www/$type" if -e "$dir/var/www/$type/$file.$type";
  }
  return;
}
#----------------------------------------------------
sub _escapeDollars {
  my ($obj, $stringRef) = @_;
  $$stringRef =~ s/\$/&#36;/g;
}
#----------------------------------------------------
sub _getRandomId {
  return int (1_000_000_000 * rand);
}
#------------------------------------------------------------------
sub _jsEscape {
  my ($obj, $string) = @_;
  if (!$obj->{jsData}) {
    require O2::Javascript::Data;
    $obj->{jsData} = O2::Javascript::Data->new();
  }
  return $obj->{jsData}->escapeForSingleQuotedString($string);
}
#------------------------------------------------------------------
1;
