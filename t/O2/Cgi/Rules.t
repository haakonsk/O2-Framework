use strict;

use Test::More qw(no_plan);
use O2::Script::Test::Common;

require O2::Cgi::Rules;
my $rules = O2::Cgi::Rules->new();

diag 'int:,2';
ok( !$rules->validate( "int:,2", 'hi' ), "Not verified:  'hi'" );
ok(  $rules->validate( "int:,2", -10  ), "Verified:      -10"  );
ok(  $rules->validate( "int:,2",   0  ), "Verified:        0"  );
ok(  $rules->validate( "int:,2",   1  ), "Verified:        1"  );
ok(  $rules->validate( "int:,2",   2  ), "Verified:        2"  );
ok( !$rules->validate( "int:,2",   3  ), "Not verified:    3"  );
ok( !$rules->validate( "int:,2",  30  ), "Not verified:   30"  );

diag 'int:notRequired';
ok(  $rules->validate( "int:,2:notRequired", '' ), "Verified: ''" );
ok(  $rules->validate( "int:notRequired",    '' ), "Verified: ''" );

diag 'int:-3,6';
ok( !$rules->validate( "int:-3,6", 'hi' ), " Not verified: 'hi'" );
ok( !$rules->validate( "int:-3,6",  10  ), " Not verified:  10"  );
ok(  $rules->validate( "int:-3,6",   0  ), "Verified:        0"  );
ok(  $rules->validate( "int:-3,6",   1  ), "Verified:        1"  );
ok(  $rules->validate( "int:-3,6",   2  ), "Verified:        2"  );
ok(  $rules->validate( "int:-3,6",   3  ), "Verified:        3"  );
ok( !$rules->validate( "int:-3,6",  30  ), "Not verified:   30"  );

diag 'int:2';
ok( !$rules->validate( "int:2", 'hi' ), "Not verified: 'hi'" );
ok( !$rules->validate( "int:2", -10  ), "Not verified: -10"  );
ok( !$rules->validate( "int:2",   0  ), "Not verified:   0"  );
ok( !$rules->validate( "int:2",   1  ), "Not verified:   1"  );
ok(  $rules->validate( "int:2",   2  ), "Verified:       2"  );
ok(  $rules->validate( "int:2",   3  ), "Verified:       3"  );
ok(  $rules->validate( "int:2",  30  ), "Verified:      30"  );

diag 'float:,2';
ok( !$rules->validate( "float:,2", 'hi'  ), "Not verified:  'hi'" );
ok(  $rules->validate( "float:,2", -10.2 ), "Verified:     -10.2" );
ok(  $rules->validate( "float:,2",   0.2 ), "Verified:       0.2" );
ok(  $rules->validate( "float:,2",   1.2 ), "Verified:       1.2" );
ok( !$rules->validate( "float:,2",   2.2 ), "Not verified:   2.2" );
ok( !$rules->validate( "float:,2",   3.2 ), "Not verified:   3.2" );
ok( !$rules->validate( "float:,2",  30.2 ), "Not verified:  30.2" );

diag 'float:notRequired';
ok(  $rules->validate( "float:,2:notRequired", '' ), "Verified: ''" );
ok(  $rules->validate( "float:notRequired",    '' ), "Verified: ''" );

diag 'float:-3.2,6.2';
ok( !$rules->validate( "float:-3.2,6.2", 'hi'  ), "Not verified:  'hi'" );
ok( !$rules->validate( "float:-3.2,6.2", -10.2 ), "Not verified: -10.2" );
ok(  $rules->validate( "float:-3.2,6.2",   0.2 ), "Verified:       0.2" );
ok(  $rules->validate( "float:-3.2,6.2",   1.2 ), "Verified:       1.2" );
ok(  $rules->validate( "float:-3.2,6.2",   2.2 ), "Verified:       2.2" );
ok(  $rules->validate( "float:-3.2,6.2",   3.2 ), "Verified:       3.2" );
ok( !$rules->validate( "float:-3.2,6.2",  30.2 ), "Not verified:  30.2" );

diag 'float:2.2';
ok( !$rules->validate( "float:2.2", 'hi'  ), "Not verified:  'hi'" );
ok( !$rules->validate( "float:2.2", -10.2 ), "Not verified: -10.2" );
ok( !$rules->validate( "float:2.2",   0.2 ), "Not verified:   0.2" );
ok( !$rules->validate( "float:2.2",   1.2 ), "Not verified:   1.2" );
ok(  $rules->validate( "float:2.2",   2.2 ), "Verified:       2.2" );
ok(  $rules->validate( "float:2.2",   3.2 ), "Verified:       3.2" );
ok(  $rules->validate( "float:2.2",  30.2 ), "Verified:      30.2" );

diag 'europeanDecimal:,2';
ok( !$rules->validate( "europeanDecimal:,2",  'hi' ), "Not verified:   'hi'" );
ok(  $rules->validate( "europeanDecimal:,2", -10.2 ), "Verified:      -10.2" );
ok(  $rules->validate( "europeanDecimal:,2",   0.2 ), "Verified:        0.2" );
ok(  $rules->validate( "europeanDecimal:,2",   1,2 ), "Verified:        1.2" );
ok( !$rules->validate( "europeanDecimal:,2",   2.2 ), "Not verified:    2.2" );
ok( !$rules->validate( "europeanDecimal:,2",   3.2 ), "Not verified:    3.2" );
ok( !$rules->validate( "europeanDecimal:,2",  30,2 ), "Not verified:   30.2" );

diag 'europeanDecimal:notRequired';
ok(  $rules->validate( "europeanDecimal:,2:notRequired", '' ), "Verified: ''" );
ok(  $rules->validate( "europeanDecimal:notRequired",    '' ), "Verified: ''" );

diag 'europeanDecimal:-3.2,6.2';
ok( !$rules->validate( "europeanDecimal:-3.2,6.2", 'hi'  ), "Not verified:  'hi'" );
ok( !$rules->validate( "europeanDecimal:-3.2,6.2", -10.2 ), "Not verified: -10.2" );
ok(  $rules->validate( "europeanDecimal:-3.2,6.2",   0.2 ), "Verified:       0.2" );
ok(  $rules->validate( "europeanDecimal:-3.2,6.2",   1.2 ), "Verified:       1.2" );
ok(  $rules->validate( "europeanDecimal:-3.2,6.2",   2.2 ), "Verified:       2.2" );
ok(  $rules->validate( "europeanDecimal:-3.2,6.2",   3.2 ), "Verified:       3.2" );
ok( !$rules->validate( "europeanDecimal:-3.2,6.2",  30.2 ), "Not verified:  30.2" );

diag 'europeanDecimal:2.2';
ok( !$rules->validate( "europeanDecimal:2.2", 'hi'  ), "Not verified:  'hi'" );
ok( !$rules->validate( "europeanDecimal:2.2", -10.2 ), "Not verified: -10.2" );
ok( !$rules->validate( "europeanDecimal:2.2",   0.2 ), "Not verified:   0.2" );
ok( !$rules->validate( "europeanDecimal:2.2",   1.2 ), "Not verified:   1.2" );
ok(  $rules->validate( "europeanDecimal:2.2",   2.2 ), "Verified:       2.2" );
ok(  $rules->validate( "europeanDecimal:2.2",   3.2 ), "Verified:       3.2" );
ok(  $rules->validate( "europeanDecimal:2.2",  30.2 ), "Verified:      30.2" );

diag 'europeanDecimal:,2';
ok( !$rules->validate( "europeanDecimal:,2",    'hi' ), "Not verified:    'hi'" );
ok(  $rules->validate( "europeanDecimal:,2", '-10,2' ), "Verified:     '-10,2'" );
ok(  $rules->validate( "europeanDecimal:,2",   '0,2' ), "Verified:       '0,2'" );
ok(  $rules->validate( "europeanDecimal:,2",   '1,2' ), "Verified:       '1,2'" );
ok( !$rules->validate( "europeanDecimal:,2",   '2,2' ), "Not verified:   '2,2'" );
ok( !$rules->validate( "europeanDecimal:,2",   '3,2' ), "Not verified:   '3,2'" );
ok( !$rules->validate( "europeanDecimal:,2",  '30,2' ), "Not verified:  '30,2'" );

diag 'europeanDecimal:-3.2,6.2';
ok( !$rules->validate( "europeanDecimal:-3.2,6.2",    'hi' ), "Not verified:    'hi'" );
ok( !$rules->validate( "europeanDecimal:-3.2,6.2", '-10,2' ), "Not verified: '-10,2'" );
ok(  $rules->validate( "europeanDecimal:-3.2,6.2",   '0,2' ), "Verified:       '0,2'" );
ok(  $rules->validate( "europeanDecimal:-3.2,6.2",   '1,2' ), "Verified:       '1,2'" );
ok(  $rules->validate( "europeanDecimal:-3.2,6.2",   '2,2' ), "Verified:       '2,2'" );
ok(  $rules->validate( "europeanDecimal:-3.2,6.2",   '3,2' ), "Verified:       '3,2'" );
ok( !$rules->validate( "europeanDecimal:-3.2,6.2",  '30,2' ), "Not verified:  '30,2'" );

diag 'europeanDecimal:2.2';
ok( !$rules->validate( "europeanDecimal:2.2",    'hi' ), "Not verified:    'hi'" );
ok( !$rules->validate( "europeanDecimal:2.2", '-10,2' ), "Not verified: '-10,2'" );
ok( !$rules->validate( "europeanDecimal:2.2",   '0,2' ), "Not verified:   '0,2'" );
ok( !$rules->validate( "europeanDecimal:2.2",   '1,2' ), "Not verified:   '1,2'" );
ok(  $rules->validate( "europeanDecimal:2.2",   '2,2' ), "Verified:       '2,2'" );
ok(  $rules->validate( "europeanDecimal:2.2",   '3,2' ), "Verified:       '3,2'" );
ok(  $rules->validate( "europeanDecimal:2.2",  '30,2' ), "Verified:      '30,2'" );

diag 'email';
ok(  $rules->validate( "email", 'haakonsk\@gmail.com' ), "Verified:      'haakonsk\@gmail.com'" );
ok( !$rules->validate( "email", 'haakonsk土mail.com'  ), "Not verified:  'haakonsk土mail.com'"  );

diag 'email:notRequired';
ok(  $rules->validate( "email:notRequired", ''                             ), "Verified:      ''"                             );
ok( !$rules->validate( "email:notRequired", 'A'                            ), "Not verified:  'A'"                            );
ok(  $rules->validate( "email:notRequired", 'haakonsk\@redpill-linpro.com' ), "Verified:      'haakonsk\@redpill-linpro.com'" );

diag 'hostname';
ok(  $rules->validate( "hostname", 'www.vg.no' ), "Verified:      'www.vg.no'" );
ok( !$rules->validate( "hostname", 'www己g孓o' ), "Not verified:  'www己g孓o'" );

diag 'hostname:notRequired';
ok(  $rules->validate( "hostname:notRequired", ''  ), "Verified: ''"  );
ok(  $rules->validate( "hostname:notRequired", 'A' ), "Verified: 'A'" );

diag 'url';
ok(  $rules->validate( "url", 'http://www.vg.no' ), "Verified:     'http://www.vg.no'" );
ok( !$rules->validate( "url", 'http://www己g孓o' ), "Not verified: 'http://www己g孓o'" );

diag 'url:notRequired';
ok(  $rules->validate( "url:notRequired", ''  ), "Verified:     ''"  );
ok( !$rules->validate( "url:notRequired", 'A' ), "Not verified: 'A'" );

diag 'regex:/^\d+\$/';
ok(  $rules->validate( 'regex:/^\d+$/', '234'  ), "Verified:     '234'"  );
ok( !$rules->validate( 'regex:/^\d+$/', 'a234' ), "Not verified: 'a234'" );

diag 'required';
ok( !$rules->validate( "required", ''   ), "Not verified: ''"  );
ok(  $rules->validate( "required", '0'  ), "Verified:     '0'" );
ok(  $rules->validate( "required",  0   ), "Verified:      0"  );
ok(  $rules->validate( "required", 'Hi' ), "Verified:    'Hi'" );

diag 'length:,2';
ok(  $rules->validate( "length:,2", 'hi'  ), "Verified:     'hi'"  );
ok(  $rules->validate( "length:,2", 'h'   ), "Verified:     'h'"   );
ok( !$rules->validate( "length:,2", 'hih' ), "Not verified: 'hih'" );

diag 'length:3,6';
ok( !$rules->validate( "length:3,6", 'hi'      ), "Not verified: 'hi'"      );
ok(  $rules->validate( "length:3,6", 'hih'     ), "Verified:     'hih'"     );
ok(  $rules->validate( "length:3,6", 'hihihi'  ), "Verified:     'hihihi'"  );
ok( !$rules->validate( "length:3,6", 'hihihih' ), "Not verified: 'hihihih'" );

diag 'length:2';
ok( !$rules->validate( "length:2", 'h'   ), "Not verified: 'h'"   );
ok(  $rules->validate( "length:2", 'hi'  ), "Verified:     'hi'"  );
ok(  $rules->validate( "length:2", 'hih' ), "Verified:     'hih'" );

diag 'date:yyyy-MM-dd';
ok(  $rules->validate('date:yyyy-MM-dd', '2009-12-31'), "Verified:     '2009-12-31'" );
ok( !$rules->validate('date:yyyy-MM-dd', '2009-12-32'), "Not verified: '2009-12-32'" );
ok( !$rules->validate('date:yyyy-MM-dd', '2009.12.31'), "Not verified: '2009.12.31'" );

diag "No test for repeat\n";
