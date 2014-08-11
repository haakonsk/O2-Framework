package O2::Template::Taglibs::Html::MediaPlayer;

use strict;

use base 'O2::Template::Taglibs::Html';

my %__EXTMAPPING = (
  flv   => 'flash',
  avi   => 'mediaplayer',
  wmv   => 'mediaplayer',
  mpg   => 'mediaplayer',
  mov   => 'quickTimeVideoPlayer',
  wav   => 'quickTimeMusicPlayer',
  mp3   => 'quickTimeMusicPlayer',
  '3gp' => 'quickTimeMusicPlayer',
);

#--------------------------------------------------------------------------------------------
sub register { # Method called by the tag-parser to see what and how methods should be called
  my ($package, %params) = @_;
  my ($obj, %methods) = $package->SUPER::register(%params);
  %methods = (
    %methods,
    MediaPlayer  => '',
  );
  return ($obj, %methods);
}
#--------------------------------------------------------------------------------------------
sub MediaPlayer {
  my ($obj, %params) = @_;
  my $url = $params{url};
  my ($extGuess) = $url =~ m/.+\.(\w+)$/xms;
  $extGuess = lc $extGuess;
  
  return $obj->_getFLVPlayer(%params)            if $__EXTMAPPING{$extGuess} eq 'flash';
  return $obj->_getQuickTimeMusicPlayer(%params) if $__EXTMAPPING{$extGuess} eq 'quickTimeMusicPlayer';
  return $obj->_getQuickTimeVideoPlayer(%params) if $__EXTMAPPING{$extGuess} eq 'quickTimeVideoPlayer';
  return $obj->_getMediaPlayer(%params)          if $__EXTMAPPING{$extGuess} eq 'mediaplayer';
  return "<b>mediaPlayer, unknown format</b><br>try downloading it to play $extGuess: <a href=\"$url\">$url</a></b>";
}
#--------------------------------------------------------------------------------------------
sub _getFLVPlayer {
  my ($obj, %params) = @_;
  my $w = $params{width}  || 360;
  my $h = $params{height} || 280;
  
  my @flashVars;
  push @flashVars, 'autostart=' . ($params{autoStart} ? 'true' : 'false');
  push @flashVars, "file=$params{url}";
  push @flashVars, "image=$params{previewImage}" if $params{previewImage};
  my $flashVars = join '&', @flashVars;
  
  my $id = 'container' . $obj->_getRandomId();
  my $html = qq{
    <div id="$id"><a href="http://www.macromedia.com/go/getflashplayer">Get the Flash Player</a> to see this player.</div>
    <script type="text/javascript" src="/flash/jwflvmediaplayer/swfobject.js"></script>
    <script type="text/javascript">
      var s1 = new SWFObject("/flash/jwflvmediaplayer/player.swf","mediaplayer","$w","$h","9","#FFFFFF");
      s1.addParam("allowfullscreen","false");
      s1.addParam("allowscriptaccess","always");
      s1.addParam("flashvars","$flashVars");
      s1.write("$id");
    </script>};
  return $html;
}
#--------------------------------------------------------------------------------------------
sub _getQuickTimeVideoPlayer {
  my ($obj, %params) = @_;
  my $w = $params{width}  || 360;
  my $h = $params{height} || 280;
  my $autoStart = $params{autoStart} ? 'true' : 'false';
  my $html = qq{
    <object classid="clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B" codebase="http://www.apple.com/qtactivex/qtplugin.cab" height="$h" width="$w">
      <param name="src" value="$params{url}">
      <param name="autoplay" value="$autoStart">
      <param name="type" value="video/quicktime" height="$h" width="$w">
      <embed src="$params{url}" height="$h" width="$w" autoplay="$autoStart" type="video/quicktime" pluginspage="http://www.apple.com/quicktime/download/">
    </object>};
  return $html;
}
#--------------------------------------------------------------------------------------------
sub _getQuickTimeMusicPlayer {
  my ($obj, %params) = @_;
  my $w = $params{width}  || 400;
  my $h = $params{height} || 360;
  my $autoStart = $params{autoStart} ? 'true' : 'false';
  my $html = qq{
    <embed src="$params{url}" 
      width="$w" height="$h" autostart="$autoStart" loop="false"> 
    </embed>};
  return $html
}
#--------------------------------------------------------------------------------------------
sub _getMediaPlayer {
  my ($obj, %params) = @_;
  my $autoStart  = $params{autoStart} ? 'true' : 'false';
  my $autoStart2 = $params{autoStart} ? 1      : '0';
  my $w = $params{width}  || 400;
  my $h = $params{height} || 380;
  return qq{
    <object id="mediaPlayer"
      classid="CLSID:22D6F312-B0F6-11D0-94AB-0080C74C7E95" 
      codebase="http://activex.microsoft.com/activex/controls/mplayer/en/nsmp2inf.cab#Version=5,1,52,701" 
      standby="Loading Microsoft® Windows® Media Player components..."
      type="application/x-oleobject" width="$w" height="$h">
      <param name="FileName" value="$params{url}">
      <param name="AutoStart" value="$autoStart">
      <param name="ShowControls" value="True">
      <param name="transparentatStart" value="False">
      <param name="ShowStatusBar" value="True">
      <param name="animationatStart" value="true">
      <param name="ShowDisplay" value="False"> 
      <embed type="application/x-mplayer2" 
        pluginspage="http://www.microsoft.com/Windows/MediaPlayer/" 
        id=mediaPlayer
        name="mediaPlayer"
        src="$params{url}"
        autostart=$autoStart
        showstatusbar=1
        animationatstart=True
        showdisplay=False
        transparentatstart=False
        showcontrols=1
        width="$w" 
        height="$h">
      </embed> 
   </object>};
}
#--------------------------------------------------------------------------------------------
1;
