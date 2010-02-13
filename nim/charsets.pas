//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit charsets;

interface

const
  CharSize = SizeOf(Char);
  Lrz = ' ';
  Apo = '''';
  Tabulator = #9;
  ESC = #27;
  CR = #13;
  FF = #12;
  LF = #10;
  BEL = #7;
  BACKSPACE = #8;
  VT = #11;
{$ifdef macos}
  DirSep = ':';
  NL = CR + '';
  FirstNLchar = CR;
  PathSep = ';'; // XXX: is this correct?
{$else}
  {$ifdef unix}
  DirSep = '/';
  NL = LF + '';
  FirstNLchar = LF;
  PathSep = ':';
  {$else} // windows, dos
  DirSep = '\';
  NL = CR + LF;
  FirstNLchar = CR;
  DriveSeparator = ':';
  PathSep = ';';
  {$endif}
{$endif}
  UpLetters   = ['A'..'Z', #192..#222];
  DownLetters = ['a'..'z', #223..#255];
  Numbers     = ['0'..'9'];
  Letters     = UpLetters + DownLetters;

type
  TCharSet = set of Char;
  PCharSet = ^TCharSet;

implementation

end.
