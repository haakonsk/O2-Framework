package O2::Template::Taglibs::Core;

use strict;

use constant DEBUG => 0;
use O2 qw($context);

#----------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    calc        => 'postfix',
    push        => 'singularParam + postfix',
    join        => 'singularParam + postfix',
    appendVar   => 'singularParam + postfix',
    for         => 'singularParam + postfix',
    foreach     => 'singularParam + postfix',
    if          => 'singularParam + postfix',
    elsif       => 'singularParam + postfix',
    else        => 'singularParam + postfix',
    use         => 'singularParam + postfix',
    function    => 'singularParam + postfix',
    call        => 'singularParam + postfix',
    warnLevel   => 'singularParam + postfix',
    include     => 'singularParam + postfix',
    comment     => 'singularParam + postfix',
    postMacro   => 'macro + postExecution',
    preMacro    => 'macro + prefix',
    setVar      => 'singularParam + postfix',
    set         => 'singularParam + postfix',
    noExec      => 'singularParam + postfix',
    out         => '',
    doubleParse => 'prefix',
    macro       => 'macro + inlineExecution',
  );
  return ($obj, %methods);
}
#----------------------------------------------------
sub function {
  my ($obj, %params) = @_;
  $obj->{functions}->{ $params{param} } = $params{content};
  return '';
}
#----------------------------------------------------
sub call {
  my ($obj, %params) = @_;

  my $functionName = delete $params{param};
  my $functionBody = $obj->{functions}->{$functionName};

  # scan function text for variables, and remember current value
  my @variables = $functionBody =~ m/\$(\w+)/g; # find all variable names
  my %variables = map { $_ => 1 } @variables; # distinct names
  my %stack;
  foreach my $var (keys %variables) {
    $stack{$var} = $obj->{parser}->findVar('$'.$var);
  }

  # set parameter variables
  foreach my $param (keys %params) {
    my $var = $params{$param};
    if ($params{$param} =~ m/^\$/) { # We have an unparsed value, lets get it from the parser
      $var = $obj->{parser}->findVar( $params{$param} );
    }
    $obj->{parser}->setVar('$'.$param, $var);
  }
  
  my $functionReturnValue = $obj->{parser}->_parse( \$functionBody );
  
  # reset variables used in function
  foreach my $param (keys %stack) {
    $obj->{parser}->setVar( '$'.$param => $stack{$param} ); #'
  }
  return ${$functionReturnValue};
}
#----------------------------------------------------
sub noExec {
  my ($obj, %params) = @_;
  $params{content} =~ s/\$/\\\$/g;
  return $params{content};
}
#----------------------------------------------------
sub out {
  my ($obj, %params) = @_;
  return $params{content};
}
#----------------------------------------------------
sub set {
  my ($obj, %params) = @_;
  my ($var, $value) = split /\s*=\s*/, $params{param};
  
  my $expr;
  ($var, $expr) = $var =~ m{ \A \s* ( \$ \w+ ) \s*  ( / | [*] | [+][+]? | --? | [|][|] )  \s* \z }xms or die qq{Didn't understand "$params{param}"};
  
  my $currentValue = $obj->{parser}->findVar($var);
  
  if ($value) {
    $value =~ s/^[\'\"]|[\'\"]$//;
    my $varValue = $value;
    if ($value =~ m/^\$\w+/) { # Probably a variable, let's see if we can get at it
      my $refToVar = $obj->{parser}->findVar($value);
      die 'Cannot execute expression on reference to a variable' if ref $refToVar && $expr;
      
      $obj->{parser}->parseVars(\$value);
      $refToVar = $value;
      $varValue = $refToVar;
    }
    if ($expr) {
      if ($expr eq '||') {
        $obj->{parser}->setVar($var, $varValue) unless $currentValue;
      }
      else {
        if    ($expr eq '+') { $obj->{parser}->setVar($var, $currentValue + $varValue) }
        elsif ($expr eq '-') { $obj->{parser}->setVar($var, $currentValue - $varValue) }
        elsif ($expr eq '*') { $obj->{parser}->setVar($var, $currentValue * $varValue) }
        elsif ($expr eq '/' && ($value < 0 || $value > 0)) {
          $obj->{parser}->setVar($var, $currentValue / $varValue);
        }
        else {
          die qq{Don't understand "$params{param}": '$expr' is not valid in combination with a given value};
        }
      }
    }
    else {
      $obj->{parser}->setVar($var, $varValue);
    }
  }
  else {
    if ($expr) {
      $currentValue ||= 0;
      if    ($expr eq '++') { $obj->{parser}->setVar($var, $currentValue + 1) }
      elsif ($expr eq '--') { $obj->{parser}->setVar($var, $currentValue - 1) }
    }
  }
  return '';
}
#----------------------------------------------------
sub preMacro {
  my ($obj) = @_;
  return 'Not implemented';
}
#----------------------------------------------------
sub postMacro {
  my ($obj) = @_;
  $obj->macro(@_);
}
#----------------------------------------------------
sub macro {
  my ($obj, %params) = @_;
  $params{pattern} = "\Q$params{replace}\E" if $params{replace};

  ${ $params{template} } =~ s{$params{pattern}}{$params{content}}gmsi;
  
  $obj->{parser}->_parse( \$params{content} );
  return '';
}
#----------------------------------------------------
sub for {
  my ($obj, %params) = @_;

  my $iterationExpression = $params{param};
  my $content       = '';
  my $loopConstruct = '';
  my $iterator      = '_';
  my $isForILoop = 0;
  if ($iterationExpression =~ m|^\(?[^\;]+\;[^\;]+\;[^\)]+\)?$|) {
    $isForILoop = 1;
  }
  elsif ($iterationExpression =~ s{  \s*  \$  ([_a-zA-Z0-9]+)  \s*  [(]  }{\(}xms   ) {
    $iterator = $1
  } 

  $iterationExpression = "($iterationExpression)" if $iterationExpression !~ m/\(/;
  my $expression = $iterationExpression;
  $obj->{parser}->parseVars(\$iterationExpression, 'externalDereference');
 
  if ($isForILoop == 1) {
    $loopConstruct = "for $iterationExpression {";
  }
  else {
    $loopConstruct = "for my \$_localIterator $iterationExpression {
\$obj->{parser}->setVar('$iterator', \$_localIterator); ";
  }
  
  $loopConstruct .= "
my \$tmpContent = \$params{content};
\$obj->{parser}->_parse(\\\$tmpContent);
\$content.=\$tmpContent;
}";

#  print "<pre>\n$loopConstruct\n</pre>";

  eval "$loopConstruct";
  die "Error in expression '$expression': $@" if $@;
  return $content;
}
#----------------------------------------------------
sub push {
  my ($obj, %params) = @_;
  $params{param} =~ s/^\$// or die "Error in expression '$params{param}': Missing declaration '$'";

  # make sure <o2 push...>$variable</o2:push> ($variable as content) is handled correctly
  my $contentIsAVariable = 0;
  if ($params{content} =~ m|^\$\w+$|) {
    my $foundVar = $obj->{parser}->findVar( $params{content} );
    if ($foundVar) {
      $params{content} = $foundVar;
      $contentIsAVariable = 1;
    }
  }
  if (!$contentIsAVariable) {
    $obj->{parser}->_parse( \$params{content} );
  }

  my $refToVar = $obj->{parser}->findVar( '$' . $params{param} );
  if (ref $refToVar ne 'ARRAY') {
    $refToVar = length ($refToVar) ? [$refToVar] : [];
    push @{$refToVar}, $params{content};
    $obj->{parser}->setVar( $params{param} => $refToVar );
  }
  else {
    push @{$refToVar}, $params{content};
  }
  return '';
}
#----------------------------------------------------
sub join {
  my ($obj, %params) = @_;
  $params{content} =~ s/^\$// or die "Error in expression '$params{param}': Missing declaration '$'";
  my $refToVar = $obj->{parser}->findVar( '$' . $params{content} );
  return join $params{param}, @{$refToVar} if ref $refToVar eq 'ARRAY';
  return ${$refToVar}                      if ref $refToVar eq 'SCALAR';
  die "Error in expression: need an array or a scalar for join";
}
#----------------------------------------------------
sub foreach {
  my ($obj, %params) = @_;
  $params{label} ||= 'currentForeach';
  
  my $sorter; # Expects each element to be an array ref. Sorting will be based on this array ref's first element.
  if ($params{sortType} || $params{sortBy} || $params{sortDirection}) {
    
    $params{sortDirection} = $obj->{parser}->findVar( $params{sortDirection} ) if $params{sortDirection} && $params{sortDirection} =~ m{ \A \$ }xms;
    
    $sorter = sub {
      if ($params{sortType} && $params{sortType} eq 'numeric') { # Numeric comparison
        return $b->[0] <=> $a->[0] if $params{sortDirection} && $params{sortDirection} eq 'descending';
        return $a->[0] <=> $b->[0];
      }
      else { # String comparison
        return $b->[0] cmp $a->[0] if $params{sortDirection} && $params{sortDirection} eq 'descending';
        return $a->[0] cmp $b->[0];
      }
    };
  }
  if ($params{sortBy} && $params{sortBy} eq 'random') {
    $sorter = sub {
      return rand () <=> rand ();
    };
  }

  my ($keyVariable, $valueVariable, $sourceVariable, $type, $arrayOrHashValues, $ignoreError) = ('', '', '', '', '', 0);
  if ($params{param} =~ m{ \A    (\$ \w+)    \s+   =>   \s+    (\$ \w+)    \s+   in   \s+    (\^?) (\S .+)  \z }xms) {
    ($keyVariable, $valueVariable, $ignoreError, $sourceVariable) = ($1, $2, $3, $4);
    my $hashName = $sourceVariable;
    $type = 'hash';
    my $var = $obj->_getLoopingStructure($sourceVariable, $ignoreError, {}, \%params);
    if (ref $var eq 'HASH') {
      $sourceVariable = "\%{$sourceVariable}";
      $arrayOrHashValues = $var;
    }
    elsif (ref $var) {
      die "Variable $hashName is not a hash reference (it's of type " . ref ($var) . ').';
    }
    elsif ($hashName =~ m{ \A \$ \w+ \z }xms) {
      return; # hash variable doesn't exist
    }
  }
  elsif ( $params{param} =~ m{ \A    (\$ \w+)    \s+   in   \s+    (\^?) (\S .+)  \z }xms) {
    ($keyVariable, $ignoreError, $sourceVariable) = ($1, $2, $3);
    my $arrayName = $sourceVariable;
    $type = 'array';
    my $var = $obj->_getLoopingStructure($sourceVariable, $ignoreError, [], \%params);
    if (ref $var eq 'ARRAY') {
      $sourceVariable = "\@{$sourceVariable}";
      $arrayOrHashValues = $var;
    }
    elsif (ref $var) {
      die "Variable $arrayName is not an array reference (it's of type " . ref ($var) . ').';
    }
    elsif ($arrayName =~ m{ \A \$ \w+ \z }xms) {
      return; # array variable doesn't exist
    }
  }
  else {
    return $obj->for(%params);
  }

  $obj->{parser}->setVar('arrayOrHashValues', $arrayOrHashValues);
  $obj->{parser}->parseVars(\$sourceVariable, 'externalDereference');

  my $step = $type eq 'hash' ? 2 : 1;
  my $content = '';
  my $loopConstruct = sprintf q{
    my $values;
    if ($sorter) {
      if ($type eq 'hash') {
        my $hashRef = $obj->{parser}->getVar('arrayOrHashValues') || { %s };
        if (lc $params{sortBy} eq 'value') {
          $values = [  map { $_->[1], $hashRef->{ $_->[1] } }  sort $sorter  map { [$hashRef->{$_}, $_] } keys %%{$hashRef}  ];
        }
        elsif ($params{sortBy} && $params{sortBy} ne 'key') {
          $values = [  map { $_->[1], $hashRef->{ $_->[1] } }  sort $sorter  map { [%s, $_]             } keys %%{$hashRef}  ];
        }
        else { # Sort by key
          $values = [  map { $_->[0], $hashRef->{ $_->[0] } }  sort $sorter  map { [$_]                 } keys %%{$hashRef}  ];
        }
      }
      else {
        if ($params{sortBy} && $params{sortBy} ne 'random') {
          $values = [  map {$_->[1]} sort $sorter map { [%s, $_] } %s  ];
        }
        else {
          $values = [  map {$_->[0]} sort $sorter map { [$_]     } %s  ];
        }
      }
    }
    else {
      $values = $obj->{parser}->getVar('arrayOrHashValues') || [ %s ];
    }
    my @values = ref $values eq 'ARRAY'  ?  @{$values}  :  %%{$values};
    for (my $i = 0; $i <= $#values; $i += $step) {
      last if $params{limit} && $i / $step >= $params{limit};
      $obj->{parser}->setVar( '%s', $values[$i]   );
      $obj->{parser}->setVar( '%s', $values[$i+1] ) if $type eq 'hash';
      my $tmpContent = $params{content};
      if ($obj->{_exitForeachLoop}) {
        delete $obj->{_exitForeachLoop} if $obj->{_exitForeachLoop} eq '%s';
        last;
      }
      $obj->{parser}->pushMethod( 'last', $obj, { postfix => 1, singularParam => 1 } );
      eval {
        $obj->{parser}->_parse(\$tmpContent);
      };
      $tmpContent = $obj->{parser}->error($@) if $@;
      $obj->{parser}->popMethod('last', $obj);
      $content .= $tmpContent;
    }
  },
  $sourceVariable,
  $obj->_getSortByStringForHash(  $params{sortBy}, $keyVariable, $valueVariable ),
  $obj->_getSortByStringForArray( $params{sortBy}, $keyVariable                 ),
  $sourceVariable, $sourceVariable, $sourceVariable, $keyVariable, $valueVariable, $params{label};
  
#  print "$loopConstruct";
  eval "$loopConstruct";
  die "Probably an error in the expression '$params{param}': $@" if $@;
  return $content;
}
#----------------------------------------------------
sub _getSortByString {
  my ($obj, $sortBy, %replacements) = @_;
  return "''" unless $sortBy;
  
  while (my ($originalStr, $replacementStr) = each %replacements) {
    $sortBy =~ s{\Q$originalStr\E\b}{$replacementStr}msg if $originalStr;
  }
  
  my @parts;
  my $pos = 0;
  while (1) {
    my $remainingStr = substr $sortBy, $pos;
    last unless $remainingStr;
    
    my ($variableStr) = $obj->{parser}->matchVariable($remainingStr);
    if (!$variableStr) {
      CORE::push @parts, [$remainingStr, 'string'];
      last;
    }
    my $varLength = length $variableStr;
    my $_pos = index $sortBy, $variableStr;
    if ($_pos == 0) {
      CORE::push @parts, [$variableStr, 'variable'];
    }
    elsif ($_pos > 0) {
      CORE::push @parts, [substr ($sortBy, $pos, $_pos-$pos), 'string'], [$variableStr, 'variable'];
    }
    else { # $_pos == -1
      CORE::push @parts, [$remainingStr, 'string'];
      last;
    }
    $pos = $_pos + $varLength;
    last if $pos-1 >= length $sortBy;
  }
  
  $sortBy = '';
  foreach my $part (@parts) {
    $sortBy
      .= $part->[1] eq 'string'   ? "q{" . $part->[0] . "} . "
      :                                    $part->[0] .  ' . '
      ;
  }
  $sortBy = substr $sortBy, 0, -3 if @parts;
  
  # Translate variables except $hashRef and $_ to $obj->{parser}->{vars}->{...}:
  $sortBy =~ s{ \$ ( hashRef | _ ) }{\\\$$1}xmsg;
  $sortBy = $obj->{parser}->parseVars(\$sortBy, 'externalDereference');
  $sortBy =~ s{ \\ \$ (hashRef | _ ) }{\$$1}xmsg;
  
  return $sortBy;
}
#----------------------------------------------------
sub _getSortByStringForHash {
  my ($obj, $sortBy, $keyVariable, $valueVariable) = @_;
  return $obj->_getSortByString(
    $sortBy,
    $keyVariable   => '$_',
    $valueVariable => '$hashRef->{$_}',
  );
}
#----------------------------------------------------
sub _getSortByStringForArray {
  my ($obj, $sortBy, $keyVariable) = @_;
  return $obj->_getSortByString($sortBy, $keyVariable => '$_');
}
#----------------------------------------------------
sub _getLoopingStructure {
  my ($obj, $sourceVariable, $ignoreError, $default, $params) = @_;
  my $var;
  eval {
    $var = $obj->{parser}->findVar( $sourceVariable, $params->{forceType} );
  };
  my $errorMsg = $@;
  die "Error in expression: $params->{param}: $errorMsg" if $errorMsg && !$ignoreError;
  return $errorMsg ? $default : $var;
}
#----------------------------------------------------
sub last {
  my ($obj, %params) = @_;
  
  $params{if} = "!($params{unless})" if $params{unless};
  
  if ($params{if}) {
    return unless $obj->if(
      param => $params{if},
      then  => 1,
    );
  }
  
  $obj->{_exitForeachLoop} = $params{param} || 'currentForeach';
  return '';
}
#----------------------------------------------------
sub calc {
  my ($obj, %params) = @_;
  $obj->{parser}->_parse( \$params{content} );
  return $params{content} if $params{content} =~ m{ macro }xms;
  die "Not allowed to calculate: '$params{content}'" if $params{content} =~ m{ (?: \A \s* [*]  |  [^-+*/()|.%\s\d]+ ) }xms; # Allowed characters: (, ), |, +, -, *, /, ., %
  
  my $value = eval $params{content};
  die "Couldn't calculate '$params{content}': $@" if $@;
  return $value;
}
#----------------------------------------------------
sub setVar {
  my ($obj, %params) = @_;
  $params{param} =~ s/^\$// or die "Error in expression '$params{param}': Missing declaration '$'";

  # Remove leading and trailing white space:
  $params{content} =~ s{ \A \s+    }{}xms;
  $params{content} =~ s{    \s+ \z }{}xms;

  my ($variableName, $ignoreError) = $obj->{parser}->matchVariable( $params{content} );
  $params{content} =~ s{ \A \^ \$ }{\$}xms;
  if ( $variableName eq $params{content} ) {
    my $var;
    eval {
      $var = $obj->{parser}->findVar( $params{content}, $params{forceType} );
    };
    my $errorMsg = $@;
    $obj->{parser}->setVar( $params{param} => $var );
    if ($errorMsg && !$ignoreError) {
      my $warnings = $obj->_getWarnLevel();
      die $errorMsg if $warnings eq 'show';
      return ''     if $warnings eq 'log' && $obj->{parser}->logError($errorMsg);
    }
    return '';
  }

  $obj->{parser}->_parse( \$params{content} );

  # Remove leading and trailing white space:
  $params{content} =~ s{ \A \s+    }{}xms;
  $params{content} =~ s{    \s+ \z }{}xms;

  die "Could not set variable '$params{param}': $@" if $@ && !$ignoreError && !$params{ignoreError};
  $obj->{parser}->setVar( $params{param} => $params{content} );
  return '';
}
#----------------------------------------------------
sub _getWarnLevel {
  my ($obj) = @_;
  return $obj->{parser}->getWarnLevel();
}
#----------------------------------------------------
sub _evaluateExpression {
  my ($obj, $expression) = @_;
  
  my $str = $expression;
  my ($variableStr, $ignoreError);
  
  my %variables;
  while ((($variableStr, $ignoreError) = $obj->{parser}->matchVariable($str)) && $variableStr) {
    my $externalDereference = $obj->{parser}->externalDereference($variableStr);
    my $expressionIsTrue;
    {
      no warnings;
      $expressionIsTrue = eval $externalDereference;
    }
    if ($expressionIsTrue) {
      $expressionIsTrue = 0 if ref $expressionIsTrue eq 'ARRAY' && !@{$expressionIsTrue};
      $expressionIsTrue = 0 if ref $expressionIsTrue eq 'HASH'  && !%{$expressionIsTrue};
    }
    if ($variableStr eq $expression || "^$variableStr" eq $expression) {
      die $@ if $@ && !$ignoreError;
      return $expressionIsTrue;
    }
    
    $variables{$variableStr} = {
      dereference => $externalDereference,
      ignoreError => $ignoreError,
    };
    $expression =~ s{ \^? \Q$variableStr\E }{$externalDereference}xms;
    
    $str = substr $str, index ($str, $variableStr) + length $variableStr;
  }
  
  my $result;
  {
    no warnings;
    $result = eval $expression;
  }
  my $errorMsg = $@;
  return $result unless $errorMsg;
  
  foreach my $variableStr (keys %variables) {
    my $externalDereference = $variables{$variableStr}->{dereference};
    eval $externalDereference;
    my $_errorMsg = $@;
    next unless $_errorMsg;
    
    if ($variables{$variableStr}->{ignoreError}) {
      $expression =~ s{ \Q$externalDereference\E }{''}xms;
      next;
    }
    
    next unless $obj->_isSameErrorMsg($errorMsg, $_errorMsg);
    $_errorMsg = "$errorMsg (Might be due to a problem with $variableStr)";
    die $_errorMsg;
  }
  
  {
    no warnings;
    $result = eval $expression;
  }
  die $@ if $@;
  return $result;
}
#----------------------------------------------------
sub _isSameErrorMsg {
  my ($obj, $errorMsg1, $errorMsg2) = @_;
  $errorMsg1 =~ s{ \A (.+) at .+ \z }{$1}xms;
  $errorMsg2 =~ s{ \A (.+) at .+ \z }{$1}xms;
  return $errorMsg1 eq $errorMsg2;
}
#----------------------------------------------------
sub if {
  my ($obj, %params) = @_;
  
  if ($params{then} || $params{else}) {
    my $expression = $params{param};
    my $expressionIsTrue;
    eval {
      $expressionIsTrue = $obj->_evaluateExpression( $params{param} );
    };
    if ($@) {
      my $errorMsg  = "Error in expression $expression: $@";
      my $warnLevel = $obj->_getWarnLevel();
      die $errorMsg                       if $warnLevel eq 'show';
      $obj->{parser}->logError($errorMsg) if $warnLevel eq 'log';
    }
    return $params{then} if $expressionIsTrue;
    return $params{else};
  }
  
  my $expression = $params{param};
  my $results;
  eval {
    $results = $obj->_evaluateExpression( $params{param} );
  };
  if ($@) {
    my $errorMsg  = "Error in expression $expression: $@";
    my $warnLevel = $obj->_getWarnLevel();
    if ($warnLevel eq 'show') {
      $obj->{precedingIf} = { results => 1 }; # Abort the whole if/elsif/else
      die $errorMsg;
    }
    elsif ($warnLevel eq 'log') {
      $obj->{parser}->logError($errorMsg);
    }
  }
  
  if ($results) {
    $obj->{parser}->_parse( \$params{content} );
    $obj->{precedingIf} = { results => $results };
    return $params{content};
  }
  else {
    $obj->{precedingIf} = { results => $results };
    return '';
  }
}
#----------------------------------------------------
sub elsif {
  my ($obj, %params) = @_;
  die "No preceding if-statement" if ref $obj->{precedingIf} ne 'HASH';
  return '' if $obj->{precedingIf}->{results};
  return $obj->if(%params);
}
#----------------------------------------------------
sub else {
  my ($obj, %params) = @_;
  die "No preceding if-statement" if ref $obj->{precedingIf} ne 'HASH';
  return '' if $obj->{precedingIf}->{results};
  $obj->{parser}->_parse( \$params{content} );
  return $params{content};
}
#----------------------------------------------------
sub warnLevel {
  my ($obj, %params) = @_;
  my $originalWarnLevel = $obj->_getWarnLevel();
  $obj->{parser}->setWarnLevel( $params{param} );
  return '' unless $params{content};
  
  $obj->{parser}->_parse( \$params{content} );
  $obj->{parser}->setWarnLevel($originalWarnLevel);
  return $params{content};
}
#----------------------------------------------------
sub use {
  my ($obj, %params) = @_;
  my $tagLib = delete $params{param} || delete $params{content};
  eval {
    $obj->{parser}->registerTaglib($tagLib, %params);
  };
  die "Could not load taglib '$tagLib': $@" if $@;
}
#----------------------------------------------------
sub include {
  my ($obj, %params) = @_;

  my $cacheKey = delete $params{cacheKey};
  $obj->{parser}->parseVars(\$cacheKey);

  my $cacher = $context->getSingleton('O2::Util::SimpleCache');
  if ($cacheKey) {
    my $content = $cacher->get($cacheKey);
    if ($content) {
      debug "Cache hit for: $cacheKey";
      return $content;
    }
    debug "Cache miss for: $cacheKey";
  }

  my $includeFile = delete $params{param} || delete $params{file} || delete $params{content};
  $obj->{parser}->parseVars(\$includeFile);

  if ($includeFile =~ m{ \A o2: (?://)? (.*) }xms) {
    my $relativePath = $1;
    foreach my $root ($context->getRootPaths()) {
      my $fullPath = "$root/$relativePath";
      next unless -f $fullPath;
      
      $includeFile = $fullPath;
      last;
    }
  }
  if ($includeFile !~ m{ \A  ( / | \w: | \\ ) }xms) { # If it is not a full path, eg not: /full/path/to or \\server\share or \full\path\to or C:/full/path/to
    $includeFile = $obj->{parser}->getCwd() . $includeFile;
  }
  die "No such file '$includeFile'"       unless -e $includeFile;
  die "File not readable: '$includeFile'" unless -r $includeFile;
  
  my $content = $context->getSingleton('O2::File')->getFile($includeFile);
  my $originalContent = $content;

  # First - see if any localized params are passed in to the included file/taglet
  my %scope;
  foreach (keys %params) {
    if ($_ eq 'content') {
      delete $params{content};
      next;
    }
    my $currentValue = $obj->{parser}->getVar($_);
    my $newValue = $params{$_};
    $scope{$_} = $currentValue; # Backup, so the variable can be reset when the scope is exited.
    my ($matchedVariable, $ignoreError) = $obj->{parser}->matchVariable( $params{$_} );
    if ($matchedVariable eq $params{$_} || "^$matchedVariable" eq $params{$_}) { # The parameter is exactly one variable (f ex: obj="$obj->getParent()")
      $newValue = $obj->{parser}->findVar( $matchedVariable, undef, 1 ); # Don't encode entities
    }
    else {
      $obj->{parser}->parseVars(\$newValue, undef, 1); # Don't encode entities
    }
    $obj->{parser}->setVar($_, $newValue);
  }

  # Parse the file/taglet with any localized params
  $obj->{parser}->pushProperty('currentTemplate', $includeFile);
  $obj->{parser}->_parse(\$content);
  $obj->{parser}->popProperty('currentTemplate');

  if ($cacheKey && $content =~ m{ \S }xms) {
    debug "Caching with key: $cacheKey";
    my $string = $originalContent;
    my $pre  = qq{<o2 use Html />};
    $pre    .= qq{<o2 incMetaHeader /><o2 incLinkTags /><o2 incJavascript includeOnLoadJs="1" /><o2 incStylesheet />} if $string !~ m{ <o2 (?: header | incLinkTags | incJavascript | incStylesheet ) \b }xms;
    my $post = qq{};
    $post   .= qq{<o2 postJavascript />} if $string !~ m{ <o2 (?: footer | postJavascript ) \b }xms;
    $string  = qq{$pre$string$post};
    
    require O2::Template;
    my $template = O2::Template->newFromString($string);
    $template->setLocale(          $context->getLocale() );
    $template->setCurrentTemplate( $includeFile          );
    my $tagParser = $template->getTagParser();
    my %vars = ( $obj->{parser}->getVars(), %params );
    foreach (keys %vars) {
      $tagParser->setVar( $_, $obj->{parser}->getVar($_) );
    }

    my %displayParams = $context->getDisplayParams();
    my $_content = ${ $template->parse(%displayParams) };
    $cacher->set( $cacheKey, $_content, ttl => $params{cacheTtl} || 24*3600 );
  }
  
  # Restore values of params that existed before the localization
  foreach (keys %scope) {
    $obj->{parser}->setVar($_, $scope{$_});
  }
  
  return $content;
}
#----------------------------------------------------
# converts path relative to O2CUSTOMER or O2ROOT full path
sub _resolveTemplatePath {
  my ($obj, $path) = @_;
  foreach my $root ($context->getEnv('O2CUSTOMERROOT'), $context->getEnv('O2ROOT')) {
    return "$root/$path" if -e "$root/$path";
  }
  return;
}
#----------------------------------------------------
sub comment {
  return '';
}
#----------------------------------------------------
sub doubleParse {
  my ($obj, %params) = @_;
  $obj->{parser}->_parse( \$params{content} );
  return $params{content};
}
#----------------------------------------------------
sub appendVar {
  my ($obj, %params) = @_;
  my $variableName = $params{param};
  my $oldValue     = $obj->{parser}->findVar( $params{param}, undef, 1 );
  $obj->{parser}->_parse( \$params{content} );
  $params{delimiter} = '' unless length $params{delimiter};
  my $appendValue    = $params{content};
  my $newValue       = $oldValue  ?  "$oldValue$params{delimiter}$appendValue"  :  $appendValue;
  $obj->{parser}->setVar( $params{param}, $newValue );
  return '';
}
#----------------------------------------------------
1;
