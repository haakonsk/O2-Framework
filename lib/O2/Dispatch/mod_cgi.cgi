#!/usr/bin/env perl

use strict;

require O2::Cgi;
require O2::Dispatch;

my $cgi = O2::Cgi->new();
$cgi->import();
my $dispatch = O2::Dispatch->new();
$dispatch->dispatch(cgi => $cgi);
