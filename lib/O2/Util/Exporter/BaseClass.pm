package O2::Util::Exporter::BaseClass;

use strict;

#------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $obj = bless(
    {
      fields => undef,
      fieldSequence => undef,
      _hashFields => undef,
      _hashFieldSequence => undef,
    }, $pkg
  );
  return $obj;
}
#------------------------------------------------------------
# export the following PLDS to this string
sub export {
  my ($obj,%params)=@_;
  die __PACKAGE__.' method "export "must be overiden';
}
#------------------------------------------------------------
# import the following file to a PLDS
sub parse {
  my ($obj,%params)=@_;
  die __PACKAGE__.' method "import" must be overiden';
}
#------------------------------------------------------------
sub setFields {
  my ($obj,$fields)=@_;
  $obj->{fields} = $fields;
  $obj->{_hashFields} = undef;
}
#------------------------------------------------------------
sub getFields {
  my ($obj)=@_;
  return @{$obj->{fields}};
}
#------------------------------------------------------------
sub setFieldSequence {
  my ($obj,$fieldSequence)=@_;
  $obj->{fieldSequence} = $fieldSequence;
  $obj->{_hashFieldSequence}  = undef;
}
#------------------------------------------------------------
sub getFieldSequence {
  my ($obj)=@_;
  return @{$obj->{fieldSequence}} if ref $obj->{fieldSequence} eq 'ARRAY';
}
#------------------------------------------------------------
sub useField {
  my ($obj,$field)=@_;
  if( $obj->{fieldSequence} ) { # ok, we using bunch of arrays
    %{$obj->{_hashFieldSequence}} = map {$_ => 1} @{$obj->{fieldSequence}} unless ref $obj->{_hashFieldSequence} eq 'HASH';
    return exists( $obj->{_hashFields}->{$field} ) ;
  }
  
  return 1 if !$obj->{fields} || @{$obj->{fields}} == -1;
  %{$obj->{_hashFields}} = map {$_ => 1} @{$obj->{fields}} unless ref $obj->{_hashFields} eq 'HASH';
  return exists( $obj->{_hashFields}->{$field} ) ;
}
#------------------------------------------------------------
sub detectFields {
  my ($obj,$data)=@_;
  my $firstElm= undef;
  if( ref $data eq 'ARRAY' ) {
    $firstElm = $data->[0];
  }
  elsif(ref $data eq 'HASH') {
    my @k = keys %{$data};
    my $firstElmKey = shift @k;
    $firstElm = $data->{$firstElmKey};
  }

  if( ref $firstElm eq 'HASH' ) {
    my @detectedFields = sort keys %{$firstElm};
    $obj->setFields(\@detectedFields);
  }
  # couldn't not detect fields, not necesarry wrong
  return 1;
}
#------------------------------------------------------------
1;
