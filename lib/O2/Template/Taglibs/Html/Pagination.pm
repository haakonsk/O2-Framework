package O2::Template::Taglibs::Html::Pagination;

use strict;

use base 'O2::Template::Taglibs::Html::Form';

use O2 qw($context $cgi);

#-----------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my $obj = bless { parser => $params{parser} }, $package;
  my %methods = (
    pagination => 'postfix',
  );
  $obj->addCssFile( file => 'bootstrap.min' );
  $obj->addJsFile(  file => 'bootstrap.min' );
  return ($obj, %methods);
}
#-----------------------------------------------------------------------------
sub pagination {
  my ($obj, %params) = @_;
  my $skip       = $cgi->getParam('skip') || 0;
  my $numPerPage = $params{numPerPage};
  $obj->{parser}->parseVars(\$numPerPage) if $numPerPage =~ m{ \$ }xms;
  $obj->{parser}->setProperty('paginationNumPerPage', $numPerPage);

  my $totalNumResults;

  my @results;
  if (exists $params{elements}) {
    my $code = $params{elements};
    $code    =~ s{ \$skip  }{ $skip       ||  0 }xmse;
    $code    =~ s{ \$limit }{ $numPerPage || 10 }xmse;
    my $elementsCode = $code;
    $code    = $obj->{parser}->externalDereference($code);
    @results = eval $code;
    die "Error during eval of the 'elements' attribute ( elements=\"$elementsCode\" ): $@" if $@;
    $totalNumResults = $obj->{parser}->findVar( $params{totalNumResults} ); # Total number of results may only be available after the elements attribute has been evaluated.
  }
  else {
    $totalNumResults = $obj->{parser}->findVar( $params{totalNumResults} );
    my $limit = $skip+$numPerPage <= $totalNumResults  ?  $skip+$numPerPage  :  $totalNumResults;
    @results = ($skip .. $limit-1);
  }

  $obj->{parser}->setProperty('paginationTotalNumResults', $totalNumResults);
  my $nextSkip = $skip + $numPerPage <  $totalNumResults ? $skip + $numPerPage : -1;
  my $prevSkip = $skip - $numPerPage >= 0                ? $skip - $numPerPage : -1;
  my $content = $params{content};
  $obj->{parser}->pushVar( 'paginationResults',         \@results        );
  $obj->{parser}->pushVar( 'paginationTotalNumResults', $totalNumResults );
  $obj->{parser}->pushVar( 'paginationFirstIndex',      $skip+1          );
  $obj->{parser}->pushVar( 'paginationLastIndex',       $skip+$numPerPage <= $totalNumResults ? $skip+$numPerPage : $totalNumResults );
  $obj->{parser}->pushMethod( 'paginationNavigation', $obj );
  $obj->{parser}->pushMethod( 'previousLink',         $obj );
  $obj->{parser}->pushMethod( 'numericPageLinks',     $obj );
  $obj->{parser}->pushMethod( 'nextLink',             $obj );
  $content = ${ $obj->{parser}->_parse(\$content) };
  $obj->{parser}->popMethod( 'paginationNavigation' );
  $obj->{parser}->popMethod( 'previousLink'         );
  $obj->{parser}->popMethod( 'numericPageLinks'     );
  $obj->{parser}->popMethod( 'nextLink'             );
  $obj->{parser}->popVar( 'paginationResults'         );
  $obj->{parser}->popVar( 'paginationTotalNumResults' );
  $obj->{parser}->popVar( 'paginationFirstIndex'      );
  $obj->{parser}->popVar( 'paginationLastIndex'       );
  return $content;
}
#--------------------------------------------------------------------------------------#
sub paginationNavigation {
  my ($obj, %params) = @_;
  my $html = "<ul class='pagination'>\n";
  if ($params{content}) { # Content is already parsed
    return "$html$params{content}</ul>\n";
  }
  my $prevLink = $obj->previousLink();
  my $nextLink = $obj->nextLink();
  $html .= $obj->previousLink();
  $html .= $obj->numericPageLinks();
  $html .= $obj->nextLink();
  $html .= "</ul>\n";
  return $html;
}
#--------------------------------------------------------------------------------------#
sub previousLink {
  my ($obj, %params) = @_;
  $params{class} ||= 'paginationPrevious';
  my $skip       = $cgi->getParam('skip') || 0;
  my $numPerPage = $obj->{parser}->getProperty('paginationNumPerPage');
  my $prevSkip   = $skip - $numPerPage >= 0 ? $skip - $numPerPage : -1;
  my $o2ml = '';
  $o2ml = "<li><o2 link setParam='skip=$prevSkip' " . $obj->_packTagAttribs(%params) . '>' . ($params{content} || $context->getLang()->getString('o2.pagination.previous')) . '</o2:link></li> ' if $prevSkip != -1;
  return ${ $obj->{parser}->_parse(\$o2ml) };
}
#--------------------------------------------------------------------------------------#
sub numericPageLinks {
  my ($obj, %params) = @_;
  my $math = $context->getSingleton('O2::Util::Math');
  my $numBefore      = $params{numBefore}     || 10;
  my $numAfter       = $params{numAfter}      || 10;
  my $skip           = $cgi->getParam('skip') ||  0;
  my $numPerPage     = $obj->{parser}->getProperty('paginationNumPerPage');
  my $totalNumPages  = $math->ceil(  $obj->{parser}->getVar('paginationTotalNumResults') / $numPerPage  );
  my $currentPageNum = $math->ceil(  $skip / $numPerPage  ) + 1;
  my $firstPageNum   = $currentPageNum-$numBefore > 0               ?  $currentPageNum-$numBefore   :  1;
  my $lastPageNum    = $currentPageNum+$numAfter  > $totalNumPages  ?  $totalNumPages               :  $currentPageNum+$numAfter;

  my $o2ml = '';
  for my $index ($firstPageNum .. $lastPageNum) {
    my $currentSkip = $numPerPage * ($index-1);
    $params{class} ||= 'paginationNumeric';
    if ($index == $currentPageNum) {
      my $class = "$params{class}";
      $o2ml .= "<li class='active'><span class='$class' " . $obj->_packTagAttribs(%params) . ">$index</span></li> " if $currentPageNum != $firstPageNum || $currentPageNum != $lastPageNum;
    }
    else {
      $o2ml .= "<li><o2 link setParam='skip=$currentSkip' " . $obj->_packTagAttribs(%params) . ">$index</o2:link></li> ";
    }
  }
  return ${ $obj->{parser}->_parse(\$o2ml) };
}
#--------------------------------------------------------------------------------------#
sub nextLink {
  my ($obj, %params) = @_;
  $params{class} ||= 'paginationNext';
  my $skip       = $cgi->getParam('skip') || 0;
  my $numPerPage = $obj->{parser}->getProperty('paginationNumPerPage');
  my $totalNumResults = $obj->{parser}->getProperty('paginationTotalNumResults');
  my $nextSkip = $skip + $numPerPage <  $totalNumResults ? $skip + $numPerPage : -1;
  my $o2ml = '';
  $o2ml = "<li><o2 link setParam='skip=$nextSkip' " . $obj->_packTagAttribs(%params) . '>' . ($params{content} || $context->getLang()->getString('o2.pagination.next')) . '</o2:link></li>' if $nextSkip != -1;
  return ${ $obj->{parser}->_parse(\$o2ml) };
}
#-----------------------------------------------------------------------------
1;
