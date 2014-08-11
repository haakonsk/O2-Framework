package O2::Util::Exporter::CSV;

# Generate CSV file according to RFC4180
# ref: http://tools.ietf.org/html/rfc4180
# params:
#   csvDelimiter: use this as record delimiter
#   csvRowDelimiter: use this as row delimiter
#   csvDisableEscape: disable escaping according to RFC4180

use strict;

use base 'O2::Util::Exporter::BaseClass';

#------------------------------------------------------------
sub export {
  my ($obj, %params) = @_;
  
  my $csv = '';
  
  $obj->{delimiter}     = $params{csvDelimiter}     || ',';
  $obj->{rowDelimiter}  = $params{csvRowDelimiter}  || "\n";
  $obj->{disableEscape} = $params{csvDisableEscape} || 0;
  
  if ($params{csvIncludeHeader}) {
    if (!$obj->getFields) {
      $obj->detectFields( $params{data} );
    }
    my @fields = $obj->getFields();
    if (@fields) {
      $obj->_escapeRow(\@fields);
      $csv .= join ($obj->{delimiter}, @fields) . $obj->{rowDelimiter};
    }
  }
  
  if (ref $params{data} eq 'ARRAY') {
    foreach my $row (@{ $params{data} }) {
      $csv .= join ( $obj->{delimiter}, @{ $obj->_handleRow($row) } ) . $obj->{rowDelimiter};
    }
  }
  elsif (ref $params{data} eq 'HASH') {
    foreach my $row (sort keys %{ $params{data} }) {
      $csv .= join ( $obj->{delimiter}, @{ $obj->_handleRow( $params{data}->{$row} ) } ) . $obj->{rowDelimiter};
    }
  }
  return $csv;
}
#------------------------------------------------------------
sub _handleRow {
  my ($obj, $row) = @_;
  my @row;
  if (ref $row eq 'HASH') {
    my @fields = $obj->getFields();
    @fields = sort keys %{$row} unless @fields; # no sequence is given
    
    foreach my $field (@fields) {
      if ($obj->useField($field)) {
        push @row, $obj->_escape( $row->{$field} );
      }
    }
  }
  elsif (ref $row eq 'ARRAY') {
    my @fields = $obj->getFieldSequence();
    @fields = (0 .. $#{$row}) unless $#fields >= $#{$row}; # no sequence is given
    foreach my $idx (@fields) {
      push @row, $obj->_escape( $row->[$idx] );
    }
  }
  return \@row;
}
#------------------------------------------------------------
sub _escapeRow {
  my ($obj, $row) = @_;
  for (my $i = 0; $i < @{$row}; $i++) {
    $row->[$i] = $obj->_escape( $row->[$i] );
  }
}
#------------------------------------------------------------
sub _escape {
  my ($obj, $str) = @_;
  return $str if $obj->{disableEscape};
  
  my $q = '';
  if ($str =~ m/^\s+.+/xms || $str =~ m/.+\s+$/xms || index ($str,',') > -1) {
    $q = '"';
  }
  if (index ($str, '"') > -1 ) {
    $str =~ s/\"/\"\"/gmxs;
    $q = '"';
  }
  return $q . $str . $q;
}
#------------------------------------------------------------
sub _unEscape {
  my ($obj, $str) = @_;
  return $str if $obj->{disableEscape};
  
  $str =~ s/\"//gxms;
  return $str;
}
#------------------------------------------------------------
# parse/import code from here
#------------------------------------------------------------
# per default it will parse data into and array with ano hashs if header is included
# otherwise it will parse data into array with ano arrays
#
sub parse {
  my ($obj, %params) = @_;
  my $plds = undef;
  use Encode;
  use Encode qw(is_utf8);
  $obj->{disableEscape} = $params{csvDisableEscape} || 0;
  $obj->{delimiter}     = $params{csvDelimiter}     || ',';
  $obj->{rowDelimiter}  = $params{csvRowDelimiter};
  if (!$obj->{rowDelimiter}) {
    if (${ $params{data} } =~ m{ (\s+) \z }xms) {
      $obj->{rowDelimiter} = $1;
    }
    $obj->{rowDelimiter} ||= "\n";
  }
  
  ${ $params{data} } = $obj->_escapeQoutedStringsInString( ${ $params{data} }, '"', ($obj->{rowDelimiter} => '&rowDelimiter;') );
  my @data = split /$obj->{rowDelimiter}/, ${ $params{data} };
  
  my @fields;
  if ($params{csvIncludeHeader}) { # ok, treats first line as an header
    my $header = shift @data;
    $header =~ s/\"//g;
    if (!is_utf8($header)) {
      $header = encode('utf-8', $header);
    }
    @fields = split /$obj->{delimiter}/, $header;
  }
  
  while (@data) {
    my $row = shift @data;
    $row =~ s/\"\"/&qoute;/gxms; # escaping escaped qoute "" -> &qoute;
    $row = $obj->_escapeQoutedStringsInString($row, '"', ($obj->{delimiter} => 'DeLiMiTeR')); 
    $row = $obj->_unEscape($row);
    $row =~ s/\&qoute\;/\"/gxms;
    
    my @row = split /$obj->{delimiter}/, $row;
    for (my $i = 0; $i < @row; $i++) {
      $row[$i] =~ s/DeLiMiTeR/$obj->{delimiter}/gxms;
      $row[$i] =~ s/\&rowDelimiter\;/$obj->{rowDelimiter}/gxms;
    }
    if (@fields) {
      my %row = map { $_ => shift @row } @fields;
      push @{$plds}, \%row;
    }
    else {
      push @{$plds}, \@row;
    }
  }
  
  return $plds;
}
#------------------------------------------------------------
sub _escapeQoutedStringsInString {
  my ($obj, $string, $qouteChar, %rules) = @_;
  my ($s, $e) = (0, 0);
  
  while ($s > -1 && $e > -1) {
    $s = index $string, $qouteChar, $s;
    last unless $s > -1;
    
    $e = index $string, $qouteChar, $s+1;
    if ($s > -1 && $e > $s) {
      my $tmp = substr $string, $s+1, $e-$s-1, '<escaped>';
      foreach my $char (keys %rules) {
        if ($char eq "\n" ) {
          $tmp =~ s/\n/$rules{$char}/gxms;
        }
        else {
          $tmp =~ s/$char/$rules{$char}/gms;
        }
      }
      $s += length ($tmp) + 2;
      $string =~ s/\<escaped\>/$tmp/xms;
    }
  }
  return $string;
}
#------------------------------------------------------------
1;
