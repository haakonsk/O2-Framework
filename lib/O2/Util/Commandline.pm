package O2::Util::Commandline;

use strict;

use O2 qw($context);

#---------------------------------------------------------------------
sub new {
  my ($pkg, %params) = @_;
  return bless \%params, $pkg;
}
#---------------------------------------------------------------------
sub heading {
  my ($obj, @params) = @_;
  $obj->divider();
  $obj->say(@params);
  $obj->divider();
  $obj->blank();
}
#---------------------------------------------------------------------
sub blank {
  my ($obj) = @_;
  print "\n";
}
#---------------------------------------------------------------------
sub cls {
  my ($obj) = @_;
  print "\033[2J";
  print "\033[H";
}
#---------------------------------------------------------------------
sub divider {
  my ($obj) = @_;
  $obj->say( '-' x 80);
}
#---------------------------------------------------------------------
sub say {
  my ($obj, @params) = @_;
  print join ('', @params),"\n";
}
#---------------------------------------------------------------------
sub ask {
  my ($obj, $question, $default) = @_;
  my $answer = '';
  while (!length $answer) {
    print ($question, $default ? " (default: $default)" : '', ': ');
    $answer = <STDIN>;
    chomp $answer;
    $answer = $default if length $answer <= 0 && defined $default;
  }
  return $answer;
}
#---------------------------------------------------------------------
sub writeFileWithConfirm {
  my ($obj, $path, $content) = @_;
  my $wantsToWrite = !-e $path || $obj->confirm("File '$path' exists. Do you want to overwrite?", 'no');
  $context->getSingleton('O2::File')->writeFile($path, $content) if $wantsToWrite;
  return $wantsToWrite;
}
#---------------------------------------------------------------------
sub confirm {
  my ($obj, $question, $default) = @_;
  my $yes = length $default && $default =~ m{ \A y }xmsi  ?  'Y'  :  'y';
  my $no  = length $default && $default !~ m{ \A y }xmsi  ?  'N'  :  'n';
  
  my $answer = '';
  while ($answer !~ m{ \A [yn] }xmsi) {
    print ("$question ($yes/$no): ");
    $answer = <STDIN>;
    chomp $answer;
    $answer = $default if length $answer <= 0;
  }
  return $answer =~ m{ \A y }xmsi;
}
#---------------------------------------------------------------------
1;
