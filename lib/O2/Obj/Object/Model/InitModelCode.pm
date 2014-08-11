package O2::Obj::Object::Model::InitModelCode;

use strict;

# Object representing the code of the initModel method.
# We require the call to registerFields to come before the call to registerIndexes.
#
# Example usage:
#   require O2::Obj::Object::Model::InitModelCode;
#   my $initModelCodeObject = O2::Obj::Object::Model::InitModelCode->new($model);
#   $initModelCodeObject->addIndex($newIndex);
#   $initModelCodeObject->writeCodeToFile();

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, $model) = @_;
  my $obj = bless { model => $model }, $pkg;
  $obj->{codeBeforeFieldDefinitions}            = '';
  $obj->{fieldLines}                            = [];
  $obj->{fields}                                = {};
  $obj->{fieldsIndent}                          = '';
  $obj->{codeBetweenFieldDefinitionsAndIndexes} = '';
  $obj->{indexLines}                            = [];
  $obj->{indexesIndent}                         = '';
  $obj->{codeAfterIndexes}                      = '';
  $obj->setCode( $model->getCodeForManagerMethod('initModel') );
  return $obj;
}
#-----------------------------------------------------------------------------
sub getModel {
  my ($obj) = @_;
  return $obj->{model};
}
#-----------------------------------------------------------------------------
sub setCode {
  my ($obj, $code) = @_;
  my ($beforeCode, $fieldsIndent, $fields, $moreCode)
    = $code =~ m{
                  \A
                  ( .* \$model->registerFields\( \s* [\"\'] [^\"\']+ [\"\'] [ \t]*, \n
                    (?: ^ [ \t]* [#] .*? \n )* # Optional comment lines
                  )
                  ( [ \t]* )
                  ( .*?    )
                  ( \s*
                    (?: \); | ^ [ \t]* \# .* \n )
                  .* )
                  \z
              }xms;
  $fieldsIndent = '    ' unless $fields;
  $beforeCode   =~ s{ [ \t]* \z }{}xms; # Remove trailing spaces (indent)
  my ($betweenCode, $indexesIndent, $indexes, $afterCode);
  ($betweenCode, $indexes, $afterCode)
    = $moreCode =~ m{
                      \A
                      ( .* \$model->registerIndexes\( \s* [\"\'] [^\"\']+ [\"\'] [ \t]*, \n )
                      ( .*? )
                      ( ^ [ \t]* \); .* )
                      \z
                  }xms;
  $afterCode = $moreCode unless $betweenCode;
  if ($indexes) {
    ($indexesIndent, $indexes)
      = $indexes =~ m{
                      ( [ \t]* )
                      ( .*     )
                  }xms;
  }
  $indexesIndent = '    ' unless $indexes;
  my @fieldLines = split /\n/, $fields;
  $fieldLines[0] = $fieldsIndent . $fieldLines[0] if @fieldLines; # The first line has been stripped of its indentation, so let's add it again.
  $obj->{codeBeforeFieldDefinitions}           = $beforeCode;
  $obj->{fieldLines}                           = \@fieldLines;
  $obj->{fieldsIndent}                         = $fieldsIndent;
  $obj->{codeBetweenFieldDefinitionAndIndexes} = $betweenCode || '';
  $obj->{indexLines}                           = [ split /\n/, $indexes || '' ];
  $obj->{indexesIndent}                        = $indexesIndent;
  $obj->{codeAfterIndexes}                     = $afterCode || $moreCode;
  $obj->_setFields($fields);
}
#-----------------------------------------------------------------------------
sub writeCodeToFile {
  my ($obj) = @_;
  my $model = $obj->getModel();
  my $oldCode = $model->getCodeForManagerMethod('initModel');
  die "No old code" unless $oldCode;
  my $newCode = $obj->_getCode();
  return if $newCode eq $oldCode;
  my $managerCode = $model->_getManagerSourceCode();
  $managerCode =~ s{\Q$oldCode\E}{$newCode}xms;
  $model->_setManagerSourceCode($managerCode);
  $model->_saveManagerSourceCode();
}
#-----------------------------------------------------------------------------
sub _getCode {
  my ($obj) = @_;
  $obj->_alignFieldLines();
  $obj->_alignIndexLines();
  my $code = $obj->{codeBeforeFieldDefinitions};
  my $fieldDefinitions = '';
  foreach my $line (@{ $obj->{fieldLines} }) {
    $fieldDefinitions .= "$line\n" if $line;
  }
  $fieldDefinitions = substr $fieldDefinitions, 0, -1 if $fieldDefinitions !~ m{ \A \n* \z }xms; # Remove last new-line
  $code .= $fieldDefinitions . $obj->{codeBetweenFieldDefinitionAndIndexes};
  my $hasIndexes = join('', @{ $obj->{indexLines} }) ? 1 : 0;
  if ($obj->{codeBetweenFieldDefinitionAndIndexes} && $hasIndexes) {
    # $model->registerIndexes() was called before and there are still database indexes for this class
    foreach my $line (@{ $obj->{indexLines} }) {
      $code .= "$line\n" if $line;
    }
    return $code . $obj->{codeAfterIndexes};
  }
  if (!$obj->{codeBetweenFieldDefinitionAndIndexes} && $hasIndexes) {
    # $model->registerIndexes() wasn't called before, but now it must be called, since one or more indexes have been added
    $code .= $obj->{codeAfterIndexes};
    my $className  = $obj->getModel()->getClassName();
    my $indexLines = '';
    foreach my $line (@{ $obj->{indexLines} }) {
      $indexLines .= "$line\n" if $line;
    }
    my $registerIndexesCode = "  \$model->registerIndexes(\n    '$className',\n$indexLines  );\n";
    $code =~ s[ } \z ][$registerIndexesCode}]xms;
    return $code;
  }
  if ($obj->{codeBetweenFieldDefinitionAndIndexes} && !$hasIndexes) {
    # $model->registerIndexes() was called before, but now there aren't any indexes anymore, so let's remove the call to registerIndexes.
    $code .= $obj->{codeAfterIndexes};
    $code =~ s{ ^ [ \t]* \$model->registerIndexes\( .*? \); \n }{}xms;
    return $code;
  }
  # $model->registerIndexes() wasn't called before, and there still aren't any indexes
  return $code . $obj->{codeAfterIndexes};
}
#-----------------------------------------------------------------------------
sub _setFields {
  my ($obj, $fieldsString) = @_;
  my %fields = eval $fieldsString;
  foreach my $fieldName (keys %fields) {
    my $field = $obj->getModel()->_createField( $obj->getModel()->getClassName(), $fieldName, $fields{$fieldName} );
    $fields{$fieldName} = $field->getFieldInfo();
  }
  foreach my $line (@{ $obj->{fieldLines} }) {
    if (my ($fieldName, $comment) = $line =~ m{ \s* (\w+) \s* => \s* \{ .*? \},? \s* (?: \# \s* (.+) )? }xms) {
      $fields{$fieldName}->{comment} = $comment if $fieldName && $fields{$fieldName} && $comment;
    }
  }
  $obj->{fields} = \%fields;
}
#-----------------------------------------------------------------------------
sub getFields {
  my ($obj) = @_;
  return %{ $obj->{fields} };
}
#-----------------------------------------------------------------------------
sub addField {
  my ($obj, $field) = @_;
  my $fieldInfo = $field->getFieldInfo();
  $obj->{fields}->{ $fieldInfo->{name} } = $fieldInfo;
  push @{ $obj->{fieldLines} }, $obj->_getCodeLineForFieldHash($fieldInfo);
}
#-----------------------------------------------------------------------------
sub modifyField {
  my ($obj, $fieldName, $field) = @_;
  my $fieldInfo = $field ? $field->getFieldInfo() : undef;
  
  delete $obj->{fields}->{$fieldName};
  $obj->{fields}->{ $fieldInfo->{name} } = $fieldInfo if $fieldInfo;
  
  my @lines = @{ $obj->{fieldLines} };
  for my $i (0 .. $#lines) {
    my ($name) = $lines[$i] =~ m{ (\w+) \s* => \s* \{ }xms;
    if ($name eq $fieldName) {
      $lines[$i] = $obj->_getCodeLineForFieldHash($fieldInfo);
      last;
    }
  }
  $obj->{fieldLines} = [ @lines ];
  
  if ($fieldInfo && $fieldName ne $fieldInfo->{name}) {
    # A field was renamed, update indexes that are using that field
    @lines = @{ $obj->{indexLines} };
    for my $i (0 .. $#lines) {
      $lines[$i] =~ s{ (columns .*) \b $fieldName \b }{$1$fieldInfo->{name}}xms;
    }
    $obj->{indexLines} = [ @lines ];
  }
}
#-----------------------------------------------------------------------------
sub deleteField {
  my ($obj, $fieldName) = @_;
  $obj->modifyField($fieldName, undef);
}
#-----------------------------------------------------------------------------
sub addIndex {
  my ($obj, $indexHash) = @_;
  push @{ $obj->{indexLines} }, $obj->_getCodeLineForIndexHash($indexHash);
}
#-----------------------------------------------------------------------------
sub modifyIndex {
  my ($obj, $indexName, $indexHash) = @_;
  my @lines = @{ $obj->{indexLines} };
  for my $i (0 .. $#lines) {
    my ($name) = $lines[$i] =~ m{ name \s* => \s* ['"] (\w+) ['"] }xms;
    if ($name eq $indexName) {
      $lines[$i] = $obj->_getCodeLineForIndexHash($indexHash);
      last;
    }
  }
  $obj->{indexLines} = \@lines;
}
#-----------------------------------------------------------------------------
sub _getCodeLineForIndexHash {
  my ($obj, $indexHash) = @_;
  return '' unless $indexHash;
  return sprintf "{ name => '$indexHash->{name}', columns => [qw(%s)], isUnique => $indexHash->{isUnique} },", join ' ', @{ $indexHash->{columns} };
}
#-----------------------------------------------------------------------------
sub _getCodeLineForFieldHash {
  my ($obj, $fieldHash) = @_;
  return '' unless $fieldHash;

  # Translate validValues to a string that eval'uates to an array ref
  my @validValues;
  foreach my $validValue (@{ $fieldHash->{validValues} }) {
    $validValue =~ s{\'}{\\\'}xmsg;
    push @validValues, $validValue;
  }
  my $validValues = join "', '", @validValues;
  $validValues    = "['$validValues']" if $validValues;

  my $line = sprintf $obj->{fieldsIndent} . "$fieldHash->{name} => {";
  $line   .= sprintf  " %s => '$fieldHash->{type}'",         'type';
  $line   .= sprintf ", %s => '$fieldHash->{length}'",       'length'       if $fieldHash->{length};
  $line   .= sprintf ", %s => '$fieldHash->{listType}'",     'listType'     if $fieldHash->{listType} ne 'none';
  $line   .= sprintf ", %s => 1",                            'multilingual' if $fieldHash->{multilingual};
  $line   .= sprintf ", %s => 1",                            'notNull'      if $fieldHash->{notNull};
  $line   .= sprintf ", %s => '$fieldHash->{defaultValue}'", 'defaultValue' if length $fieldHash->{defaultValue};
  $line   .= sprintf ", %s => $validValues",                 'validValues'  if $validValues;
  $line   .= ' },';
  $line   .= " # $fieldHash->{comment}" if $fieldHash->{comment};
  return $line;
}
#-----------------------------------------------------------------------------
sub deleteIndex {
  my ($obj, $indexName) = @_;
  $obj->modifyIndex($indexName, undef);
}
#-----------------------------------------------------------------------------
sub _alignIndexLines {
  my ($obj) = @_;
  my ($maxNameLength, $maxColumnsLength) = (0, 0);
  my @lines = @{ $obj->{indexLines} };
  foreach my $line (@lines) {
    my ($name) = $line =~ m{ name \s* => \s* ['"] (\w+) ['"] }xms;
    my $lengthOfName = length $name;
    $maxNameLength = $lengthOfName if $lengthOfName > $maxNameLength;
    my ($columns) = $line =~ m{ columns \s* => \s* ( \[ .*? \] ) }xms;
    my $lengthOfColumns = length $columns;
    $maxColumnsLength = $lengthOfColumns if $lengthOfColumns > $maxColumnsLength;
  }
  for my $i (0 .. $#lines) {
    $lines[$i] =~ s{ ,[ ]+ }{, }xmsg;
    $lines[$i] =~ s{ ( name    \s* => \s* ['"] )  (\w+)  ( ['"] )  (,?)  }{ "$1$2$3$4" . ' ' x ($maxNameLength    - length $2) }xmse;
    $lines[$i] =~ s{ ( columns \s* => \s*      )    ( \[ .*? \] )  (,?)  }{ "$1$2$3"   . ' ' x ($maxColumnsLength - length $2) }xmse;
    $lines[$i] =~ s{ \A [ ]* }{ ' ' x length $obj->{indexesIndent} }xmse if $lines[$i];
  }
  $obj->{indexLines} = \@lines;
}
#-----------------------------------------------------------------------------
sub _alignFieldLines {
  my ($obj) = @_;
  my ($maxNameLength, $maxHashLength) = (0, 0);
  my @lines = @{ $obj->{fieldLines} };
  foreach my $line (@lines) {
    my ($name, $hash) = $line =~ m{ (\w+) \s* => \s* { ([^\n]+?) [ ]* } }xms;
    my $lengthOfName = length $name;
    my $lengthOfHash = length $hash;
    $maxNameLength = $lengthOfName if $lengthOfName && $lengthOfName > $maxNameLength;
    $maxHashLength = $lengthOfHash if $lengthOfHash && $lengthOfHash > $maxHashLength;
  }
  for my $i (0 .. $#lines) {
    $lines[$i] =~ s{ [ ]+ => }{ =>}xmsg;
    $lines[$i] =~ s{ (\w+) (\s* => \s*) { ([^\n]+?) [ ]* }, }{ $1 . (' ' x ($maxNameLength - length $1)) . $2 . "\{$3" . (' ' x ($maxHashLength - length $3)) . ' \},' }xmse;
  }
  $obj->{fieldLines} = \@lines;
}
#-----------------------------------------------------------------------------
1;
