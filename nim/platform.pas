//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit platform;

// This module contains data about the different processors
// and operating systems.
// Note: Unfortunately if an OS or CPU is listed here this does not mean that
// Nimrod has been tested on this platform or that the RTL has been ported.
// Feel free to test for your exentric platform!

interface

{$include 'config.inc'}

uses
  nsystem, strutils;

type
  TSystemOS = (
    // Also add OS in initialization section and alias conditionals to
    // condsyms (end of module).
    osNone,
    osDos,
    osWindows,
    osOs2,
    osLinux,
    osMorphos,
    osSkyos,
    osSolaris,
    osIrix,
    osNetbsd,
    osFreebsd,
    osOpenbsd,
    osAix,
    osPalmos,
    osQnx,
    osAmiga,
    osAtari,
    osNetware,
    osMacos,
    osMacosx,
    osEcmaScript,
    osNimrodVM
  );
type
  TInfoOSProp = (
    ospNeedsPIC,        // OS needs PIC for libraries
    ospCaseInsensitive, // OS filesystem is case insensitive
    ospPosix            // OS is posix-like
  );

  TInfoOSProps = set of TInfoOSProp;
  TInfoOS = record{@tuple}
    name: string;
    parDir: string;
    dllExt: string;
    altDirSep: string;
    dllPrefix: string;
    objExt: string;
    newLine: string;
    pathSep: string;
    dirSep: string;
    scriptExt: string;
    curDir: string;
    exeExt: string;
    extSep: string;
    props: TInfoOSProps;
  end;
const
  OS: array [succ(low(TSystemOS))..high(TSystemOS)] of TInfoOS = (
  (
    name: 'DOS';
    parDir: '..';
    dllExt: '.dll';
    altDirSep: '/'+'';
    dllPrefix: '';
    objExt: '.obj';
    newLine: #13#10;
    pathSep: ';'+'';
    dirSep: '\'+'';
    scriptExt: '.bat';
    curDir: '.'+'';
    exeExt: '.exe';
    extSep: '.'+'';
    props: {@set}[ospCaseInsensitive];
  ),
  (
    name: 'Windows';
    parDir: '..';
    dllExt: '.dll';
    altDirSep: '/'+'';
    dllPrefix: '';
    objExt: '.obj';
    newLine: #13#10;
    pathSep: ';'+'';
    dirSep: '\'+'';
    scriptExt: '.bat';
    curDir: '.'+'';
    exeExt: '.exe';
    extSep: '.'+'';
    props: {@set}[ospCaseInsensitive];
  ),
  (
    name: 'OS2';
    parDir: '..';
    dllExt: '.dll';
    altDirSep: '/'+'';
    dllPrefix: '';
    objExt: '.obj';
    newLine: #13#10;
    pathSep: ';'+'';
    dirSep: '\'+'';
    scriptExt: '.bat';
    curDir: '.'+'';
    exeExt: '.exe';
    extSep: '.'+'';
    props: {@set}[ospCaseInsensitive];
  ),
  (
    name: 'Linux';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'MorphOS';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'SkyOS';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'Solaris';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'Irix';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'NetBSD';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'FreeBSD';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'OpenBSD';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'AIX';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'PalmOS';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC];
  ),
  (
    name: 'QNX';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'Amiga';
    parDir: '..';
    dllExt: '.library';
    altDirSep: '/'+'';
    dllPrefix: '';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC];
  ),
  (
    name: 'Atari';
    parDir: '..';
    dllExt: '.dll';
    altDirSep: '/'+'';
    dllPrefix: '';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '';
    curDir: '.'+'';
    exeExt: '.tpp';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC];
  ),
  (
    name: 'Netware';
    parDir: '..';
    dllExt: '.nlm';
    altDirSep: '/'+'';
    dllPrefix: '';
    objExt: '';
    newLine: #13#10;
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '.nlm';
    extSep: '.'+'';
    props: {@set}[ospCaseInsensitive];
  ),
  (
    name: 'MacOS';
    parDir: '::';
    dllExt: 'Lib';
    altDirSep: ':'+'';
    dllPrefix: '';
    objExt: '.o';
    newLine: #13+'';
    pathSep: ','+'';
    dirSep: ':'+'';
    scriptExt: '';
    curDir: ':'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospCaseInsensitive];
  ),
  (
    name: 'MacOSX';
    parDir: '..';
    dllExt: '.dylib';
    altDirSep: ':'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[ospNeedsPIC, ospPosix];
  ),
  (
    name: 'EcmaScript';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[];
  ),
  (
    name: 'NimrodVM';
    parDir: '..';
    dllExt: '.so';
    altDirSep: '/'+'';
    dllPrefix: 'lib';
    objExt: '.o';
    newLine: #10+'';
    pathSep: ':'+'';
    dirSep: '/'+'';
    scriptExt: '.sh';
    curDir: '.'+'';
    exeExt: '';
    extSep: '.'+'';
    props: {@set}[];
  )
);
type
  TSystemCPU = (
    // Also add CPU for in initialization section and alias conditionals to
    // condsyms (end of module).
    cpuNone,
    cpuI386,
    cpuM68k,
    cpuAlpha,
    cpuPowerpc,
    cpuSparc,
    cpuVm,
    cpuIa64,
    cpuAmd64,
    cpuMips,
    cpuArm,
    cpuEcmaScript,
    cpuNimrodVM
  );
type
  TEndian = (littleEndian, bigEndian);
  TInfoCPU = record{@tuple}
    name: string;
    intSize: int;
    endian: TEndian;
    floatSize: int;
    bit: int;
  end;
const
  EndianToStr: array [TEndian] of string = ('littleEndian', 'bigEndian');
  CPU: array [succ(low(TSystemCPU))..high(TSystemCPU)] of TInfoCPU = (
  (
    name: 'i386';
    intSize: 32;
    endian: littleEndian;
    floatSize: 64;
    bit: 32;
  ),
  (
    name: 'm68k';
    intSize: 32;
    endian: bigEndian;
    floatSize: 64;
    bit: 32;
  ),
  (
    name: 'alpha';
    intSize: 64;
    endian: littleEndian;
    floatSize: 64;
    bit: 64;
  ),
  (
    name: 'powerpc';
    intSize: 32;
    endian: bigEndian;
    floatSize: 64;
    bit: 32;
  ),
  (
    name: 'sparc';
    intSize: 32;
    endian: bigEndian;
    floatSize: 64;
    bit: 32;
  ),
  (
    name: 'vm';
    intSize: 32;
    endian: littleEndian;
    floatSize: 64;
    bit: 32;
  ),
  (
    name: 'ia64';
    intSize: 64;
    endian: littleEndian;
    floatSize: 64;
    bit: 64;
  ),
  (
    name: 'amd64';
    intSize: 64;
    endian: littleEndian;
    floatSize: 64;
    bit: 64;
  ),
  (
    name: 'mips';
    intSize: 32;
    endian: bigEndian;
    floatSize: 64;
    bit: 32;
  ),
  (
    name: 'arm';
    intSize: 32;
    endian: littleEndian;
    floatSize: 64;
    bit: 32;
  ),
  (
    name: 'ecmascript';
    intSize: 32;
    endian: bigEndian;
    floatSize: 64;
    bit: 32;
  ),
  (
    name: 'nimrodvm';
    intSize: 32;
    endian: bigEndian;
    floatSize: 64;
    bit: 32;
  )
);

var
  targetCPU, hostCPU: TSystemCPU;
  targetOS, hostOS: TSystemOS;

function NameToOS(const name: string): TSystemOS;
function NameToCPU(const name: string): TSystemCPU;

var
  IntSize: int;
  floatSize: int;
  PtrSize: int;
  tnl: string; // target newline

procedure setTarget(o: TSystemOS; c: TSystemCPU);

implementation

procedure setTarget(o: TSystemOS; c: TSystemCPU);
begin
  assert(c <> cpuNone);
  assert(o <> osNone);
  targetCPU := c;
  targetOS := o;
  intSize := cpu[c].intSize div 8;
  floatSize := cpu[c].floatSize div 8;
  ptrSize := cpu[c].bit div 8;
  tnl := os[o].newLine;
end;

function NameToOS(const name: string): TSystemOS;
var
  i: TSystemOS;
begin
  for i := succ(osNone) to high(TSystemOS) do
    if cmpIgnoreStyle(name, OS[i].name) = 0 then begin
      result := i; exit
    end;
  result := osNone
end;

function NameToCPU(const name: string): TSystemCPU;
var
  i: TSystemCPU;
begin
  for i := succ(cpuNone) to high(TSystemCPU) do
    if cmpIgnoreStyle(name, CPU[i].name) = 0 then begin
      result := i; exit
    end;
  result := cpuNone
end;

// this is Ok for the Pascal version, but the Nimrod version needs a different
// mechanism
{@emit
procedure nimCPU(): cstring; importc; noconv;}
{@emit
procedure nimOS(): cstring; importc; noconv;}

{@ignore}
initialization
{$ifdef i386}
  hostCPU := cpuI386;
{$endif}
{$ifdef m68k}
  hostCPU := cpuM68k;
{$endif}
{$ifdef alpha}
  hostCPU := cpuAlpha;
{$endif}
{$ifdef powerpc}
  hostCPU := cpuPowerpc;
{$endif}
{$ifdef sparc}
  hostCPU := cpuSparc;
{$endif}
{$ifdef vm}
  hostCPU := cpuVm;
{$endif}
{$ifdef ia64}
  hostCPU := cpuIa64;
{$endif}
{$ifdef amd64}
  hostCPU := cpuAmd64;
{$endif}
{$ifdef mips}
  hostCPU := cpuMips;
{$endif}
{$ifdef arm}
  hostCPU := cpuArm;
{$endif}
{$ifdef DOS}
  hostOS := osDOS;
{$endif}
{$ifdef Windows}
  hostOS := osWindows;
{$endif}
{$ifdef OS2}
  hostOS := osOS2;
{$endif}
{$ifdef Linux}
  hostOS := osLinux;
{$endif}
{$ifdef MorphOS}
  hostOS := osMorphOS;
{$endif}
{$ifdef SkyOS}
  hostOS := osSkyOS;
{$endif}
{$ifdef Solaris}
  hostOS := osSolaris;
{$endif}
{$ifdef Irix}
  hostOS := osIrix;
{$endif}
{$ifdef NetBSD}
  hostOS := osNetBSD;
{$endif}
{$ifdef FreeBSD}
  hostOS := osFreeBSD;
{$endif}
{$ifdef OpenBSD}
  hostOS := osOpenBSD;
{$endif}
{$ifdef PalmOS}
  hostOS := osPalmOS;
{$endif}
{$ifdef QNX}
  hostOS := osQNX;
{$endif}
{$ifdef Amiga}
  hostOS := osAmiga;
{$endif}
{$ifdef Atari}
  hostOS := osAtari;
{$endif}
{$ifdef Netware}
  hostOS := osNetware;
{$endif}
{$ifdef MacOS}
  hostOS := osMacOS;
{$endif}
{$ifdef MacOSX}
  hostOS := osMacOSX;
{$endif}
{$ifdef darwin} // BUGFIX
  hostOS := osMacOSX;
{$endif}
{@emit
  hostCPU := nameToCPU(toString(nimCPU()));
}
{@emit
  hostOS := nameToOS(toString(nimOS()));
}
  setTarget(hostOS, hostCPU); // assume no cross-compiling
end.
