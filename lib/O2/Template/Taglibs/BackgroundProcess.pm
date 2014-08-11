package O2::Template::Taglibs::BackgroundProcess;

use strict;

use base 'O2::Template::Taglibs::Html';

use O2 qw($context);

#----------------------------------------------------
sub register {
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    backgroundProcess => 'postfix',
  );
  $obj->addJsFile(  file => 'taglibs/backgroundProcess' );
  $obj->addCssFile( file => 'taglibs/backgroundProcess' );
  return ($obj, %methods);
}
#----------------------------------------------------
sub backgroundProcess {
  my ($obj, %params) = @_;
  $obj->{id}        = $params{id} || $obj->_getRandomId();
  $obj->{exclusive} = $params{exclusive} || 0;
  my $command = $params{command};
  if ($command) {
    $obj->{parser}->parseVars(\$command);
  }
  else {
    my $url = $params{url} || $context->getSingleton('O2::Util::UrlMod')->urlMod(%params, absoluteURL => 1);
    $command  = "wget $url --no-cache";
    $command .= " --output-document $params{outputDocument}" if $params{outputDocument};
    if ($obj->{exclusive} && ($obj->{currentPid} = $context->getSingleton('O2::Script::Detached')->isRunning($command))) {
      $obj->addJs(
        where   => 'post',
        content => qq{ document.getElementById("submit_$obj->{id}").click(); },
      );
    }
  }
  $obj->{command} = $command;
  
  my $parser = $obj->{parser};
  $parser->pushPostExecutionMethod('startButton', $obj);
  $parser->pushMethod('progressBar', $obj);
  $parser->_parse( \$params{content} );
  $parser->_parseMacrosForTag( \$params{content}, 'startButton' );
  $parser->popMethod('progressBar', $obj);
  $parser->popMethod('startButton', $obj);
  return $params{content};
}
#----------------------------------------------------
sub progressBar {
  my ($obj, %params) = @_;
  $obj->{max}                           = $params{max};
  $obj->{showProgressBar}               = 1;
  $obj->{checkIntervalSeconds}          = $params{checkIntervalSeconds}          || 2;
  $obj->{estimateProgressBetweenChecks} = $params{estimateProgressBetweenChecks} || 0;
  $obj->{checkTimeoutSeconds}           = $params{checkTimeoutSeconds}           || 1;
  my $style = '';
  if (my $width = $params{width}) {
    $width .= 'px' if $width =~ m{ \A \d+ \z }xms; # If it's just a number, append 'px'
    $style  = qq{style="width: $width"};
  }
  return qq{<div class="progress" id="progressBarFor_$obj->{id}" $style><div></div></div>};
}
#----------------------------------------------------
sub startButton {
  my ($obj, %params) = @_;
  
  $obj->addJsFile( file => 'ajax' );
  my $html = <<"END";
<o2 use Html::Ajax />

<o2 ajaxForm setDispatcherPath="o2" setClass="Taglibs-BackgroundProcess" setMethod="startProcess" handler="backgroundProcessStarted">
  <o2 input type="hidden" name="id"                            value="$obj->{id}"                            />
  <o2 input type="hidden" name="command"                       value="$obj->{command}"                       />
  <o2 input type="hidden" name="exclusive"                     value="$obj->{exclusive}"                     />
  <o2 input type="hidden" name="max"                           value="$obj->{max}"                           />
  <o2 input type="hidden" name="onStart"                       value="$params{onStart}"                      />
  <o2 input type="hidden" name="onEnd"                         value="$params{onEnd}"                        />
  <o2 input type="hidden" name="showProgressBar"               value="$obj->{showProgressBar}"               />
  <o2 input type="hidden" name="checkIntervalSeconds"          value="$obj->{checkIntervalSeconds}"          />
  <o2 input type="hidden" name="estimateProgressBetweenChecks" value="$obj->{estimateProgressBetweenChecks}" />
  <o2 input type="hidden" name="checkTimeoutSeconds"           value="$obj->{checkTimeoutSeconds}"           />
  <o2 input type="submit" value="$params{text}" id="submit_$obj->{id}" />
</o2:ajaxForm>
END
  
  require O2::Template;
  my $template = O2::Template->newFromString($html);
  my $htmlRef = $template->parse();
  return ${$htmlRef};
}
#----------------------------------------------------
1;
