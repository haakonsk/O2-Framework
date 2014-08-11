package O2::Util::XMLGenerator;

use strict;

#------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $obj = bless {}, $package;
  $obj->setNamespace( $params{namespace}->[0], $params{namespace}->[1] ) if ref $params{namespace} eq 'ARRAY';
  $obj->setEncoding(  $params{encoding}                                ) if     $params{encoding};
  return $obj;
}
#------------------------------------------------------------------------------------------
sub getNamespace {
  my ($obj) = @_;
  return $obj->{ns}, $obj->{nsURI};
}
#------------------------------------------------------------------------------------------
sub setNamespace {
  my ($obj, $ns, $URI) = @_;
  $obj->{ns} = $ns;
  $obj->{nsURI} = $URI;
}
#------------------------------------------------------------------------------------------
sub getEncoding {
  my ($obj) = @_;
  return $obj->{enc};
}
#------------------------------------------------------------------------------------------
sub setEncoding {
  my ($obj, $value) = @_;
  $obj->{enc} = $value;
}
#------------------------------------------------------------------------------------------
sub toXml {
  my ($obj, $name, $ref) = @_;
  $obj->{indent} = -1;
  my ($ns, $URI) = $obj->getNamespace();
  $obj->{namespace} = $ns ? "$ns:" : '';
  my $encoding = $obj->getEncoding() || 'ISO-8859-1';

  my $xml = $obj->_unNest($name => $ref);

  return qq{<?xml version="1.0" encoding="$encoding"?>\n$xml};
}
#------------------------------------------------------------------------------------------
sub _unNest {
  my ($obj, $name, $value) = @_;
  $obj->{indent}++;

  my $newLine="\n";
  my $elementName = $obj->{namespace}._unEscape($name);
  my $elementNameFirst = $elementName;

  if ( !$obj->{indent} && $obj->{namespace}) { # hhhOk.. This is a tiny hack and it's not generic..
    my ($ns, $URI) = $obj->getNamespace();
    $elementNameFirst = $obj->{namespace}._unEscape($name). " xmlns:$ns=\"$URI\"";
  }

  my $return = '';
  if ( ref $value eq 'HASH') {
    $return = ('  ' x $obj->{indent})."<$elementNameFirst>$newLine";
    foreach ( sort keys %{$value} ) {
      $return .= $obj->_unNest($_ => $value->{$_})
    }
    $return .= ('  ' x $obj->{indent})."</$elementName>$newLine";
  }
  elsif ( ref $value eq 'ARRAY' ) {
    $obj->{indent}--;
    foreach ( @{$value} ) {
      $return .= $obj->_unNest($name, $_);
    }
    $obj->{indent}++;
  }
  else {
    my $elementValue = _unEscape($value);
    $return = ('  ' x $obj->{indent})."<$elementNameFirst>$elementValue</$elementName>$newLine";
  }
  $obj->{indent}--;
  return $return;
}
#------------------------------------------------------------------------------------------
sub _unEscape {
  my ($value) = @_;
  return '' unless length $value;

  $value =~ s/&/&amp;/g;
  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;

  return $value;
}
#------------------------------------------------------------------------------------------
1;
