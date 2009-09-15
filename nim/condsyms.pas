//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit condsyms;

// This module handles the conditional symbols.

{$include 'config.inc'}

interface

uses
  nsystem, ast, astalgo, msgs, nhashes, platform, strutils, idents;

var
  gSymbols: TStrTable;

procedure InitDefines;
procedure DeinitDefines;

procedure DefineSymbol(const symbol: string);
procedure UndefSymbol(const symbol: string);
function isDefined(symbol: PIdent): Boolean;
procedure ListSymbols;

function countDefinedSymbols: int;

implementation

procedure DefineSymbol(const symbol: string);
var
  sym: PSym;
  i: PIdent;
begin
  i := getIdent(symbol);
  sym := StrTableGet(gSymbols, i);
  if sym = nil then begin
    new(sym); // circumvent the ID mechanism
  {@ignore}
    fillChar(sym^, sizeof(sym^), 0);
  {@emit}
    sym.kind := skConditional;
    sym.name := i;
    StrTableAdd(gSymbols, sym);
  end;
  sym.position := 1;
end;

procedure UndefSymbol(const symbol: string);
var
  sym: PSym;
begin
  sym := StrTableGet(gSymbols, getIdent(symbol));
  if sym <> nil then sym.position := 0;
end;

function isDefined(symbol: PIdent): Boolean;
var
  sym: PSym;
begin
  sym := StrTableGet(gSymbols, symbol);
  result := (sym <> nil) and (sym.position = 1)
end;

procedure ListSymbols;
var
  it: TTabIter;
  s: PSym;
begin
  s := InitTabIter(it, gSymbols);
  MessageOut('-- List of currently defined symbols --');
  while s <> nil do begin
    if s.position = 1 then MessageOut(s.name.s);
    s := nextIter(it, gSymbols);
  end;
  MessageOut('-- End of list --');
end;

function countDefinedSymbols: int;
var
  it: TTabIter;
  s: PSym;
begin
  s := InitTabIter(it, gSymbols);
  result := 0;
  while s <> nil do begin
    if s.position = 1 then inc(result);
    s := nextIter(it, gSymbols);
  end;
end;

procedure InitDefines;
begin
  initStrTable(gSymbols);
  DefineSymbol('nimrod'); // 'nimrod' is always defined
  // add platform specific symbols:
  case targetCPU of
    cpuI386: DefineSymbol('x86');
    cpuIa64: DefineSymbol('itanium');
    cpuAmd64: DefineSymbol('x8664');
    else begin end
  end;
  case targetOS of
    osDOS: DefineSymbol('msdos');
    osWindows: begin
      DefineSymbol('mswindows');
      DefineSymbol('win32');
    end;
    osLinux, osMorphOS, osSkyOS, osIrix, osPalmOS, osQNX, osAtari, osAix: begin
      // these are all 'unix-like'
      DefineSymbol('unix');
      DefineSymbol('posix');
    end;
    osSolaris: begin
      DefineSymbol('sunos');
      DefineSymbol('unix');
      DefineSymbol('posix');
    end;
    osNetBSD, osFreeBSD, osOpenBSD: begin
      DefineSymbol('unix');
      DefineSymbol('bsd');
      DefineSymbol('posix');
    end;
    osMacOS: begin
      DefineSymbol('macintosh');
    end;
    osMacOSX: begin
      DefineSymbol('macintosh');
      DefineSymbol('unix');
      DefineSymbol('posix');
    end;
    else begin end
  end;
  DefineSymbol('cpu' + ToString( cpu[targetCPU].bit ));
  DefineSymbol(normalize(endianToStr[cpu[targetCPU].endian]));
  DefineSymbol(cpu[targetCPU].name);
  DefineSymbol(platform.os[targetOS].name);
end;

procedure DeinitDefines;
begin
end;

end.
