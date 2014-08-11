use strict;
use Test::More qw(no_plan);
use O2::Util::List qw(upush contains);

my @letters;
upush @letters, 'a';
upush @letters, 'b';
upush @letters, 'b';
upush @letters, 'c';
upush @letters, 'c';
upush @letters, 'c';
upush @letters, 'a';

is_deeply(\@letters, [ qw(a b c) ], 'upush seems to work');

ok(  contains( @letters, 'a'       ), '@letters contains a'                    );
ok(  contains( @letters, qw(a b)   ), '@letters contains a and b'              );
ok(  contains( @letters, qw(a b c) ), '@letters contains a, b and c'           );
ok( !contains( @letters, qw(a d)   ), '@letters doesn\'t contain both a and d' );
ok( !contains( @letters, 'd'       ), '@letters doesn\'t contain d'            );
