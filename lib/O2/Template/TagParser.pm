package O2::Template::TagParser;

# vars:       Available as a variable in the template
# properties: Not available in the template

use strict;

use constant DEBUG => 0;
use O2 qw($context $config $cgi);
use O2::Util::List qw(containsAny);

#--------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  
  my $obj = bless {}, $package;
  
  $obj->{vars} = $params{vars};
  $obj->setWarnLevel(   $config->get('template.warnLevel') );
  $obj->registerTaglib( 'Core'                             ) unless $params{noTaglibs};
  $obj->setCwd(         $params{cwd} || ''                 );
  
  return $obj;
}
#--------------------------------------------------------------------------------------------
sub setCwd {
  my ($obj, $cwd) = @_;
  $obj->{cwd} = $cwd;
}
#--------------------------------------------------------------------------------------------
sub getCwd {
  my ($obj) = @_;
  return $obj->{cwd};
}
#--------------------------------------------------------------------------------------------
sub setVars {
  my ($obj, %vars) = @_;
  $obj->{vars} = \%vars;
}
#--------------------------------------------------------------------------------------------
sub getVars {
  my ($obj) = @_;
  return %{ $obj->{vars} };
}
#--------------------------------------------------------------------------------------------
sub setWarnLevel {
  my ($obj, $warnLevel) = @_;
  $obj->{warnLevel} = $warnLevel;
}
#--------------------------------------------------------------------------------------------
sub getWarnLevel {
  my ($obj) = @_;
  return $obj->{warnLevel} if $obj->{warnLevel} =~ m{ \A (?: off | show | log ) \z }xms;
  return 'log';
}
#--------------------------------------------------------------------------------------------
sub registerTaglib {
  my ($obj, $taglib, %params) = @_;
  
  $taglib = "O2::Template::Taglibs::$taglib";
  $taglib =~ s{ \A O2:: }{O2CMS::}xms if $taglib =~ m{ Taglibs::O2CMS:: }xms;
  
  my $prefix = $config->get('dispatcher.customerPackagePrefix');
  if ($prefix && $taglib =~ m{ Taglibs:: \Q$prefix\E }xms) {
    $taglib =~ s{ \A O2:: }{${prefix}::}xms;
  }
  elsif (my ($plugin) = $taglib =~ m{ Taglibs::O2Plugin::(\w+) }xms) {
    $taglib =~ s{ \A O2:: }{O2Plugin::${plugin}::}xms;
  }
  
  return $obj->{registeredTaglibs}->{$taglib} if $obj->{registeredTaglibs}->{$taglib} && $taglib !~ m{ \A O2::Template::Taglibs::Jquery (?:Ui)? \z }xms;
  
  eval "require $taglib";
  die "Could not load taglib '$taglib': '$@'" if $@;
  my ($taglibHandler, %methods) = $taglib->register(parser => $obj, %params);
  foreach my $method (keys %methods) {
    my $rules;
    foreach (split /\s*\+\s*/, $methods{$method}) {
      $rules->{$_} = 1;
    }
    $obj->{rules}->{$taglib}->{$method} = $rules;
    
    $obj->{methods}->{$method} = {
      handler => $taglibHandler,
      rule    => $rules,
    };
  }
  return $obj->{registeredTaglibs}->{$taglib} = $taglibHandler;
}
#--------------------------------------------------------------------------------------------
sub getTaglibByName {
  my ($obj, $name, %params) = @_;
  my $taglib = "O2::Template::Taglibs::$name";
  return $obj->{registeredTaglibs}->{$taglib} if $obj->{registeredTaglibs}->{$taglib};
  $obj->registerTaglib($name, %params);
  return $obj->{registeredTaglibs}->{$taglib};
}
#--------------------------------------------------------------------------------------------
sub pushMethod {
  my ($obj, $methodName, $object, $rule) = @_;
  push @{ $obj->{pushedMethods}->{$methodName} },  $obj->{methods}->{$methodName};
  $obj->{methods}->{$methodName} = {
    handler => $object,
    rule    => $rule || $obj->{rules}->{ ref $object }->{$methodName},
  };
}
#--------------------------------------------------------------------------------------------
sub pushPostExecutionMethod {
  my ($obj, $methodName, $object) = @_;
  push @{ $obj->{pushedMethods}->{$methodName} },  $obj->{methods}->{$methodName};
  $obj->{methods}->{$methodName} = {
    handler => $object,
    rule    => { macro => 1, postExecution => 1 },
  };
}
#--------------------------------------------------------------------------------------------
sub pushPostfixMethod {
  my ($obj, $methodName, $object) = @_;
  $obj->pushMethod( $methodName, $object, { postfix => 1 } );
}
#--------------------------------------------------------------------------------------------
sub pushMethods {
  my ($obj, %methods) = @_;
  foreach my $method (keys %methods) {
    $obj->pushMethod( $method => $methods{$method} );
  }
}
#--------------------------------------------------------------------------------------------
sub _popMethod {
  my ($obj, $methodName, $object) = @_;
   $obj->{methods}->{$methodName} = pop @{ $obj->{pushedMethods}->{$methodName} }, $object;
}
#--------------------------------------------------------------------------------------------
sub popMethod {
  my ($obj, %methods) = @_;
  foreach my $method (keys %methods) {
    $obj->_popMethod( $method => $methods{$method} );
  }
}
#--------------------------------------------------------------------------------------------
sub parse {
  my ($obj, $template) = @_;
  return $obj->_parse($template, 'parseMacros');
}
#--------------------------------------------------------------------------------------------
sub encodeEntities {
  my ($obj, $text, $charactersToEncode) = @_;
  return $text unless $text;
  
  my %charactersToEncode = map  { $_ => 1 }  ( $charactersToEncode ? split //, $charactersToEncode : @{ $obj->getProperty('charactersToEncode') || [] } );
  $text =~ s{&}{&amp;}g   if $charactersToEncode{'&'};
  $text =~ s{"}{&quot;}g  if $charactersToEncode{'"'};
  $text =~ s{'}{&\#39;}g  if $charactersToEncode{"'"};
  $text =~ s{<}{&lt;}g    if $charactersToEncode{'<'};
  $text =~ s{>}{&gt;}g    if $charactersToEncode{'>'};
  $text =~ s{\$}{&\#36;}g if $charactersToEncode{'$'};
  return $text;
}
#--------------------------------------------------------------------------------------------
sub _parse {
  my ($obj, $template, $parseMacros, %params) = @_;
  die "Need scalar-reference for parsing" unless ref $template eq 'SCALAR';
  
  # XXX Premacros

  while (${$template} && ${$template} =~ m/<[oO]2(\s+)(\w+)/g) {
    my $spacers = $1 || 0;
    my $tagName = $2;
    return $template if $tagName eq 'end';

    my $startPosition = pos ${$template};

    my ($attribs, $content, $endPosition, $hasInnerTag, $error) = _resolveTag($template, $startPosition);

    if ($error) {
      my $currentTemplate = $obj->getProperty('currentTemplate');
      my $templatePart = substr ${$template}, $startPosition;
      $templatePart    =~ s{ [\n\r] .* \z }{}xms;
      ${$template} = "<font color='red'>$currentTemplate: Could not find closing tag near <b>" . $obj->encodeEntities( "<o2 $tagName $templatePart", '<&>' ) . "</b></font>";
      warning "$currentTemplate: Could not find closing tag near <o2 $tagName$templatePart";
      return $template;
    }

    my $method = $obj->{methods}->{$tagName} || 0;
    $startPosition -= length ($spacers . $tagName) + 3;
    my $replaceContent = '';

    if ($method) {
      my %attribs;

      $obj->parseVars(\$attribs) unless $method->{rule}->{postfix};

      if ($method->{rule}->{singularParam}) {
        # The singular param is optional, so if $param contain '=', it means there is no singular param
        $attribs{param} = '';
        if (my ($param) = $attribs =~ m{ \A \s*  ( "[^"]+" | '[^']+' | [^\s=]+ )  (?: \s | \z ) }xms) {
          $attribs =~ s{ \Q$param\E }{}xms;
          $attribs{param} = $param;
          $attribs{param} =~ s{^["']|["']$}{}g; # Remove leading and trailing quotes
        }
      }

      while ($attribs =~ m{
                            (\w+)
                            (?:
                              = ([\'\"]) \2
                            |
                              = ([\'\"]) ( .*? [^\\]) \3
                            |
                              = ([\'\"]) ([^\2]*?) \5
                            |
                              = (\S+)
                            )? \s*
                        }xmsg) {
        next if $1 eq 'content' || $1 eq 'param';
        my ($attributeName, $quote1, $quote2, $value1, $quote3, $value2, $value3) = ($1, $2, $3, $4, $5, $6, $7);
        $value1 =~ s{ \\ $quote1 }{$quote1}xmsg if $value1 && $quote1; # If the quote was escaped with a backslash, we must remove the backslash
        $attribs{$attributeName}
          = length $value1                ? $value1
          : length $value2                ? $value2
          : length $value3                ? $value3
          : $quote1 || $quote2 || $quote3 ?      ''
          :                                       1
          ;
      }
      
      $obj->_parse(\$content)    if  $hasInnerTag && !$method->{rule}->{postfix};
      $obj->parseVars(\$content) if !$hasInnerTag && !$method->{rule}->{postfix};

      $attribs{content} = $content;

      if ($method->{rule}->{macro}) {
        if ($method->{rule}->{postExecution}) {
          my $macroIndex = $#{ $obj->{macros} } + 1;
          push @{ $obj->{macros} }, {
            tagName => $tagName,
            content => $content,
            attribs => \%attribs,
            index   => $macroIndex,
          };
          $replaceContent = qq{[#macro id=$macroIndex#]};
        }
        else {
          # XXX Call the inline macro (since preExecution is already handled, this must be an inlineExecution
          my $tmpTemplate = substr ${$template}, $endPosition;
          $attribs{template} = \$tmpTemplate;
          push @{ $obj->{tagStack} }, $tagName;
          eval {
            $replaceContent = $method->{handler}->$tagName(%attribs);
          };
          $replaceContent = $obj->error("$tagName: $@") if $@;
          pop @{ $obj->{tagStack} };
          substr (${$template}, $endPosition) = $tmpTemplate;
        }
      }
      else {
        push @{ $obj->{tagStack} }, $tagName;
        eval {
          $replaceContent = $method->{handler}->$tagName(%attribs);
        };
        $replaceContent = $obj->error("$tagName: $@") if $@;
        pop @{ $obj->{tagStack} };
      }
    }
    else {
      $replaceContent = $obj->error("No such tag '$tagName'");
    }
    substr (${$template}, $startPosition, ($endPosition - $startPosition)) = length $replaceContent ? $replaceContent : '';
    pos (${$template}) = $startPosition  +  (length ($replaceContent) || 0);
  }

  if (!$params{dontParseVars}) {
    eval {
      $obj->parseVars($template);
    };
    ${$template} = $obj->error($@) if $@;
  }

  if ($parseMacros) {
    $obj->_setupEventHandlers($template);
    $obj->_parseMacros($template) if $obj->{macros};
  }
  
  return $template;
}
#--------------------------------------------------------------------------------------------
sub _parseMacros {
  my ($obj, $template) = @_;
  my $jsData = $context->getSingleton('O2::Javascript::Data');
  foreach my $macro (@{ $obj->{macros} }) {
    my $replaceContent;
    if ($macro->{errorMsg}) {
      $replaceContent = $macro->{errorMsg};
      ${$template} =~ s/\[#macro id=$macro->{index}(.*?)#\]/$1 eq ' escapeForSingleQuotedString' ? $jsData->escapeForSingleQuotedString($replaceContent) : $replaceContent/ge;
    }
    else {
      my $tagName = $macro->{tagName};
      push @{ $obj->{tagStack} }, $tagName;
      eval {
        $replaceContent = $obj->{methods}->{$tagName}->{handler}->$tagName(  %{ $macro->{attribs} }  );
      };
      $replaceContent = $obj->error("$tagName: $@") if $@;
      $replaceContent = '' unless length $replaceContent;
      pop @{ $obj->{tagStack} };
      ${$template} =~ s/\[#macro id=$macro->{index}(.*?)#\]/$1 eq ' escapeForSingleQuotedString' ? $jsData->escapeForSingleQuotedString($replaceContent) : $replaceContent/ge;
    }
  }
  $obj->_parseMacros($template) if ${$template} =~ m/\[\#macro id=\d+(.*?)\#\]/ms; # New macros appeared - must parse those, too
}
#--------------------------------------------------------------------------------------------
sub _setupEventHandlers {
  my ($obj, $template) = @_;
  my $htmlTaglib = $obj->registerTaglib('Html');
  
  while (${$template} =~ m{ (<(\w+) \s+ ([^>]+) eventHandlers=(['"])(.+?)\4 ([^>]*) /?>) }xmsg) {
    my ($match, $tagName, $attributes1, $eventHandlers, $attributes2) = ($1, $2, $3, $5, $6);
    my $attributes = "$attributes1 $attributes2";
    my ($dummy, $id) = $attributes =~ m{ \bid=(['"]) (.+?) \1 }xms;
    if (!$id) {
      $id = 'o2Elm' . $htmlTaglib->_getRandomId();
      my $appendStr = qq{ id="$id"};
      my $pos = pos ${$template}; # Save current position (which is lost in the following substr assignment)
      substr (${$template}, ($pos-length $match), (length ($match)-1)) = substr ($match, 0, -1) . $appendStr;
      pos (${$template}) = $pos + length $appendStr; # Set new position so the pattern match in the while loop doesn't start matching from the start of the string again
    }
    
    my @eventHandlers = split /,/, $eventHandlers;
    foreach my $eventHandler (@eventHandlers) {
      my ($eventType, $handlerFunction) = split /:/, $eventHandler, 2;
      $htmlTaglib->addJs(
        where   => 'post',
        content => qq{o2.addEvent( document.getElementById("$id"), "$eventType", $handlerFunction );},
      );
    }
  }
}
#--------------------------------------------------------------------------------------------
sub _parseMacrosForTag {
  my ($obj, $template, $tagName) = @_;
  my $macroIndex = 0;
  my $remainingCounter = 0;
  my @remainingMacros;
  foreach my $macro (@{$obj->{macros}}) {
    if ($macro->{tagName} eq $tagName) {
      my $replaceContent = $obj->{methods}->{$tagName}->{handler}->$tagName( %{$macro->{attribs}} );
      ${$template} =~ s/<#macro id="$macroIndex"#>/$replaceContent/;
    }
    else {
      $remainingCounter++;
      ${$template} =~ s/<#macro id="$macroIndex"#>/<#macro id="$remainingCounter"#>/;
      push @remainingMacros, $macro;
    }
    $macroIndex++;
  }
  $obj->{macros} = \@remainingMacros;
  return $template;
}
#--------------------------------------------------------------------------------------------
sub _resolveTag {
  my ($template, $startPosition) = @_;

  my $nTags       = 1;
  my $hasInnerTag = 0;
  my $endTag      = '';
  my $error       = 0;

  while (${$template} =~ m{ ( <o2  |  </o2(?::[^>]+)?>  |  /> ) }gx) {
    $endTag = $1;
    if    ($endTag =~ m{</o2}) { $nTags-- }
    elsif ($endTag eq '/>')    { $nTags-- }
    elsif ($endTag eq '<o2')   { $nTags++ }

    $hasInnerTag = 1 if $nTags >= 2;
    last if $nTags == 0;
  }

  my $endPosition = pos ${$template};

  $error = 1 unless $endPosition;

  my $attributeEnd = $startPosition;
  my $singleQ      = 0;
  my $doubleQ      = 0;
  my $char         = substr ${$template}, $attributeEnd, 1;
  my $lastChar     = '';
  while (  $attributeEnd <= $endPosition   &&   ( ($singleQ > 0 || $doubleQ > 0)  ||  ($char ne '>') )  ) {
    $lastChar = $char;
    $char = substr ${$template}, ++$attributeEnd, 1;
    $doubleQ = $doubleQ ? 0 : 1 if !$singleQ && $char eq '"'  && $lastChar ne '\\';
    $singleQ = $singleQ ? 0 : 1 if !$doubleQ && $char eq '\'' && $lastChar ne '\\';
  }

  my $attributes = substr ${$template}, $startPosition, $attributeEnd - $startPosition;
  my $contentEnd = $endPosition - $attributeEnd - 1 - length $endTag;
  my $content    = $contentEnd < 1 ? '' : substr ${$template}, $attributeEnd + 1, $contentEnd;

  $attributes =~ s{/$}{}g if $endTag eq '/>';

  pos (${$template}) = $startPosition;

  return ($attributes, $content, $endPosition, $hasInnerTag, $error);
}
#--------------------------------------------------------------------------------------------
sub _isEndOfVariable {
  my ($obj, $mode, $openedParens, $str, $pos) = @_;
  return 0 if exists $openedParens->{total} && $openedParens->{total} > 0;
  $str = substr $str, $pos;
  return 1 if $mode eq 'methodName' && (!$str || $str =~ m{ \A [^-\w\(] }xms); # Allowed to skip parentheses for method calls without arguments
  return 0 if $mode ne 'complete';
  return 1 if $str !~ m{ \A -> }xms;
  return 0;
}
#--------------------------------------------------------------------------------------------
# Returns the first matched variable (not it's value) in the given string
sub matchVariable {
  my ($obj, $str) = @_;
  my $ignoreError = 0;
  my %openedParens = (
    '('   => 0,
    '{'   => 0,
    '['   => 0,
    total => 0,
  );
  while (length $str  &&  $str =~ m{ (\^?) (\$ [a-zA-Z_]\w*) }xmsg) {
    my $pos = pos $str;
    $ignoreError = 1 if $1;
    my $variableName = $2;
    return ($variableName, $ignoreError) if substr ($str, $pos, 2) ne '->';

     # Walk past the arrow ("->")
    $pos          += 2;
    $variableName .= '->';

    my $mode = 'afterArrow';
    while ( !$obj->_isEndOfVariable($mode, \%openedParens, $str, $pos) ) {
      my $nextChar = substr $str, $pos, 1;
#      warn "$mode - $variableName - $nextChar"; # Uncomment to see a little bit of what happens
      die "Didn't find end of variable: $str. Variable name is $variableName." if $pos >= length $str;
      if (($mode eq 'afterArrow' || $mode eq 'index')  &&  ($nextChar eq '{' || $nextChar eq '[')) {
        $mode = 'index';
        $openedParens{total}++;
        $openedParens{$nextChar}++;
      }
      elsif ($mode eq 'afterArrow'  &&  $nextChar =~ m{ \w }xms) { # Start of method name
        $mode = 'methodName';
      }
      elsif (($mode eq 'methodName' || $mode eq 'methodArgument') && $nextChar eq '(') {
        $mode = 'methodArgument';
        $openedParens{total}++;
        $openedParens{'('}++;
      }
      elsif ($mode eq 'index'  &&  ($nextChar eq '}' || $nextChar eq ']')) {
        $openedParens{total}--;
        $openedParens{'{'}-- if $nextChar eq '}';
        $openedParens{'['}-- if $nextChar eq ']';
        $mode = 'complete'   if $openedParens{total} == 0  &&  $openedParens{'{'} == 0  &&  $openedParens{'['} == 0;
      }
      elsif ($mode eq 'methodArgument' && $nextChar eq ')') {
        $openedParens{total}--;
        $openedParens{'('}--;
        $mode = 'complete' if $openedParens{total} == 0  &&  $openedParens{'('} == 0;
      }
      elsif (($mode eq 'complete' || $mode eq 'methodName')  &&  $nextChar eq '-') {
        $mode = 'inArrow';
      }
      elsif ($mode eq 'inArrow' && $nextChar eq '>') {
        $mode = 'afterArrow';
      }
      elsif (($mode eq 'methodArgument' || $mode eq 'index')  &&  $nextChar eq '\\') {
        $mode = "escape:$mode";
      }
      elsif ($mode =~ m{ \A escape\:(\w+) \z }xms) {
        $mode = $1;
      }
      $pos++;
      $variableName .= $nextChar;
    }
    return ($variableName, $ignoreError);
  }
  return ('', 1);
}
#--------------------------------------------------------------------------------------------
sub parseVars {
  my ($obj, $stub, $findMethod, $dontEncodeEntities) = @_;
  die "First parameter to parseVars must be a reference to a string" unless ref $stub eq 'SCALAR';
  return unless length ${$stub};
  
  $findMethod ||= 'findVar';
  ${$stub} =~ s/\\\$/&escapedDollar;/g;
  ${$stub} =~ s/([^=-])\>/$1&escapedGt;/g;

  my $str = ${$stub};
  my ($variableStr, $ignoreError);
  while ((($variableStr, $ignoreError) = $obj->matchVariable($str)) && $variableStr) {
    my $replaceWith;
    eval {
      $replaceWith = $obj->$findMethod($variableStr, undef, $dontEncodeEntities, $ignoreError);
    };
    die "Couldn't parse variable $variableStr: $@" if $@;
    
    $replaceWith = '' unless length $replaceWith;
#    warn "$variableStr => $replaceWith";
    ${$stub} =~ s{ \^? \Q$variableStr\E }{$replaceWith}xms;
    $str     = substr $str, index ($str, $variableStr) + length $variableStr;
  }

  ${$stub} =~ s/\&escapedDollar\;/\$/g;
  ${$stub} =~ s/\&escapedGt\;/>/g;
  return ${$stub};
}
#--------------------------------------------------------------------------------------------
sub externalDereference {
  my ($obj, $var) = @_;
  $var =~ s[ \^? \$ ([a-zA-Z_]\w*) ][\$obj->{parser}->{vars}->{$1}]xg;
  return $var;
}
#--------------------------------------------------------------------------------------------
sub findVar {
  my ($obj, $var, $forceType, $dontEncodeEntities, $ignoreError) = @_;
  return '' unless $var;
  
  my $originalVar = $var;
  $ignoreError = 1 if $var =~ s{ \A \^ [\$] }{\$}xms;
  
  while (my ($methodNameVariable) = $var =~ m{ \$ ([a-zA-Z_]\w*) \( }xms) { # Method call where method name is a variable
    no strict 'subs';
    my $methodName = eval $obj->{vars}->{$methodNameVariable};
    die $@ if $@;
    $var =~ s{ \$ $methodNameVariable }{$methodName}xms;
  }
  $var =~ s[ \$ ([a-zA-Z_]\w*) ][\$obj->{vars}->{$1}]xg;
  return '' unless $var;
  
  my $results;
  if ($forceType && lc $forceType eq 'hash') {
    my %results = eval $var;
    $results = \%results;
  }
  elsif ($forceType && lc $forceType eq 'array') {
    my @results = eval $var;
    $results = \@results;
  }
  else {
    $results = eval $var;
  }
  if ($@) {
    my $errorMsg = "Couldn't eval '$originalVar': $@";
    $results = '';
    if (!$ignoreError) {
      my $warnLevel = $obj->getWarnLevel();
      die $errorMsg             if $warnLevel eq 'show';
      $obj->logError($errorMsg) if $warnLevel eq 'log';
    }
  }
  
  return ${$results} if ref $results eq 'SCALAR';
  return ''          if !defined $results || length $results == 0;
  
  my @charactersToEncode = @{ $obj->getProperty('charactersToEncode') || [] };
  if (@charactersToEncode  &&  !$dontEncodeEntities  &&  index ($var, 'getString') == -1  &&  index ($var, 'getArrayRef') == -1) {
    $results = $obj->encodeEntities($results) unless containsAny @{ $obj->{tagStack} }, qw(setVar appendVar);
  }
  return $results;
}
#--------------------------------------------------------------------------------------------
sub getVar {
  my ($obj, $key) = @_;
  my $value;
  $key =~ s{^\$}{};
  if ($key =~ s{^([^-]+)->}{}) {
    $value = eval "\$obj->{vars}->{$1}->$key";
    $obj->error("Could not assign variable: $@") if $@;
  }
  else {
    $value = $obj->{vars}->{$key};
  }
  return $value;
}
#--------------------------------------------------------------------------------------------
sub setVar {
  my ($obj, $key, $value) = @_;
  $key =~ s{^\$}{};
  if ($key =~ s{^([^-]+)->}{}) {
    eval "\$obj->{vars}->{$1}->$key = $value";
    $obj->error("Could not assign variable: $@") if $@;
  }
  else {
    $obj->{vars}->{$key} = $value;
  }
}
#--------------------------------------------------------------------------------------------
sub pushVar {
  my ($obj, $key, $value) = @_;
  $obj->{pushedVars}         = {} unless $obj->{pushedVars};
  $obj->{pushedVars}->{$key} = [] unless $obj->{pushedVars}->{$key};
  push @{ $obj->{pushedVars}->{$key} }, $obj->getVar($key);
  $obj->setVar($key, $value);
  return 1;
}
#--------------------------------------------------------------------------------------------
sub popVar {
  my ($obj, $key) = @_;
  my $value    = $obj->getVar($key);
  my $oldValue = pop @{ $obj->{pushedVars}->{$key} };
  $obj->setVar($key, $oldValue);
  return $value;
}
#--------------------------------------------------------------------------------------------
sub getProperty {
  my ($obj, $key) = @_;
  return $obj->{$key};
}
#--------------------------------------------------------------------------------------------
sub setProperty {
  my ($obj, $key, $value) = @_;
  $obj->findVar('$lang')->setResourcePath( $obj->{resourcePathsFor}->{$value} ) if $key eq 'currentTemplate' && defined $value && $obj->{resourcePathsFor}->{$value};
  return $obj->{$key} = $value;
}
#--------------------------------------------------------------------------------------------
sub pushProperty {
  my ($obj, $key, $value) = @_;
  $obj->{pushedProperties}         = {} unless $obj->{pushedProperties};
  $obj->{pushedProperties}->{$key} = [] unless $obj->{pushedProperties}->{$key};
  push @{ $obj->{pushedProperties}->{$key} }, $obj->getProperty($key);
  $obj->setProperty($key, $value);
  return 1;
}
#--------------------------------------------------------------------------------------------
sub popProperty {
  my ($obj, $key) = @_;
  my $value    = $obj->getProperty($key);
  my $oldValue = pop @{ $obj->{pushedProperties}->{$key} };
  $obj->setProperty($key, $oldValue);
  return $value;
}
#--------------------------------------------------------------------------------------------
sub setResourcePath {
  my ($obj, $resourcePath) = @_;
  $obj->{resourcePathsFor} ||= {};
  $obj->{resourcePathsFor}->{ $obj->getProperty('currentTemplate') }  =  $resourcePath;
  $obj->findVar('$lang')->setResourcePath($resourcePath);
}
#--------------------------------------------------------------------------------------------
sub error {
  my ($obj, $errorMsg) = @_;
  $errorMsg = $obj->logError($errorMsg);
  
  my $macroIndex = $#{ $obj->{macros} } + 1;
  push @{ $obj->{macros} }, {
    errorMsg => $errorMsg,
    index    => $macroIndex,
  };
  
  return qq{<font color="red"><b>[#macro id=$macroIndex#]</b></font>};
}
#--------------------------------------------------------------------------------------------
sub logError {
  my ($obj, $error) = @_;
  my $errorMsg = "TagParser error";
  $errorMsg   .= ' (' . $obj->getProperty('currentTemplate') . ')' if $obj->getProperty('currentTemplate');
  $errorMsg   .= ": $error";
  
  warning $errorMsg, stackTrace => $cgi->{_stackTrace};
  return $errorMsg;
}
#--------------------------------------------------------------------------------------------
1;
__END__

Known bugs;

- Typing -$var- does not work
- Self-closing O2-tag does not nest properly within open O2-tags
- Scoping: Variables between o2-tags doesn''t get evaluated before after all processing of all o2-tags is done
- Can't handle empty attributes (eg. title="" eats next attribute)
