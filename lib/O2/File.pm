package O2::File;

use strict;

use constant DEBUG => 0;

use O2 qw($context);
use Fcntl qw(:flock);

#--------------------------------------------------------------------------------------------
sub new {
  my ($package, %params) = @_;
  my $obj = bless \%params, $package;
  $obj->{transactionLevel}      = 0;
  $obj->{waitingFileOperations} = [];
  umask oct 2;
  return $obj;
}
#--------------------------------------------------------------------------------------------
sub openFile {
  my ($obj, $file) = @_;
  local *FH;
  my $realPath = $obj->resolvePath($file);
  open FH, $realPath or die "Could not read file '$file' (resolved: $realPath): $!";
  binmode FH;
  return *FH;
}
#--------------------------------------------------------------------------------------------
sub closeFile {
  my $obj = shift;
  local *FH = shift;
  close FH;
  return 1;
}
#--------------------------------------------------------------------------------------------
{
  my $insideGetFileRef = 0;
  
  sub getFileRef {
    my ($obj, $file, %params) = @_;
    my $data;
    local *FH;
    my $realPath = $obj->resolvePath($file);
    open FH, $realPath or die "Could not read file '$file' (resolved: $realPath): $!";
    flock FH, LOCK_SH; # Shared lock
    binmode FH;
    {
      local $/ = undef;
      $data = <FH>;
    }
    flock FH, LOCK_UN; # Release lock
    close FH;
    
    my ($fileEncoding) = $data =~ m{ \A [^\n]* fileEncoding= ([^\s]+) [^\n]* $ }xms;
    if ($fileEncoding && !$params{keepFileEncodingLine}) {
      $data =~ s{ \A [^\n]* fileEncoding= [^\s]+ [^\n]* \n \s* }{}xms;
    }
    
    # We must avoid infinite recursive calls to getFileRef() and config->get():
    if (!$insideGetFileRef) {
      $insideGetFileRef = 1;
      $fileEncoding   ||= $context->getConfig()->get('o2.defaultFileEncoding');
      $insideGetFileRef = 0;
    }
    
    if ($fileEncoding) {
      require Encode;
      $data = Encode::decode($fileEncoding, $data);
    }
    
    return \$data;
  }
}
#--------------------------------------------------------------------------------------------
sub getFile {
  my ($obj, $file, %params) = @_;
  my $content = ${ $obj->getFileRef($file, %params) };
  return $content unless wantarray;
  return map { "$_\n" } split /\n/, $content;
}
#--------------------------------------------------------------------------------------------
# converts "o2:..." path to real path. Search for file below siteRoot, customerRoot and o2root
sub resolvePath {
  my ($obj, $path) = @_;
  die "Could not resolve path $path" if $path !~ m{ \A o2: (?://)? (.*) }xms && !-f $path;
  
  return $path if $path !~ m{ \A o2: (?://)? (.*) }xms;
  my $relativePath = $1;
  
  foreach my $prefix ($context->getRootPaths()) {
    return "$prefix/$relativePath" if -e "$prefix/$relativePath";
  }
  die "Could not resolve path: $path";
}
#--------------------------------------------------------------------------------------------
sub resolveExistingPaths {
  my ($obj, $path) = @_;
  return $path unless $path =~ m|^o2:(?://)?(.*)|;
  my $relativePath = $1;
  
  my @paths;
  foreach my $prefix ($context->getRootPaths()) {
    push @paths, "$prefix/$relativePath" if -e "$prefix/$relativePath";
  }
  return @paths;
}
#--------------------------------------------------------------------------------------------
sub writeFile {
  my ($obj, $file, @content) = @_;
  $obj->_writeFile($file, undef, @content);
}
#--------------------------------------------------------------------------------------------
sub writeEncodedFile {
  my ($obj, $file, $encoding, @content) = @_;
  die "Missing valid encoding, got |$encoding|" if !$encoding  ||  ( $encoding ne 'utf-8' && $encoding !~ m/ \A iso - \d+ - \d \z /xms );
  
  $obj->_writeFile($file, $encoding, @content);
}
#--------------------------------------------------------------------------------------------
# Adds the fileEncoding=<fileEncoding> line if encoding is given. Keeps the line even if encoding is undef. Does not add the line if encoding is undef.
sub writeFileWithFileEncoding {
  my ($obj, $filePath, $encoding, @content) = @_;
  return $obj->writeFile($filePath, @content) if !$encoding && !-f $filePath;

  my $contentString = $obj->_getContentString(@content);
  if ($encoding) {
    $contentString = "# fileEncoding=$encoding\n$contentString";
  }
  elsif (-f $filePath) {
    # See if the original file has specified a fileEncoding, and use that encoding if it has
    open my $fh, '<', $filePath or die "Could not read file '$filePath' (resolved: $filePath): $!";
    flock   $fh, LOCK_SH; # Shared lock
    binmode $fh;
    my $firstLine = <$fh>;
    flock   $fh, LOCK_UN; # Release lock
    close   $fh;
    ($encoding) = $firstLine =~ m{ \A [^\n]* fileEncoding= ([^\s]+) [^\n]* $ }xms;
    $contentString = "# fileEncoding=$encoding\n$contentString" if $encoding;
  }

  $obj->_writeFile($filePath, $encoding, $contentString);
}
#--------------------------------------------------------------------------------------------
sub _writeFile {
  my ($obj, $file, $encoding, @content) = @_;
  my $ignoreTransaction = $obj->_extractIgnoreTransactionParam(\@content);
  if ($obj->{transactionLevel} > 0 && !$ignoreTransaction) {
    debug "Delaying _writeFile";
    push @{ $obj->{waitingFileOperations} }, {
      methodName => '_writeFile',
      params     => [$file, $encoding, @content],
    };
    return;
  }

  $obj->_validateFilePath($file);
  
  require Encode;
  $file = Encode::encode( $obj->getFileNameEncoding(), $file );
  if (!-e $file) { # Opening in '+<' mode doesn't create the file if it doesn't exist. How about locking in this case? Probably nothing to worry about..
    open my $fh, '>', $file or die "writeFile: Could not create file '$file': $!";
    close $fh;
  }

  my $fh = $obj->_openForWritingAndLock($file, $encoding);
  print {$fh} $obj->_getContentString(@content);
  flock $fh, LOCK_UN; # Release lock
  close $fh;
}
#--------------------------------------------------------------------------------------------
# Let's not allow same name with different casing
sub _validateFilePath {
  my ($obj, $filePath) = @_;
  my ($dir) = $filePath =~ m{ (.*) / }xms;
  $filePath = "./$filePath" unless $dir;
  $dir ||= '.';
  my @files = map { "$dir/$_" } $obj->scanDir($dir);
  my $similarFilePath;
  foreach my $_filePath (@files) {
    return 1 if $_filePath eq $filePath;
    $similarFilePath ||= $_filePath if lc ($_filePath) eq lc ($filePath);
  }
  die "Can't create new file $filePath: File with same name but different casing exists ($similarFilePath)." if $similarFilePath;
  return 1;
}
#--------------------------------------------------------------------------------------------
sub _openForWritingAndLock {
  my ($obj, $filePath, $encoding) = @_;
  $encoding = 'utf8' if $encoding && $encoding eq 'utf-8';

  my $mode = '+<'; # Opening in '>' mode would have deleted the file before we could lock it
  $mode   .= ":encoding($encoding)" if $encoding;

  open my $fh, $mode, $filePath or die "writeFile: Could not write to file '$filePath': $!";

  flock    $fh, LOCK_EX; # Sets an exclusive lock
  seek     $fh, 0, 0;    # Go to beginning of file
  truncate $fh, 0;       # Delete content

  binmode $fh, ":$encoding" if $encoding;
  binmode $fh           unless $encoding;

  return $fh;
}
#--------------------------------------------------------------------------------------------
sub _getContentString {
  my ($obj, @content) = @_;
  my $contentString;
  if (@content == 1) {
    my $content = $content[0];
    die "Could not figure out reference-type: " . ref ($content) if ref ($content)  &&  ref ($content) ne 'ARRAY'  &&  ref ($content) ne 'SCALAR';
    $contentString
      = ref ($content) eq 'ARRAY'  ? join ( '', @{$content} )
      : ref ($content) eq 'SCALAR' ?            ${$content}
      :                                           $content
      ;
  }
  else {
    $contentString = join '', @content;
  }
  return $contentString;
}
#--------------------------------------------------------------------------------------------
sub _extractIgnoreTransactionParam {
  my ($obj, $params) = @_;
  my $ignoreTransaction;
  for my $i (0 .. @{$params}-2) {
    my $param = $params->[$i];
    if ($param eq 'ignoreTransaction') {
      $ignoreTransaction = $params->[$i+1];
      splice @{$params}, $i, 2;
      last;
    }
  }
  return $ignoreTransaction;
}
#--------------------------------------------------------------------------------------------
sub appendFile {
  my ($obj, $file, @content) = @_;
  my $ignoreTransaction = $obj->_extractIgnoreTransactionParam(\@content);
  if ($obj->{transactionLevel} > 0 && !$ignoreTransaction) {
    debug "Delaying appendFile";
    push @{ $obj->{waitingFileOperations} }, {
      methodName => 'appendFile',
      params     => [$file, @content],
    };
    return;
  }
  
  open my $fh, '>>', $file or die "Could not append to file '$file': $!";
  flock   $fh, LOCK_EX; # Sets an exclusive lock
  seek    $fh, 0, 2;    # Go to end of file. If we don't do this, someone may have appended after we opened the file (while we were waiting for the lock), in which case we'd be writing to the middle of the file instead of the end.
  binmode $fh;
  if (@content == 1) {
    my $content = $content[0];
    if    ( (ref $content) =~ m{ \A ARRAY  }xms ) { print {$fh} @{$content};                                    }
    elsif ( (ref $content) =~ m{ \A SCALAR }xms ) { print {$fh} ${$content};                                    }
    elsif (  ref $content                       ) { die "Could not figure out reference-type for file '$file'"; }
    else                                          { print {$fh}   $content;                                     }
  }
  else {
    print {$fh} @content;
  }
  flock $fh, LOCK_UN; # Release lock
  close $fh;
}
#--------------------------------------------------------------------------------------------
sub mkPath {
  my ($obj, $path, $mode) = @_;
  $mode ||= oct 775;
  
  if ($obj->{transactionLevel} > 0) {
    debug "Delaying mkPath";
    push @{ $obj->{waitingFileOperations} }, {
      methodName => 'mkPath',
      params     => [$path, $mode],
    };
    return;
  }
  
  my $pathDelim = '/'; #default *nix
  my $isWindows = 0;
  
  my $totpath;
  my $split = '\\' . $pathDelim;
  my @paths = split /$split/, $path;
  
  # Windows hack: The first 3 parts of the path make up the machine name, ex: \\s-name83. The first 4 parts is a directory that we may try to create.
  # So we merge the first 4 elements of @paths into one element.
  if ($isWindows   &&   $path =~ m{ \A \\\\ }xms   &&   scalar(@paths) >= 4) {
    my $firstDir = shift(@paths) . $pathDelim . shift(@paths) . $pathDelim . shift(@paths) . $pathDelim . shift(@paths);
    unshift @paths, $firstDir;
  }
  
  foreach $path (@paths) {
    $totpath .= "$path$pathDelim";
    if (!-d $totpath) {
      mkdir $totpath        or die "Could not make path '$totpath': $!";
      chmod $mode, $totpath or die "Could not chmod $mode on $totpath: $!";
      die "Could not make path '$path'" unless -d $totpath;
    } 
  }
  return 1;
}
#--------------------------------------------------------------------------------------------
# $dir allowed to start with "o2:", in that case params{scanAllO2Dirs} is used to determine if we should look
# in the first matching directory, or all matching directories
sub scanDir {
  my ($obj, $dir, $pattern, %params) = @_;
  return $obj->_scanDir( $dir,                    $pattern, %params                     )     if $dir !~ m{ \A o2: }xms;
  return $obj->_scanDir( $obj->resolvePath($dir), $pattern, %params, absolutePaths => 1 ) unless $params{scanAllO2Dirs};
  
  my @files;
  $dir =~ s{ o2: /* }{}xms;
  foreach my $rootPath ($context->getRootPaths()) {
    my $fullDir = "$rootPath/$dir";
    push @files, $obj->_scanDir($fullDir, $pattern, absolutePaths => 1) if -d $fullDir;
  }
  return @files;
}
#--------------------------------------------------------------------------------------------
sub _scanDir {
  my ($obj, $dir, $pattern, %params) = @_;
  my ($file, @files);
  opendir DIR, $dir or die "Could not open dir '$dir': $!";
  if ($pattern) {
    $pattern =~ s/\./\\./g;
    $pattern =~ s/\?/./g;
    $pattern =~ s/\*/.*?/g;
    @files = grep { /$pattern/ } readdir DIR;
  }
  else {
    @files = readdir DIR;
  }
  closedir DIR;
  
  require Encode;
  @files = map  { Encode::decode( $obj->getFileNameEncoding(), $_ ) } @files;
  @files = map  { "$dir/$_"                                         } @files if $params{absolutePaths};
  
  return @files;
}
#--------------------------------------------------------------------------------------------
# Calls scanDir for every directory
# Returns an array of files, with paths relative to $dir
sub scanDirRecursive {
  my ($obj, $dir, $pattern, %params) = @_;
  return $obj->_scanDirRecursive( $dir,                    $pattern, '', %params                     )     if $dir !~ m{ \A o2: }xms;
  return $obj->_scanDirRecursive( $obj->resolvePath($dir), $pattern, '', %params, absolutePaths => 1 ) unless $params{scanAllO2Dirs};
  
  my @files;
  $dir =~ s{ o2: /* }{}xms;
  foreach my $rootPath ($context->getRootPaths()) {
    my $fullDir = "$rootPath/$dir";
    push @files, $obj->_scanDirRecursive($fullDir, $pattern, '', absolutePaths => 1) if -d $fullDir;
  }
  return @files;
}
#--------------------------------------------------------------------------------------------
sub _scanDirRecursive {
  my ($obj, $currentDir, $pattern, $prependPath, %params) = @_;
  $prependPath ||= '';
  my @files = map {
        $params{absolutePaths} ? "$currentDir/$_"
      : $prependPath           ? "$prependPath/$_"
      :                          $_
    } $obj->scanDir($currentDir, $pattern, %params, absolutePaths => 0);
  my @dirs = grep { -d "$currentDir/$_" && $_ !~ m{ \A [.] }xms } $obj->scanDir($currentDir, undef, %params, absolutePaths => 0);
  foreach my $dir (@dirs) {
    my $currentPrependPath = $prependPath . ($prependPath ? '/' : '') . "$dir";
    push @files, $obj->_scanDirRecursive("$currentDir/$dir", $pattern, $currentPrependPath, %params);
  }
  return @files;
}
#--------------------------------------------------------------------------------------------
sub _rmtree {
  my ($dir) = @_;
  opendir DIR, $dir or die "Could not open dir '$dir': $!";
  my @arr = readdir DIR;
  closedir DIR;
  
  foreach my $line (@arr) {
    next if $line =~ m!^\.\.?$!;
    if (-d "$dir/$line" && !rmdir "$dir/$line") {
      &_rmtree("$dir/$line");
      rmdir "$dir/$line";
    }
    unlink "$dir/$line" if -f "$dir/$line";
  }
}
#--------------------------------------------------------------------------------------------
sub rmFile {
  my ($obj, $file, $mode) = @_;
  if ($obj->{transactionLevel} > 0) {
    debug "Delaying rmFile";
    push @{ $obj->{waitingFileOperations} }, {
      methodName => 'rmFile',
      params     => [$file, $mode],
    };
    return;
  }
  
  my ($path, $expr, @array);
  if ($mode && $mode eq '-rf') {
    &_rmtree($file);
    rmdir $file;
  }
  elsif (-f "$file") {
    unlink $file or die "Could not delete file '$file': $!";
  }
  elsif ($file =~ m/\*.\w/g) {
    $file =~ m!(.*)\/([^\/]+)!;
    my ($path, $expr) = ($1, $2);
    
    my @files = $obj->scanDir($path, $expr);
    foreach my $line (@files) {
      next if $line =~ m!^\.\.?$!;
      unlink "$path/$line" if -f "$path/$line";
    }
  }
  elsif (-d "$file") {
    rmdir ($file) or die "Could not delete directory '$file': $!";
  }
} 
#--------------------------------------------------------------------------------------------
sub rmEmptyDirs {
  my ($obj, $path) = @_;
  if ($obj->{transactionLevel} > 0) {
    debug "Delaying rmEmptyDirs";
    push @{ $obj->{waitingFileOperations} }, {
      methodName => 'rmEmptyDirs',
      params     => [$path],
    };
    return;
  }
  
  $path =~ s{ / [^/]+ \z }{}xms unless -d $path;
  while ($path) {
    eval {
      $obj->rmFile($path);
    };
    return if $@;
    $path =~ s{ / [^/]+ \z }{}xms;
  }
}
#--------------------------------------------------------------------------------------------
sub getDirData {
  my ($obj, $dir, $pattern) = @_;
  die "$dir is not a directory" unless -d $dir;
  
  my %dirdata;
  foreach ($obj->scanDir($dir, $pattern)) {
    next if $_ =~ m/^\.+$/;
    $dirdata{$_} = $obj->getFileSize("$dir/$_");
  }
  return \%dirdata;
} 
#--------------------------------------------------------------------------------------------
sub getFileSize {
  my ($obj, $file, $measure, $dec) = @_;
  my $retval = -1;
  if (-e $file) {
    $retval = -s $file;
    if ($measure) {
      my %m = (
        KB => 1024,
        MB => 1024000,
      );
      return sprintf ($dec || "%.2f"), $retval/$m{$measure};
    }
  }
  return $retval;
}
#--------------------------------------------------------------------------------------------
sub cpFile {                                              # This MIGHT need some revision
  my ($obj, $origFile, $newFile, $mode, $chmod) = @_;
  if ($obj->{transactionLevel} > 0) {
    debug "Delaying cpFile";
    push @{ $obj->{waitingFileOperations} }, {
      methodName => 'cpFile',
      params     => [$origFile, $newFile, $mode, $chmod],
    };
    return;
  }
  
  my ($path, $expr);
  
  # Copy a structure of files
  if ($mode && $mode eq '-R') {
    $origFile =~ m!(.*)\/([^\/]+)!;
    ($path, $expr) = ($1, $2);
    
    # If to-dir is a valid dir
    if (-d $newFile) {
      # If files are many
      if ($origFile =~ m!\*!) {
        my @array = $obj->scanDir($path, $expr);
        foreach my $line (@array) {
          next if $line =~ m!^\.\.?$!;
          
          if (-d "$path/$line" && -d "$newFile$line") {
            &_shiftDir("$path/$line", "$newFile$line", '', $chmod);
          }
          elsif (-f "$path/$line") { # If it is a file
            &writeFile($newFile . $line, 's ');                      # <--- What is this ?????????????????????????????????????
            chmod $chmod || oct 755, $newFile . $line;
            &_doCopyFile("$path/$line", $newFile . $line, $chmod);
          }
        }
      } 
      # Error - If only one file
      else {
        die "Error in usage of this proc. Use * to indicate all files.";
      }
    }
    # If to-dir isn't a valid dir
    else {
      die "Error opening dir $newFile";
    }
  }
  
  # Copy groups of files to a new directory
  elsif ($origFile =~ m!\*!) {
    $origFile =~ m!(.*)\/([^\/]+)!;
    ($path, $expr) = ($1, $2);
    my @array = $obj->scanDir($path,$expr);
    foreach my $line (@array) {
      next if $line =~ m!^\.\.?$! || -d "$path/$line";
      &_doCopyFile("$path/$line", $newFile . $line, $chmod);
    }
  }
  
  # Copy a single file
  else {
    &_doCopyFile($origFile, $newFile, $chmod);
  }
}
#--------------------------------------------------------------------------------------------
sub _shiftDir {
  my ($dir, $dirto, $mode, $chmod) = @_;
  
  opendir DIR, $dir or die "Error opening dir $dir";
  my @array = readdir DIR;
  closedir DIR;
  
  foreach my $line (@array) {
    next if $line =~ m!^\.\.?$!;
    if ($mode && !-d "$dirto/line" && -d "$dir/$line") {
      mkdir "$dirto/$line", oct 775;
      chmod $chmod || oct 775, "$dirto/$line";
    }
    if (-d "$dir/$line") {
      chmod $chmod || oct 775, "$dirto/$line";
      &_shiftDir("$dir/$line", "$dirto/$line", '', $chmod);
    }
    elsif (-f "$dir/$line") {
      &writeFile("$dirto/$line", "s");
      chmod $chmod || oct 775, "$dirto/$line";
      &_doCopyFile("$dir/$line", "$dirto/$line");
    }
  }
}
#--------------------------------------------------------------------------------------------
sub move {
  my ($obj, $fromFile, $toFile) = @_;
  if ($obj->{transactionLevel} > 0) {
    debug "Delaying move";
    push @{ $obj->{waitingFileOperations} }, {
      methodName => 'move',
      params     => [$fromFile, $toFile],
    };
    return;
  }
  
  require File::Copy;
  my $success = File::Copy::move($fromFile, $toFile);
  die "Couldn't move $fromFile to $toFile: $!" unless $success;
}
#--------------------------------------------------------------------------------------------
sub _doCopyFile {
  my ($inFile, $outFile, $chmod) = @_;
  my ($written, $len, $offset, $buf);
  
  open IN, "< $inFile" or die "$!: $inFile";
  binmode IN;
  open OUT, "> $outFile" or die "$!: $outFile";
  binmode OUT;
  
  my $blksize = (stat IN)[11] || 16384;
  while ($len = sysread IN, $buf, $blksize) {
    if (!defined $len) {
      next if $! =~ /^Interrupted/;
      die $!;
    }
    $offset = 0;
    while ($len) {
      defined ($written = syswrite OUT, $buf, $len, $offset) or die $!;
      $len    -= $written;
      $offset += $written;
    }
  }
  
  chmod $chmod || oct 775, $outFile;
  
  close IN;
  close OUT;
}
#--------------------------------------------------------------------------------------------
sub _FileWalker {
  my ($path, $expr, $newFile) = @_;
  my $line;
  
  opendir DIR, $path or die "Error opening dir $path: $!";
  my @array = grep { $expr } readdir DIR;
  closedir DIR;
  
  foreach my $line (@array) {
    next if $line =~ m!^\.\.?$!;
    next if -d "$path/$line";
    &_doCopyFile("$path/$line", $newFile . $line);
  }
}
#--------------------------------------------------------------------------------------------
# returns path based on id.
# Hash arguments:
#   id           - the numeric id (only required agrument)
#   levels - hom many directories to use when you distribute your file (default 5)
#   rootDir      - path prefix
#   fileName     - filename to append
#   mkDirs       - create all missing directories (after rootDir)
#   fileMode     - chmod mode for directories created when the mkDirs flag is active
# Example: distribute(id=>127, rootDir=>'/tmp', fileName=>'object.xml') will return "/tmp/00/00/01/27/object.xml"
sub distributePath {
  my ($obj, %args) = @_;
  $args{charsPerLevel} = 2 if !defined $args{charsPerLevel} || !($args{charsPerLevel} > 0);
  $args{levels}        = 5 if !defined $args{levels}        || !($args{levels}        > 0);
  $args{fileName}    ||= '';
  $args{fileMode}    ||= oct 775;
  $args{rootDir}     ||= '';
  die 'Missing id argument' unless exists $args{id};
  
  my $addChars = ($args{levels} * $args{charsPerLevel}) - length $args{id};
  my $paddedId = $args{id};
  $paddedId    = ('0' x $addChars) . $args{id} if $addChars > 0;
  
  my @dirs = $paddedId =~ m|(.{$args{charsPerLevel}})|g;
  my $path = $args{rootDir};
  if ($args{mkDirs} && !-d $path) {
    $obj->mkPath( $path, $args{fileMode} ) or die "Could not create directory '$path': $!.";
  }
  
  foreach my $dir ( @dirs[0 .. $args{levels}-1] ) {
    $path .= "/$dir";
    if ( $args{mkDirs} && $args{rootDir} ) {
      if (!-d $path) {
        if (!mkdir ($path) && !-d $path) {
          my $errorMsg = "mkdir failed on $path";
          $errorMsg   .= " ($!)" if $!;
          die $errorMsg;
        }
        if (!chmod $args{fileMode}, $path) {
          my $errorMsg = "chmod failed on $path";
          $errorMsg   .= " ($!)" if $!;
          die $errorMsg;
        }
      }
    }
  }
  return $args{fileName} ? "$path/$args{fileName}" : $path;
}
#--------------------------------------------------------------------------------------------
# recursive look for files matching $match in $rootDir. Note that $match matches on full path
# XXX break if recursion goes wild - softlinks may cause havoc
sub find {
  my ($obj, $rootDir, $match) = @_;
  my @files;
  opendir my $dir, $rootDir or return;
  while (my $file = readdir $dir) {
    next if $file eq '.' || $file eq '..';
    
    my $path = "$rootDir/$file";
    push @files, $obj->find($path, $match) if -d $path;
    push @files, $path                     if    $path =~ m|$match|i;
  }
  closedir $dir;
  return @files;
}
#--------------------------------------------------------------------------------------------
sub getFileNameEncoding {
  my ($obj) = @_;
  return $obj->{fileNameEncoding} if $obj->{fileNameEncoding};
  
  eval {
    $obj->{fileNameEncoding} = $context->getConfig()->get('o2.fileNameEncoding');
  };
  return $obj->{fileNameEncoding} ||= 'iso-8859-1';
}
#--------------------------------------------------------------------------------------------
sub startTransaction {
  my ($obj) = @_;
  $obj->{transactionLevel}++;
}
#--------------------------------------------------------------------------------------------
sub endTransaction {
  my ($obj) = @_;
  die 'Transaction never started' unless $obj->{transactionLevel};
  
  $obj->{transactionLevel}--;
  return if $obj->{transactionLevel} >= 1;
  
  # Execute all buffered file operations
  while (@{ $obj->{waitingFileOperations} }) {
    my $fileOperation = shift @{ $obj->{waitingFileOperations} };
    my $method = $fileOperation->{methodName};
    debug "Executing $method";
    my @params = @{ $fileOperation->{params} };
    eval {
      $obj->$method(@params);
    };
    warning "Error executing $method in O2::File::endTransaction: $@" if $@;
  }
  
  $obj->{waitingFileOperations} = [];
}
#--------------------------------------------------------------------------------------------
sub rollback {
  my ($obj) = @_;
  die 'rollback: Transaction never started' unless $obj->{transactionLevel};
  
  debug 'rollback';
  $obj->{transactionLevel}      = 0;
  $obj->{waitingFileOperations} = []; # Ignore all buffered file operations
}
#--------------------------------------------------------------------------------------------
sub startIgnoreTransactions {
  my ($obj) = @_;
  $obj->{realTransactionLevel} = delete $obj->{transactionLevel};
}
#--------------------------------------------------------------------------------------------
sub endIgnoreTransactions {
  my ($obj) = @_;
  $obj->{transactionLevel} = delete $obj->{realTransactionLevel};
}
#--------------------------------------------------------------------------------------------
1;
