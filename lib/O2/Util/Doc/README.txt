#!perl
# This is just a temporary solution... Feel free to change it..


# Heres a start;


package O2::Util::Doc::DocMaker;

sub new {
  my ($pkg, %params) = @_;
  die "No context-object supplied" unless ref $params{context};
  my $obj = bless {context => $params{context}}, $pkg;
  return $obj;
}

sub generateDocumentation {
  my ($obj) = @_;
  foreach my $documenter ( $obj->getDocumenters() ) {
    $documenter->generateDocumentation( docMaker => $obj);
  }
}

sub alertDocumenters {
  
}

sub getDocumenters {
  my ($obj) = @_;
  return @{ $obj->{documenters} };
}

sub setDocumenters {
  my ($obj, @documenters) = @_;
  if ($#documenters == 0 && ref $documenters[0] eq 'ARRAY') { # We were sent a reference to an array
    @documenters = @{ $documenters[0] }                       # Make sure we copy it so we don't carry
  }                                                           # with us the external reference
  $obj->{documenters} = \@documenters;
}

sub addDocumenter {
  my ($obj, $documenter) = @_;
  push @{ $obj->{documenters} }, $documenter;
}

