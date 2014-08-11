package O2::Util::MimeType;

use strict;

#--------------------------------------------------------------------------------------------
sub new {
  my ($pkg) = @_;
  
  my %mimeTypes = (
    'unknown' => { type => 'application/unknown',           description => 'unknown file type',          },
    'rtx'     => { type => 'text/richtext',                                                              },
    'cdf'     => { type => 'application/x-netcdf',                                                       },
    'csh'     => { type => 'application/x-csh',                                                          },
    'dm'      => { type => 'application/vnd.oma.drm.message',                                            },
    'pdb'     => { type => 'chemical/x-pdb',                                                             },
    'nc'      => { type => 'application/x-netcdf',                                                       },
    'wmlsc'   => { type => 'application/vnd.wap.wmlscriptc',                                             },
    'pdf'     => { type => 'application/pdf',                                                            },
    'src'     => { type => 'application/x-wais-source',                                                  },
    'wmlc'    => { type => 'application/vnd.wap.wmlc',                                                   },
    'ogg'     => { type => 'application/ogg',               o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'css'     => { type => 'text/css',                                                                   },
    'tgz'     => { type => 'application/x-gzip',                                                         },
    'htm'     => { type => 'text/html',                                                                  },
    'dxr'     => { type => 'application/x-director',                                                     },
    'gtar'    => { type => 'application/x-gtar',                                                         },
    'dir'     => { type => 'application/x-director',                                                     },
    'wmls'    => { type => 'text/vnd.wap.wmlscript',                                                     },
    'skd'     => { type => 'application/x-koan',                                                         },
    'ksp'     => { type => 'application/x-kspread',                                                      },
    'iges'    => { type => 'model/iges',                                                                 },
    'xsl'     => { type => 'text/xml',                                                                   },
    'skm'     => { type => 'application/x-koan',                                                         },
    'skp'     => { type => 'application/x-koan',                                                         },
    'skt'     => { type => 'application/x-koan',                                                         },
    'latex'   => { type => 'application/x-latex',                                                        },
    'ice'     => { type => 'x-conference/x-cooltalk',                                                    },
    'rgb'     => { type => 'image/x-rgb',                                                                },
    'gz'      => { type => 'application/x-gzip',                                                         },
    'roff'    => { type => 'application/x-troff',                                                        },
    'asc'     => { type => 'text/plain',                                                                 },
    'vcd'     => { type => 'application/x-cdlink',                                                       },
    'gif'     => { type => 'image/gif',                     o2ClassName => 'O2::Obj::Image',             },
    'tar'     => { type => 'application/x-tar',                                                          },
    'xls'     => { type => 'application/vnd.ms-excel',                                                   },
    'mesh'    => { type => 'model/mesh',                                                                 },
    'tif'     => { type => 'image/tiff',                    o2ClassName => 'O2::Obj::Image',             },
    'djv'     => { type => 'image/vnd.djvu',                                                             },
    'mp2'     => { type => 'audio/mpeg',                    o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    '3gp'     => { type => 'video/3gpp',                    o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'mp3'     => { type => 'audio/mpeg',                    o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'texi'    => { type => 'application/x-texinfo',                                                      },
    'txt'     => { type => 'text/plain',                                                                 },
    'jpe'     => { type => 'image/jpeg',                    o2ClassName => 'O2::Obj::Image',             },
    'dcr'     => { type => 'application/x-director',                                                     },
    'stc'     => { type => 'application/vnd.sun.xml.calc.template',                                      },
    'jpg'     => { type => 'image/jpeg',                    o2ClassName => 'O2::Obj::Image',             },
    'bin'     => { type => 'application/octet-stream',                                                   },
    'std'     => { type => 'application/vnd.sun.xml.draw.template',                                      },
    'ai'      => { type => 'application/postscript',                                                     },
    'sti'     => { type => 'application/vnd.sun.xml.impress.template',                                   },
    'bz2'     => { type => 'application/x-bzip2',                                                        },
    'jpeg'    => { type => 'image/jpeg',                    o2ClassName => 'O2::Obj::Image',             },
    'xml'     => { type => 'text/xml',                                                                   },
    'ps'      => { type => 'application/postscript',                                                     },
    'png'     => { type => 'image/png',                     o2ClassName => 'O2::Obj::Image',             },
    'au'      => { type => 'audio/basic',                   o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'vrml'    => { type => 'model/vrml',                                                                 },
    'stw'     => { type => 'application/vnd.sun.xml.writer.template',                                    },
    'pnm'     => { type => 'image/x-portable-anymap',       o2ClassName => 'O2::Obj::Image',             },
    'mov'     => { type => 'video/quicktime',               o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'smi'     => { type => 'application/smil',                                                           },
    'movie'   => { type => 'video/x-sgi-movie',             o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'wav'     => { type => 'audio/x-wav',                   o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'tiff'    => { type => 'image/tiff',                    o2ClassName => 'O2::Obj::Image',             },
    'm3u'     => { type => 'audio/x-mpegurl',               o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'lzh'     => { type => 'application/octet-stream',                                                   },
    'eps'     => { type => 'application/postscript',                                                     },
    'rpm'     => { type => 'application/x-rpm',                                                          },
    'exe'     => { type => 'application/octet-stream',                                                   },
    'html'    => { type => 'text/html',                                                                  },
    'ram'     => { type => 'audio/x-pn-realaudio',          o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'ief'     => { type => 'image/ief',                     o2ClassName => 'O2::Obj::Image',             },
    'pgm'     => { type => 'image/x-portable-graymap',      o2ClassName => 'O2::Obj::Image',             },
    'ras'     => { type => 'image/x-cmu-raster',            o2ClassName => 'O2::Obj::Image',             },
    'mpe'     => { type => 'video/mpeg',                    o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'pgn'     => { type => 'application/x-chess-pgn',                                                    },
    't'       => { type => 'application/x-troff',                                                        },
    'mpg'     => { type => 'video/mpeg',                    o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'tcl'     => { type => 'application/x-tcl',                                                          },
    'dll'     => { type => 'application/octet-stream',                                                   },
    'wbxml'   => { type => 'application/vnd.wap.wbxml',                                                  },
    'silo'    => { type => 'model/mesh',                                                                 },
    'qt'      => { type => 'video/quicktime',               o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'man'     => { type => 'application/x-troff-man',                                                    },
    'snd'     => { type => 'audio/basic',                   o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'mid'     => { type => 'audio/midi',                    o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'mif'     => { type => 'application/vnd.mif',                                                        },
    'cpio'    => { type => 'application/x-cpio',                                                         },
    'ra'      => { type => 'audio/x-realaudio',             o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'js'      => { type => 'application/x-javascript',                                                   },
    'mxu'     => { type => 'video/vnd.mpegurl',                                                          },
    'rm'      => { type => 'audio/x-pn-realaudio',          o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'zip'     => { type => 'application/zip',                                                            },
    'kwd'     => { type => 'application/x-kword',                                                        },
    'sgm'     => { type => 'text/sgml',                                                                  },
    'smil'    => { type => 'application/smil',                                                           },
    'wrl'     => { type => 'model/vrml',                                                                 },
    'oda'     => { type => 'application/oda',                                                            },
    'sv4cpio' => { type => 'application/x-sv4cpio',                                                      },
    'avi'     => { type => 'video/x-msvideo',               o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'mpeg'    => { type => 'video/mpeg',                    o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'tsv'     => { type => 'text/tab-separated-values',                                                  },
    'dms'     => { type => 'application/octet-stream',                                                   },
    'xwd'     => { type => 'image/x-xwindowdump',           o2ClassName => 'O2::Obj::Image',             },
    'shar'    => { type => 'application/x-shar',                                                         },
    'cpt'     => { type => 'application/mac-compactpro',                                                 },
    'ppm'     => { type => 'image/x-portable-pixmap',       o2ClassName => 'O2::Obj::Image',             },
    'chrt'    => { type => 'application/x-kchart',                                                       },
    'class'   => { type => 'application/octet-stream',                                                   },
    'kwt'     => { type => 'application/x-kword',                                                        },
    'ppt'     => { type => 'application/vnd.ms-powerpoint',                                              },
    'sh'      => { type => 'application/x-sh',                                                           },
    'xht'     => { type => 'application/xhtml+xml',                                                      },
    'swf'     => { type => 'application/x-shockwave-flash', o2ClassName =>'O2::Obj::Flash',              },
    'so'      => { type => 'application/octet-stream',                                                   },
    'hqx'     => { type => 'application/mac-binhex40',                                                   },
    'djvu'    => { type => 'image/vnd.djvu',                                                             },
    'kpr'     => { type => 'application/x-kpresenter',                                                   },
    'kar'     => { type => 'audio/midi',                    o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'kpt'     => { type => 'application/x-kpresenter',                                                   },
    'xpm'     => { type => 'image/x-xpixmap',               o2ClassName => 'O2::Obj::Image',             },
    'texinfo' => { type => 'application/x-texinfo',                                                      },
    'igs'     => { type => 'model/iges',                                                                 },
    'tex'     => { type => 'application/x-tex',                                                          },
    'kil'     => { type => 'application/x-killustrator',                                                 },
    'pbm'     => { type => 'image/x-portable-bitmap',       o2ClassName => 'O2::Obj::Image',             },
    'dvi'     => { type => 'application/x-dvi',                                                          },
    'xhtml'   => { type => 'application/xhtml+xml',                                                      },
    'midi'    => { type => 'audio/midi',                    o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'spl'     => { type => 'application/x-futuresplash',                                                 },
    'sv4crc'  => { type => 'application/x-sv4crc',                                                       },
    'sgml'    => { type =>  'text/sgml',                                                                 },
    'sxc'     => { type => 'application/vnd.sun.xml.calc',                                               },
    'doc'     => { type => 'application/msword',                                                         },
    'ustar'   => { type => 'application/x-ustar',                                                        },
    'sxd'     => { type => 'application/vnd.sun.xml.draw',                                               },
    'bmp'     => { type => 'image/bmp',                     o2ClassName => 'O2::Obj::Image',             },
    'sxg'     => { type => 'application/vnd.sun.xml.writer.global',                                      },
    'aifc'    => { type => 'audio/x-aiff',                  o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'sxi'     => { type => 'application/vnd.sun.xml.impress',                                            },
    'aiff'    => { type => 'audio/x-aiff',                  o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'msh'     => { type => 'model/mesh',                                                                 },
    'sxm'     => { type => 'application/vnd.sun.xml.math',                                               },
    'mpga'    => { type => 'audio/mpeg',                    o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'tr'      => { type => 'application/x-troff',                                                        },
    'xbm'     => { type => 'image/x-xbitmap',                                                            },
    'aif'     => { type => 'audio/x-aiff',                  o2ClassName => 'O2::Obj::MultiMedia::Audio', },
    'me'      => { type => 'application/x-troff-me',                                                     },
    'sit'     => { type => 'application/x-stuffit',                                                      },
    'ez'      => { type => 'application/andrew-inset',                                                   },
    'sxw'     => { type => 'application/vnd.sun.xml.writer',                                             },
    'rtf'     => { type => 'text/rtf',                                                                   },
    'hdf'     => { type => 'application/x-hdf',                                                          },
    'ms'      => { type => 'application/x-troff-ms',                                                     },
    'wml'     => { type => 'text/vnd.wap.wml',                                                           },
    'bcpio'   => { type => 'application/x-bcpio',                                                        },
    'etx'     => { type => 'text/x-setext',                                                              },
    'wbmp'    => { type => 'image/vnd.wap.wbmp',            o2ClassName => 'O2::Obj::Image',             },
    'lha'     => { type => 'application/octet-stream',                                                   },
    'xyz'     => { type => 'chemical/x-xyz',                                                             },
    'jar'     => { type => 'application/java-archive',                                                   },
    'jad'     => { type => 'text/vnd.sun.j2me.app-descriptor',                                           },
    'flv'     => { type => 'video/x-flv',                   o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'mp4'     => { type => 'video/mpeg',                    o2ClassName => 'O2::Obj::MultiMedia::Video', },
    'wmv'     => { type => 'video/x-ms-wmv',                o2ClassName => 'O2::Obj::MultiMedia::Video', },
  );
  
  return bless {
    mimeTypes => \%mimeTypes,
  }, $pkg;
}
#--------------------------------------------------------------------------------------------
sub getClassNameByFileExtension {
  my ($obj, $extension) = @_;
  $extension = lc $extension;
  if ( exists $obj->{mimeTypes}->{$extension}  &&  exists $obj->{mimeTypes}->{$extension}->{o2ClassName} ) {
    return $obj->{mimeTypes}->{$extension}->{o2ClassName};
  }
  return 'O2::Obj::File';
}
#--------------------------------------------------------------------------------------------
sub getMimeTypeByFileName {
  my ($obj, $fileName) = @_;
  return $obj->_getMimeType(fileName => $fileName)->{type};
}
#--------------------------------------------------------------------------------------------
sub _getMimeType {
  my ($obj, %params) = @_;
  if (exists $params{fileName}) {
    my ($ext) = $params{fileName} =~ m/^.+\.(\w+)$/i;
    if ($ext && exists $obj->{mimeTypes}->{$ext}) {
      return $obj->{mimeTypes}->{$ext};
    }
  }
  return $obj->{mimeTypes}->{unknown};
}
#--------------------------------------------------------------------------------------------
1;


__END__
XXX Struct this into the datastructure above
HTML text data (RFC 1866);html htm ;;text/html
Plain text: documents; program listings;txt c c++ pl cc h;;text/plain 
Richtext (obsolete - replaced by text/enriched) ;;;text/richtext 
Structure enhanced text ;(etx?) ;;text/x-setext
Enriched text markup (RFC 1896);;;text/enriched
Tab-separated values (tabular);(tsv?) ;;text/tab-separated-values 
SGML documents (RFC 1874);;;text/sgml
Speech synthesis data (MVP Solutions) ;talk;;text/x-speech 
Cascading Stylesheets;css ;;text/css
DSSSL-online stylesheets;;;application/dsssl (proposed) 
GIF ;gif;;image/gif
X-Windows bitmap (b/w) ;xbm ;;image/x-xbitmap
X-Windows pixelmap (8-bit color) ;xpm ;;image/x-xpixmap
Portable Network Graphics;png ;;image/x-png
Image Exchange Format (RFC 1314);ief ;;image/ief
JPEG ;jpeg jpg jpe;;image/jpeg
TIFF ;tiff tif;;image/tiff
RGB ;rgb;;image/rgb
;;;image/x-rgb 
Group III Fax (RFC 1494);g3f ;;image/g3fax
X Windowdump format;xwd;;image/x-xwindowdump
Macintosh PICT format;pict ;;image/x-pict
PPM (UNIX PPM package);ppm ;;image/x-portable-pixmap
PGM (UNIX PPM package);pgm ;;image/x-portable-graymap 
PBM (UNIX PPM package);pbm ;;image/x-portable-bitmap
PNM (UNIX PPM package);pnm ;;image/x-portable-anymap
Microsoft Windows bitmap ;bmp ;;image/x-ms-bmp
CMU raster ;ras;;image/x-cmu-raster
Kodak Photo-CD ;pcd;;image/x-photo-cd
Computer Graphics Metafile ;cgm ;;image/cgm
North Am. Presentation Layer Protocol;;;image/naplps
CALS Type 1 or 2;mil cal ;;image/x-cals
Fractal Image Format (Iterated Systems) ;fif;;image/fif 
QuickSilver active image (Micrografx) ;dsf;;image/x-mgx-dsf 
CMX vector image (Corel);cmx ;;image/x-cmx
Wavelet-compressed (Summus);wi ;;image/wavelet
AutoCad Drawing (SoftSource);dwg ;;image/vnd.dwg
;;;image/x-dwg 
AutoCad DXF file (SoftSource);dxf ;;image/vnd.dxf
;;;image/x-dxf 
Simple Vector Format (SoftSource);svf;;image/vnd.svf 
;;;also vector/x-svf 
SGI B&W ;bw;;image/x-sgi-bw
SGI RGB ;rgba sgi;;image/x-sgi-rgba
Encapusulated PostScript;eps epsi epsf;;image/x-eps
"basic"audio - 8-bit u-law PCM;au snd;;audio/basic 
Macintosh audio format (AIpple);aif aiff aifc ;;audio/x-aiff
Microsoft audio ;wav ;;audio/x-wav
MPEG audio ;mpa abs mpega ;;audio/x-mpeg
MPEG-2 audio;mp2a mpa2 ;;audio/x-mpeg2
compressed speech (Echo Speech Corp.) ;es;;audio/echospeech 
Toolvox speech audio (Voxware);vox ;;audio/voxware 
RapidTransit compressed audio (Fast Man) ;lcc;;application/fastman 
Realaudio (Progressive Networks);ra ram;;application/x-pn-realaudio 
Realaudio plugin (Progressive Networks);rm rpm;;application/x-pn-realaudio-plugin 
NIFF music notation data format;;;application/vnd.music-niff 
MIDI music data ;mmid;;x-music/x-midi
Koan music data (SSeyo);skp ;;application/vnd.koan
;;;application/x-koan 
Speech synthesis data (MVP Solutions) ;talk;;text/x-speech 
MPEG video;mpeg mpg mpe;;video/mpeg
MPEG-2 video;mpv2 mp2v;;video/mpeg2
Macintosh Quicktime;qt mov ;;video/quicktime
Microsoft video ;avi;;video/x-msvideo
SGI Movie format;movie;;video/x-sgi-movie
VDOlive streaming video (VDOnet);vdo;;video/vdo 
Vivo streaming video (Vivo software) ;viv;;video/vnd.vivo 
Proxy autoconfiguration (Netscape browsers) ;pac;;application/x-ns-proxy-autoconfig 
See Chapter 6;;;application/x-www-form-urlencoded
See Chapter 9;;;application/x-www-local-exec
See Chapter 9 (Netscape extension);;;multipart/x-mixed-replace 
See Chapter 9 and Appendix B;;;multipart/form-data
Netscape Cooltalk chat data (Netscape) ;ice;;x-conference/x-cooltalk 
Interactive chat (Ichat);;;application/x-chat 
;;;
Text-Related;;;
PostScript ;ai eps ps;;application/postscript
Microsoft Rich Text Format;rtf ;;application/rtf
Adobe Acrobat PDF ;pdf ;;application/pdf
;;;application/x-pdf 
Maker Interchange Format (FrameMaker) ;mif;;application/vnd.mif 
;;;application/x-mif 
Troff document;t tr roff;;application/x-troff
Troff document with MAN macros;man ;;application/x-troff-man
Troff document with ME macros;me ;;application/x-troff-me
Troff document with MS macros;ms ;;application/x-troff-ms
<LaTeX document ;latex;;application/x-latex
Tex/LateX document;tex;;application/x-tex
GNU TexInfo document;texinfo texi ;;application/x-texinfo
TeX dvi format ;dvi;;application/x-dvi
MacWrite document;??;;application/macwriteii
MS word document;doc;;application/msword
MS word for DOS;msw;;application/x-dos_ms_word
WordPerfect 5.1 document;?? ;;application/wordperfect5.1 
SGML application (RFC 1874);;;application/sgml
Office Document Architecture;oda ;;application/oda 
Envoy Document;evy;;application/envoy
;;;application/x-envoy 
<Wang Info. Tranfer Format (Wang);;;application/wita 
DEC Document Transfer Format (DEC);;;application/dec-dx 
IBM Document Content Architecture (IBM) ;;;application/dca-rft 
;;;
CommonGround Digital Paper (No Hands Software) ;;;application/commonground 
FrameMaker Documents (Frame);doc fm frm frame ;;application/vnd.framemaker 
;;;application/x-maker 
;;;    application/x-framemaker 
Remote printing at arbitrary printers (RFC 1486) ;;;application/remote-printing 
Gnu tar format;gtar;;application/x-gtar
4.3BSD tar format;tar;;application/x-tar
POSIX tar format;ustar;;application/x-ustar
<<<<<<Old CPIO format;bcpio;;application/x-bcpio
POSIX CPIO format;cpio;;application/x-cpio
UNIX sh shell archive;shar ;;application/x-shar
DOS/PC - Pkzipped archive;zip ;;application/zip
Macintosh Binhexed archive ;hqx ;;application/mac-binhex40 
Macintosh Stuffit Archive;sit sea ;;application/x-stuffit
Macintosh Macbinary ;bin;;application/x-macbinary
Fractal Image Format ;fif ;;application/fractals
;;;image/fif
Binary, UUencoded;bin uu;;
Binary, UUencoded;bin uu;;application/octet-stream
PC executable;exe;;application/octet-stream
WAIS "sources";src wsrc ;;application/x-wais-source 
NCSA HDF data format;hdf;;application/hdf
Javascript program ;js ls mocha ;;text/javascript 
;;;application/x-javascript 
VBScript program ;;;text/vbscript
UNIX bourne shell program;sh ;;application/x-sh
UNIX c-shell program;csh;;application/x-csh
Perl program;pl;;application/x-perl
Tcl (Tool Control Language) program;tcl ;;application/x-tcl
Atomicmail program scripts (obsolete) ;;;application/atomicmail 
Slate documents - executable enclosures (BBN) ;;;application/slate 
Undefined binary data (often executable progs) ;;;application/octet-stream 
RISC OS Executable programs (ANT Limited) ;;;application/riscos 
Andrew Toolkit inset;;;application/andrew-inset
FutureSplash vector animation (FutureWave) ;spl;;application/futuresplash 
mBED multimedia data (mBED);mbd ;;application/mbedlet 
Macromedia Shockwave (Macromedia);;;application/x-director 
Sizzler real-time video/animation;;;application/x-sprite 
PowerMedia multimedia (RadMedia);rad;;application/x-rad-powermedia 
PowerPoint presentation (Microsoft);ppz;;application/mspowerpoint 
PointPlus presentation data (Net Scene) ;css;;application/x-pointplus 
ASAP WordPower (Software Publishing Corp.) ;asp;;application/x-asap 
Astound Web Player multimedia data (GoldDisk) ;asn;;application/astound 
OLE script e.g. Visual Basic (Ncompass) ;axs;;application/x-olescript 
OLE Object (Microsoft/NCompass);ods;;application/x-oleobject 
OpenScape OLE/OCX objects (Business@Web) ;opp;;x-form/x-openscape 
Visual Basic objects (Amara);wba ;;application/x-webbasic 
Specialized data entry forms (Alpha Software) ;frm;;application/x-alpha-form 
client-server objects (Wayfarer Communications) ;wfx;;x-script/x-wfxclient 
Undefined binary data (often executable progs) ;;;application/octet-stream 
CALS (U.S. D.O.D data format - RFC 1895);;;application/cals-1840 
Pointcast news data (Pointcast);pcn;;application/x-pcn 
;;;application/x-msexcel 
;;;application/ms-excel
;;;application/msexcel
;;;application/x-excel
Excel for DOS (Microsoft);xl;;application/x-dos_ms_excel 
PowerPoint (Microsoft);ppt, ppz, pps, pot ;;application/vnd.ms-powerpoint 
;;;application/mspowerpoint 
Microsoft Powerpoint for DOS (Microsoft);ppt ;;application/x-dos_ms_powerpoint2 
Help Docs(Microsoft);hlp ;;application/mshelp 
Microsoft Project (Microsoft);mpc, mpt, mpx, mpw, mpp ;;application/vnd.ms-project 
;;;application/msproject 
Works data (Microsoft);;;application/vnd.ms-works 
MAPI data (Microsoft);;;application/vnd.ms-tnef
Artgallery data (Microsoft);;;application/vnd.artgalry 
SourceView document (Dataware Electronics) ;svd;;application/vnd.svd 
Truedoc (Bitstream);;;application/vnd.truedoc
Net Install - software install (20/20 Software) ;ins;;application/x-net-install 
Carbon Copy - remote control/access (Microcom) ;ccv;;application/ccv 
Spreadsheets (Visual Components);vts;;workbook/formulaone 
Cybercash digital money (Cybercash);;;application/cybercash 
Format for sending generic Macintosh files;;;application/applefile 
Active message -- connect to active mail app. ;;;application/activemessage 
X.400 mail message body part (RFC 1494);;;application/x400-bp 
USENET news message id (RFC 1036);;;application/news-message-id 
USENET news message (RFC 1036);;;application/news-transmission 
Messages with multiple parts;;;multipart/mixed
Messages with multiple, alternative parts;;;multipart/alternative 
Message with multiple, related parts ;;;multipart/related
Multiple parts are digests;;;multipart/digest
For reporting of email status (admin.);;;multipart/report 
Order of parts does not matter;;;multipart/parallel
Macintosh file data;;;multipart/appledouble
Aggregate messages; descriptor as header;;;multipart/header-set 
Container for voice-mail ;;;multipart/voice-message
HTML FORM data (see Ch. 9 and App. B);;;multipart/form-data
Infinite multiparts - See Chapter 9 (Netscape) ;;;multipart/x-mixed-replace 
MIME message;;;message/rfc822
Partial message;;;message/partial
Message containing external references;;;message/external-body 
Message containing USENET news;;;message/news
HTTP message ;;;message/http
VRML data file;wrl vrml;;x-world/x-vrml 
(changing to model/vrml) 
WIRL - VRML data (VREAM);vrw ;;x-world/x-vream
Play3D 3d scene data (Play3D);p3d ;;application/x-p3d 
Viscape Interactive 3d world data (Superscape) ;svr;;x-world/x-svr 
WebActive 3d data (Plastic Thought) ;wvr;;x-world/x-wvr 
QuickDraw3D scene data (Apple);3dmf;;x-world/x-3dmf 
Chemical types -- to communicate information about chemical models ;;;chemical/* (several subtypes) 
Mathematica notebook;ma;;application/mathematica
Computational meshes for numerical simulations ;msh;;x-model/x-mesh 
(evolving to model/mesh) 
Vis5D 5-dimensional data ;v5d ;;application/vis5d
IGES models -- CAD/CAM (CGM) data ;igs ;;application/iges 
(evolving to model/iges?) 
Autocad WHIP vector drawings;dwf ;;drawing/x-dwf
Showcase Presentations;showcase slides sc sho show ;;application/x-showcase
Insight Manual pages;ins insight ;;application/x-insight
Iris Annotator data;ano;;application/x-annotator
Cosmo World Builder;vb;;application/x-cosmobuilder
Directory Viewer;dir;;application/x-dirview
Software License ;lic;;application/x-enterlicense
Fax manager file;faxmgr;;application/x-fax-manager 
Fax job data file;faxmgrjob ;;application/x-fax-manager-job 
IconBook data;icnbk;;application/x-iconbook
InPerson Call "Jumper";ipcall;;application/x-inperson-call
InPerson Shared Whiteboard;wb;;application/x-inpview
Installable software in 'inst' format;inst ;;application/x-install
Mail folder;mail;;application/x-mailfolder
InPerson People Pages;pp ppages;;application/x-ppages
Data for printer (via lpr);sgi-lpr ;;application/x-sgi-lpr
Software in 'tardist' format;tardist ;;application/x-tardist
Software in compressed 'tardist' format;ztardist;;application/x-ztardist 
WingZ spreadsheet;wkz;;application/x-wingz
Open Inventor 3-D scenes ;iv ;;graphics/x-inventor
