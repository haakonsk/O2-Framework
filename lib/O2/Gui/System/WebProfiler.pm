package O2::Gui::System::WebProfiler;

# Simple report dispatcher to generate HTML reports of Devel::NYTProf generate logfiles

use strict;

use base 'O2::Gui';

use constant DEBUG => 0;
use O2 qw($context $db $cgi);

#--------------------------------------------------------------------------------------------
sub viewReport {
  my ($obj) = @_;
  my $reportFile = $obj->getParam('file');
  die "Could not find a raw nytprof log file matching given report file" unless -f $reportFile;
  
  my $referrer    = $context->getEnv('HTTP_REFERER');
  my $nytprofhtml = $context->getEnv('O2ROOT') . '/bin/tools/nytprofhtml';
  
  my $fileMgr = $context->getSingleton('O2::File');
  my $outDir = $reportFile;
  $outDir    =~ s/o2webprofiler\.(\d+\.\d+)\..+/$1/;
  my $webPath = $1 or die "Didn't find web path from $reportFile";
  debug "webPath: $webPath";
  my $cmd = "$nytprofhtml -f $reportFile -o $outDir";
  debug "outDir: $outDir";
  $fileMgr->mkPath($outDir) unless -d $outDir;
  
  debug "Running $cmd";
  open RUN, "$cmd |" or die "Can't run command $cmd: $!\n";
  while (<RUN>) {
    debug $_;
  }
  close RUN;
  
  my $sqlDataFile = $reportFile;
  $sqlDataFile    =~ s/nytprof$/sqlfile/;
  $obj->_generateSQLTable($sqlDataFile, "$outDir/o2SQL.html") if -e $sqlDataFile;
  die 'Could not generate profile report and error occured....' unless -f "$outDir/index.html";
  
  # Need to open index.html and replace the siteSubtitle to reflect the actual O2 app and not the dispacher
  my $currentUrl = $cgi->getCurrentUrl(includeServer => 1);
  $currentUrl    =~ s{ \A https?:// }{}xms;
  my $fileContent = $fileMgr->getFileRef("$outDir/index.html");
  ${$fileContent} =~ s|\/www[^\s]+\/Dispatch\/[^\s]+\.cgi|$db->fetch("select url from O2_CONSOLE_LOG where message = ? order by id desc limit 1", $currentUrl)|msegi;
  ${$fileContent} =~ s|(\<div\s+class=\"body\_content\"\>)|\<a href=\"\/o2Profiler\/$webPath\/o2SQL.html">SQL Profile</a>$1|; # Add link to SQL profiling report
  $fileMgr->writeFile("$outDir/index.html", $fileContent);
  
  # Create o2Profiler symlink if it doesn't exist:
  my $symlinkPath = $context->getEnv('DOCUMENT_ROOT') . '/o2Profiler';
  symlink $context->getEnv('O2CUSTOMERROOT') . '/var/o2WebProfiler/', $symlinkPath unless -e $symlinkPath;
  
  $obj->_cleanUpOldFiles;
  
  print qq{<script type="text/javascript">top.location.href="/o2Profiler/$webPath";</script>};
  print qq{<br><a href="/o2Profiler/$webPath">Click here to see report, if you are not redirected to the report automatically...</a>};
  
  return 1;
}
#--------------------------------------------------------------------------------------------
sub _generateSQLTable {
  my ($obj, $dataFile, $targetFile) = @_;
  
  my $sqlData = $context->getSingleton('O2::Data')->load($dataFile);
  
  my ($totalRunTime, $totalPids, $worstPid, $worstRun) = (0, 0, 0, 0);
  foreach my $pid (keys %{$sqlData}) {
    my $runTime = $sqlData->{$pid}->{runTime};
    $totalRunTime += $runTime;
    if ($worstRun < $runTime) {
      $worstRun = $runTime;
      $worstPid = $pid;
    }
    $totalPids++;
  }
  
  require O2::Template;
  my $tmpl = O2::Template->newFromFile('o2://var/templates/System/WebProfiler/sqlSummary.html');
  my $html = $tmpl->parse(
    worstPid     => $worstPid,
    totalRunTime => $totalRunTime,
    totalPids    => $totalPids,
    sqlData      => $sqlData,
  );
  $context->getSingleton('O2::File')->writeFile($targetFile, $html);
}
#--------------------------------------------------------------------------------------------
sub _cleanUpOldFiles {
  my ($obj) = @_;
  my $path = $context->getEnv('O2CUSTOMERROOT') . '/var/o2WebProfiler/';
  return unless -d $path;
  
  my $fileMgr = $context->getSingleton('O2::File');
  foreach my $file ($fileMgr->scanDir($path)) {
    next if $file eq '.' || $file eq '..';
    my ($fileTime) = $file =~ m/(\d{9,10})/;
    if ( $fileTime && $fileTime < time - (86400*30) ) { # delete everything older than 30 days 
      if (-f "$path/$file") {
        $fileMgr->rmFile("$path/$file");
      }
      elsif (-d "$path/$file") {
        $fileMgr->rmFile("$path/$file", '-rf');
      }
    }
  }
}
#--------------------------------------------------------------------------------------------
1;
