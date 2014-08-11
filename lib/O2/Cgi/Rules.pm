package O2::Cgi::Rules;

use strict;

use O2 qw($context $cgi);

#--------------------------------------------------------------------------------------------
sub new {
  my ($pkg, %init) = @_;
  return bless {}, $pkg;
}
#--------------------------------------------------------------------------------------------
sub validate {
  my ($obj, $rule, $value) = @_;

  my $param = '';
  if ($rule =~ m{ [:] }xms) {
    ($param) = $rule =~ m{ \A \w+ [:] (.+) \z }xms;
  }

  return $obj->_int($param, $value)             if $rule =~ m{ \A int             }xms;
  return $obj->_float($param, $value)           if $rule =~ m{ \A float           }xms;
  return $obj->_europeanDecimal($param, $value) if $rule =~ m{ \A europeanDecimal }xms;
  return $obj->_email($param, $value)           if $rule =~ m{ \A email           }xms;
  return $obj->_hostname($param, $value)        if $rule =~ m{ \A hostname        }xms;
  return $obj->_url($param, $value)             if $rule =~ m{ \A url             }xms;
  return $obj->_regex($param, $value)           if $rule =~ m{ \A regex           }xms;
  return $obj->_fileExt($param, $value)         if $rule =~ m{ \A fileExt         }xms;
  return $obj->_path($param, $value)            if $rule =~ m{ \A path            }xms;
  return $obj->_required($param, $value)        if $rule =~ m{ \A required        }xms;
  return $obj->_length($param, $value)          if $rule =~ m{ \A length          }xms;
  return $obj->_numChecked($param, $value)      if $rule =~ m{ \A numChecked      }xms;
  return $obj->_javascript($param, $value)      if $rule =~ m{ \A javascript      }xms; # XXX Can we make this work in perl?
  return $obj->_repeat($param, $value)          if $rule =~ m{ \A repeat          }xms;
  return $obj->_date($param, $value)            if $rule =~ m{ \A date            }xms;
}
#--------------------------------------------------------------------------------------------
sub _int {
  my ($obj, $param, $value) = @_;
  return 1 if $param =~ m{ notRequired }xms && length $value == 0;
  my ($min, $max) = split(',', $param);
  return 0 if $value ne int($value);
  return 0 if defined($min) && $min ne '' && $value < $min;
  return 0 if defined($max) && $value > $max;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub _float {
  my ($obj, $param, $value) = @_;
  return 1 if $param =~ m{ notRequired }xms && length $value == 0;
  my ($min, $max) = split(',', $param);
  return 0 if $value ne $value * 1;
  return 0 if defined($min) && $min ne '' && $value < $min;
  return 0 if defined($max) && $value > $max;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub _europeanDecimal {
  my ($obj, $param, $value) = @_;
  return 1 if $param =~ m{ notRequired }xms && length $value == 0;
  $value =~ s{ [,] }{.}xms;
  return $obj->_float($param, $value);
}
#--------------------------------------------------------------------------------------------
sub _email {
  my ($obj, $param, $value) = @_;
  return 1 if $param eq 'notRequired' && length $value == 0;
  return $value =~ m{ \A  [^@]+  [@]  [^\.]+  [.]  [^\.]+  \z }xms;
}
#--------------------------------------------------------------------------------------------
sub _hostname {
  my ($obj, $param, $value) = @_;
  return 1 if $param eq 'notRequired' && length $value == 0;
  return $value =~ m{ \A  [\w\.\-]+  \z }xms;
}
#--------------------------------------------------------------------------------------------
sub _url {
  my ($obj, $param, $value) = @_;
  return 1 if $param eq 'notRequired' && length $value == 0;
  return $value =~ m{ \A  (http|ftp|mailto) [:] [/] [/]  [\%a-zA-z0-9\-\/\_\:\@\.]+  \z }xms;
}
#--------------------------------------------------------------------------------------------
sub _regex {
  my ($obj, $param, $value) = @_;
  my $regex = substr($param, 1, -1);
  return $value =~ m{$regex}ms;
}
#--------------------------------------------------------------------------------------------
# XXX: Not implemented
sub _fileExt {
  my ($obj, $param, $value) = @_;
  return 1;
}
#--------------------------------------------------------------------------------------------
# XXX: Not implemented
sub _path {
  my ($obj, $param, $value) = @_;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub _required {
  my ($obj, $param, $value) = @_;
  return length($value) > 0;
}
#--------------------------------------------------------------------------------------------
sub _length {
  my ($obj, $param, $value) = @_;
  my ($min, $max) = split(',', $param);
  return 0 if defined($min) && $min ne '' && length($value) < $min;
  return 0 if defined($max) && length($value) > $max;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub _numChecked {
  my ($obj, $param, $numChecked) = @_;
  my ($minNumChecked, $maxNumChecked) = split /,/, $param;
  $minNumChecked =           0 unless $minNumChecked;
  $maxNumChecked = 999_999_999 unless $maxNumChecked;
  return if $numChecked < $minNumChecked || $numChecked > $maxNumChecked;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub _repeat {
  my ($obj, $param, $value) = @_;
  my $fieldName  = $param;
  my $otherValue = $cgi->getParam($fieldName);
  return $value eq $otherValue;
}
#--------------------------------------------------------------------------------------------
# XXX Not implemented on the server side
sub _javascript {
  my ($obj, $param, $value) = @_;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub _date {
  my ($obj, $param, $value) = @_;
  return 1 if $param =~ m{ notRequired }xms && length $value == 0;
  $param =~ s{ :notRequired }{}xms;
  my ($format, $date) = ($param, $value);
  my $dateFormatter = $context->getDateFormatter();
  my $epoch;
  eval {
    $epoch = $dateFormatter->dateTime2Epoch($date);
  };
  return 0 if $@;
  return $dateFormatter->dateFormat($epoch, $format) eq $date;
}
#--------------------------------------------------------------------------------------------
1;
