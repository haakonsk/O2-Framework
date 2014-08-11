package O2::Model::Target;

# Helper methods for target classes. Mostly for user interaction.

use strict;

use O2 qw($context);

#-----------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  my $file = $context->getSingleton('O2::File');
  return bless {
    file => $file,
    %init,
  }, $pkg;
}
#-----------------------------------------------------------------------------
sub writeFile {
  my ($obj, $path, $content) = @_;
  $obj->{file}->writeFile($path, $content);
}
#-----------------------------------------------------------------------------
# Create all missing directories in a path. Expects last part to be filename. Confirm each directory.
sub makePath {
  my ($obj, $path) = @_;
  my @dirs = split /\//, $path;
  pop @dirs; # filename
  my $build = '';
  foreach my $dir (@dirs) {
    $build .= "$dir/";
    if ( !-e $build ) {
      if ( !$obj->getArg('questions') || ($obj->ask("Create directory $build (y/N)? ", 'n') eq 'y') ) {
        mkdir $build or  die "Error mkdir $build: $!";
      }
    }
  }
}
#-----------------------------------------------------------------------------
# Returns class name with :: substituted with $separator (for O2/Obj/Object and O2-Obj-Object cases)
sub pathifyClassName {
  my ($obj, $className, $separator) = @_;
  return join $separator, split /::/, $className;
}
#-----------------------------------------------------------------------------
sub setArgs {
  my ($obj, %args) = @_;
  
  # Remove leading hyphens in argument keys
  while (my ($key, $value) = each %args) {
    my $newKey = $key;
    $newKey    =~ s{ \A [-]+ }{}xms;
    $args{$newKey} = delete $args{$key} if $key ne $newKey;
  }
  
  %args = ( # Default messages and questions
    messages    => 1,
    questions   => 1,
    currentRoot => $context->getEnv('O2CUSTOMERROOT'),
    %args,
  );
  $obj->{args} = \%args;
}
#-----------------------------------------------------------------------------
sub setArg {
  my ($obj, $name, $value) = @_;
  $obj->{args}->{$name} = $value;
}
#-----------------------------------------------------------------------------
sub getArg {
  my ($obj, $argName) = @_;
  return $obj->{args}->{$argName};
}
#-----------------------------------------------------------------------------
sub say {
  my ($obj, $message) = @_;
  print $message,"\n" if $obj->getArg('messages');
}
#-----------------------------------------------------------------------------
sub ask {
  my ($obj, $question, $defaultAnswer) = @_;
  return $defaultAnswer unless $obj->getArg('questions');
  print "$question ";
  my $answer = <STDIN>;
  chomp $answer;
  return $answer ? $answer : $defaultAnswer;
}
#-----------------------------------------------------------------------------
1;
