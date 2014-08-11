package O2::Util::Exporter;

# Exporter tool to generate CSV/XML files based on a perl data structure.
# This is not the same as O2::Util::Seralizer

use strict;

#------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless {}, $pkg;
}
#------------------------------------------------------------
# Export the following PLDS to this string
sub export {
  my ($obj, %params) = @_;
  my $exporter = $obj->_getExportTypeObject( $params{format} );

  my $fields;
  if ( $params{fields} && ref $params{fields} eq 'ARRAY' ) {
    $exporter->setFields( $params{fields} );
  }
  if ( $params{fieldSequence} && ref $params{fieldSequence} eq 'ARRAY' ) {
    $exporter->setFieldSequence( $params{fieldSequence} );
  }
 
  return $exporter->export(%params);
}
#------------------------------------------------------------
sub exportToFile {
  my ($obj, %params) = @_;
  my $file = $params{file};

  die 'No file to save export to is given' unless    $file;
  die "File exists '$file'"                    if -e $file || -d $file;
  
  my $export = $obj->export(%params);
  return $context->getSingleton('O2::File')->writeFile($file, $export);
}
#------------------------------------------------------------
# Import the following file to a PLDS
sub parse {
  my ($obj, %params) = @_;
  my $exporter = $obj->_getExportTypeObject( $params{format} );
  return $exporter->parse(%params);
}
#------------------------------------------------------------
sub parseFromFile {
  my ($obj, %params) = @_;
  my $file = $params{file};
  
  die 'No fileName givem to import from is given' unless    $file;
  die "Given file name doesn't exist: '$file'"    unless -e $file;
  
  $params{data} = $context->getSingleton('O2::File')->getFileRef($file);
  return $obj->parse(%params);
}
#------------------------------------------------------------
sub _getExportTypeObject {
  my ($obj, $class) = @_;
  my $className = "O2::Util::Exporter::$class";
  eval "require $className;";
  die "Could not load class '$className': $@" if $@;
  
  my $object = eval {
    $className->new();
  };
  die "new $className didn't return a ref: $@" unless ref $object;
  
  return $object
}
#------------------------------------------------------------
1;
