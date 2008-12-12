//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit nsystem;

// This module provides things that are in Nimrod's system
// module and not available in Pascal.

interface

{$include 'config.inc'}

uses
  sysutils
{$ifdef fpc}
  , math
{$endif}
  ;

type
  // Generic int like in Nimrod:
  // well, no, because of FPC's bugs...
{$ifdef cpu64}
  int = int64;
  uint = qword;
{$else}
  int = longint;
  uint = cardinal;
{$endif}

  TResult = Boolean;
  EInvalidValue = class(Exception)
  end;

{$ifndef fpc}
  EOverflow = class(Exception)
  end;
{$endif}
  EOutOfRange = class(Exception)
  end;

  float32 = single;
  float64 = double;
  PFloat32 = ^float32;
  PFloat64 = ^float64;
const
  Failure = False;
  Success = True;

  snil = '';

type
  Natural = 0..high(int);
  Positive = 1..high(int);
  NObject = object // base type for all objects, cannot use
  // TObject here, as it would overwrite System.TObject which is
  // a class in Object pascal. Anyway, pas2mor has no problems
  // to replace NObject by TObject
  end;
  PObject = ^NObject;

  int16 = smallint;
  int8 = shortint;
  int32 = longint;
  uint16 = word;
  uint32 = longword;
  uint8 = byte;

  TByteArray = array [0..1024 * 1024] of Byte;
  PByteArray = ^TByteArray;
  PByte = ^Byte;
  cstring = pchar;
  bool = boolean;
  PInt32 = ^int32;

{$ifdef bit64clean} // BUGIX: was $ifdef fpc
  BiggestUInt = QWord;
  BiggestInt = Int64; // biggest integer type available
{$else}
  BiggestUInt = Cardinal; // Delphi's Int64 is broken seriously
  BiggestInt = Integer;   // ditto
{$endif}
  BiggestFloat = Double; // biggest floating point type
{$ifdef cpu64}
  TAddress = Int64;
{$else}
  TAddress = longint;
{$endif}

var
  NaN: float;
  inf: float;
  NegInf: float;
{$ifdef fpc}
{$else}
  {$ifopt Q+}
    {$define Q_on}
    {$Q-}
  {$endif}
  {$ifopt R+}
    {$define R_on}
    {$R-}
  {$endif}
  const
    Inf = 1.0/0.0;
    NegInf = (-1.0) / 0.0;
  {$ifdef Q_on}
    {$Q+}
    {$undef Q_on}
  {$endif}
  {$ifdef R_on}
    {$R+}
    {$undef R_on}
  {$endif}
{$endif}

function toFloat(i: biggestInt): biggestFloat;
function toInt(r: biggestFloat): biggestInt;

function min(a, b: int): int; overload;
function max(a, b: int): int; overload;
{$ifndef fpc} // fpc cannot handle these overloads (bug in 64bit version?)
// the Nimrod compiler does not use them anyway, so it does not matter
function max(a, b: real): real; overload;
function min(a, b: real): real; overload;
{$endif}

procedure zeroMem(p: Pointer; size: int);
procedure copyMem(dest, source: Pointer; size: int);
procedure moveMem(dest, source: Pointer; size: int);
function equalMem(a, b: Pointer; size: int): Boolean;

function ncopy(s: string; a: int = 1): string; overload;
function ncopy(s: string; a, b: int): string; overload;
// will be replaced by "copy"

function newString(len: int): string;

procedure addChar(var s: string; c: Char);

{@ignore}
function addU(a, b: biggestInt): biggestInt;
function subU(a, b: biggestInt): biggestInt;
function mulU(a, b: biggestInt): biggestInt;
function divU(a, b: biggestInt): biggestInt;
function modU(a, b: biggestInt): biggestInt;
function shlU(a, b: biggestInt): biggestInt;
function shrU(a, b: biggestInt): biggestInt;
function ltU(a, b: biggestInt): bool;
function leU(a, b: biggestInt): bool;

function toU8(a: biggestInt): byte;
function toU16(a: biggestInt): int16;
function toU32(a: biggestInt): int32;
function ze64(a: byte): biggestInt;
function ze(a: byte): int;
{@emit}

function alloc(size: int): Pointer;
function realloc(p: Pointer; newsize: int): Pointer;
procedure dealloc(p: Pointer);

type
  TTextFile = record
    buf: PChar;
    sysFile: system.textFile;
  end;

  TBinaryFile = file;

  TFileMode = (fmRead, fmWrite, fmReadWrite, fmReadWriteExisting, fmAppend);

function OpenFile(out f: tTextFile; const filename: string;
                  mode: TFileMode = fmRead): Boolean; overload;
function endofFile(var f: tBinaryFile): boolean; overload;
function endofFile(var f: textFile): boolean; overload;

function readChar(var f: tTextFile): char;
function readLine(var f: tTextFile): string; overload;
function readLine(var f: tBinaryFile): string; overload;
function readLine(var f: textFile): string; overload;

procedure nimWrite(var f: tTextFile; const str: string); overload;
procedure nimCloseFile(var f: tTextFile); overload;

// binary file handling:
function OpenFile(var f: tBinaryFile; const filename: string;
                  mode: TFileMode = fmRead): Boolean; overload;
procedure nimCloseFile(var f: tBinaryFile); overload;

function ReadBytes(var f: tBinaryFile; out a: array of byte;
                   start, len: int): int;
function ReadChars(var f: tBinaryFile; out a: array of char;
                   start, len: int): int;

function writeBuffer(var f: TBinaryFile; buffer: pointer; len: int): int;
function readBuffer(var f: tBinaryFile; buffer: pointer; len: int): int;
overload;
function readBuffer(var f: tBinaryFile): string; overload;
function getFilePos(var f: tBinaryFile): int;
procedure setFilePos(var f: tBinaryFile; pos: int64);

function readFile(const filename: string): string;

procedure nimWrite(var f: tBinaryFile; const str: string); overload;

procedure add(var x: string; const y: string);
// Pascal version of string appending. Terminating zero is ignored.

implementation

{@ignore}
procedure add(var x: string; const y: string);
// Pascal version of string appending. Terminating zero is ignored.
var
  L: int;
begin
  L := length(y);
  if L > 0 then begin
    if y[L] = #0 then x := x + copy(y, 1, L-1)
    else x := x + y;
  end
end;
{@emit}

function alloc(size: int): Pointer;
begin
  getMem(result, size); // use standard allocator
  FillChar(result^, size, 0);
end;

function realloc(p: Pointer; newsize: int): Pointer;
begin
  reallocMem(p, newsize); // use standard allocator
  result := p;
end;

procedure dealloc(p: pointer);
begin
  freeMem(p);
end;

{@ignore}
function addU(a, b: biggestInt): biggestInt;
begin
  result := biggestInt(biggestUInt(a) + biggestUInt(b));
end;

function subU(a, b: biggestInt): biggestInt;
begin
  result := biggestInt(biggestUInt(a) - biggestUInt(b));
end;

function mulU(a, b: biggestInt): biggestInt;
begin
  result := biggestInt(biggestUInt(a) * biggestUInt(b));
end;

function divU(a, b: biggestInt): biggestInt;
begin
  result := biggestInt(biggestUInt(a) div biggestUInt(b));
end;

function modU(a, b: biggestInt): biggestInt;
begin
  result := biggestInt(biggestUInt(a) mod biggestUInt(b));
end;

function shlU(a, b: biggestInt): biggestInt;
begin
  result := biggestInt(biggestUInt(a) shl biggestUInt(b));
end;

function shrU(a, b: biggestInt): biggestInt;
begin
  result := biggestInt(biggestUInt(a) shr biggestUInt(b));
end;

function ltU(a, b: biggestInt): bool;
begin
  result := biggestUInt(a) < biggestUInt(b);
end;

function leU(a, b: biggestInt): bool;
begin
  result := biggestUInt(a) < biggestUInt(b);
end;

function toU8(a: biggestInt): byte;
begin
  assert(a >= 0);
  assert(a <= 255);
  result := a;
end;

function toU32(a: biggestInt): int32;
begin
  result := int32(a and $ffffffff);
end;

function toU16(a: biggestInt): int16;
begin
  result := int16(a and $ffff);  
end;

function ze64(a: byte): biggestInt;
begin
  result := a
end;

function ze(a: byte): int;
begin
  result := a
end;
{@emit}

procedure addChar(var s: string; c: Char);
{@ignore}
// delphi produces suboptimal code for "s := s + c"
{$ifndef fpc}
var
  len: int;
{$endif}
{@emit}
begin
{@ignore}
{$ifdef fpc}
  s := s + c
{$else}
  {$ifopt H+}
  len := length(s);
  setLength(s, len + 1);
  PChar(Pointer(s))[len] := c
  {$else}
  s := s + c
  {$endif}
{$endif}
{@emit
  s &= c
}
end;

function newString(len: int): string;
begin
  setLength(result, len);
  if len > 0 then begin
  {@ignore}
    fillChar(result[1], length(result), 0);
  {@emit}
  end
end;

function toFloat(i: BiggestInt): BiggestFloat;
begin
  result := i // conversion automatically in Pascal
end;

function toInt(r: BiggestFloat): BiggestInt;
begin
  result := round(r);
end;

procedure zeroMem(p: Pointer; size: int);
begin
  fillChar(p^, size, 0);
end;

procedure copyMem(dest, source: Pointer; size: int);
begin
  if size > 0 then
    move(source^, dest^, size);
end;

procedure moveMem(dest, source: Pointer; size: int);
begin
  if size > 0 then
    move(source^, dest^, size); // move handles overlapping regions
end;

function equalMem(a, b: Pointer; size: int): Boolean;
begin
  result := compareMem(a, b, size);
end;

{$ifndef fpc}
function min(a, b: real): real; overload;
begin
  if a < b then result := a else result := b
end;

function max(a, b: real): real; overload;
begin
  if a > b then result := a else result := b
end;
{$endif}

function min(a, b: int): int; overload;
begin
  if a < b then result := a else result := b
end;

function max(a, b: int): int; overload;
begin
  if a > b then result := a else result := b
end;

function ncopy(s: string; a, b: int): string;
begin
  result := copy(s, a, b-a+1);
end;

function ncopy(s: string; a: int = 1): string;
begin
  result := copy(s, a, length(s))
end;


{$ifopt I+} {$define I_on} {$I-} {$endif}
function OpenFile(out f: tTextFile; const filename: string;
                  mode: TFileMode = fmRead): Boolean; overload;
begin
  AssignFile(f.sysFile, filename);
  f.buf := alloc(4096);
  SetTextBuf(f.sysFile, f.buf^, 4096);
  case mode of
    fmRead: Reset(f.sysFile);
    fmWrite: Rewrite(f.sysFile);
    fmReadWrite: Reset(f.sysFile);
    fmAppend: Append(f.sysFile);
  end;
  result := (IOResult = 0);
end;

function readChar(var f: tTextFile): char;
begin
  Read(f.sysFile, result);
end;

procedure nimWrite(var f: tTextFile; const str: string);
begin
  system.write(f.sysFile, str)
end;

function readLine(var f: tTextFile): string;
begin
  Readln(f.sysFile, result);
end;

function endofFile(var f: tBinaryFile): boolean;
begin
  result := eof(f)
end;

function endofFile(var f: textFile): boolean;
begin
  result := eof(f)
end;

procedure nimCloseFile(var f: tTextFile);
begin
  closeFile(f.sysFile);
  dealloc(f.buf)
end;

procedure nimCloseFile(var f: tBinaryFile);
begin
  closeFile(f);
end;

function OpenFile(var f: TBinaryFile; const filename: string;
                  mode: TFileMode = fmRead): Boolean;
begin
  AssignFile(f, filename);
  case mode of
    fmRead: Reset(f, 1);
    fmWrite: Rewrite(f, 1);
    fmReadWrite: Reset(f, 1);
    fmAppend: assert(false);
  end;
  result := (IOResult = 0);
end;

function ReadBytes(var f: tBinaryFile; out a: array of byte;
                   start, len: int): int;
begin
  result := 0;
  BlockRead(f, a[0], len, result)
end;

function ReadChars(var f: tBinaryFile; out a: array of char;
                   start, len: int): int;
begin
  result := 0;
  BlockRead(f, a[0], len, result)
end;

function readBuffer(var f: tBinaryFile; buffer: pointer; len: int): int;
begin
  result := 0;
  BlockRead(f, buffer^, len, result)
end;

procedure nimWrite(var f: tBinaryFile; const str: string); overload;
begin
  writeBuffer(f, addr(str[1]), length(str));
end;

function readLine(var f: tBinaryFile): string; overload;
var
  c: char;
begin
  result := '';
  while readBuffer(f, addr(c), 1) = 1 do begin
    case c of
      #13: begin
        readBuffer(f, addr(c), 1); // skip #10
        break;
      end;
      #10: break;
      else begin end
    end;
    addChar(result, c);
  end
end;

function readLine(var f: textFile): string; overload;
begin
  result := '';
  readln(f, result);
end;

function readBuffer(var f: tBinaryFile): string; overload;
const
  bufSize = 4096;
var
  bytesRead, len, cap: int;
begin
  // read the file in 4K chunks
  result := newString(bufSize);
  cap := bufSize;
  len := 0;
  while true do begin
    bytesRead := readBuffer(f, addr(result[len+1]), bufSize);
    inc(len, bytesRead);
    if bytesRead <> bufSize then break;
    inc(cap, bufSize);
    setLength(result, cap);
  end;
  setLength(result, len);
end;

function readFile(const filename: string): string;
var
  f: tBinaryFile;
begin
  if openFile(f, filename) then begin
    result := readBuffer(f);
    nimCloseFile(f)
  end
  else
    result := '';
end;

function writeBuffer(var f: TBinaryFile; buffer: pointer;
                     len: int): int;
begin
  result := 0;
  BlockWrite(f, buffer^, len, result);
end;

function getFilePos(var f: tBinaryFile): int;
begin
  result := filePos(f);
end;

procedure setFilePos(var f: tBinaryFile; pos: int64);
begin
  Seek(f, pos);
end;

{$ifdef I_on} {$undef I_on} {$I+} {$endif}

{$ifopt R+} {$R-,Q-} {$define R_on} {$endif}
var
  zero: float;
  Saved8087CW: Word;
  savedExcMask: TFPUExceptionMask;
initialization
{$ifdef cpu64}
  savedExcMask := SetExceptionMask([exInvalidOp,
	exDenormalized,
	exPrecision,
	exZeroDivide,
	exOverflow,
	exUnderflow
	]);
{$else}
  Saved8087CW := Default8087CW;
  Set8087CW($133f); // Disable all fpu exceptions
{$endif}
  zero := 0.0;
  NaN := 0.0 / zero;
  inf := 1.0 / zero;
  NegInf := -inf;
finalization
{$ifdef cpu64}
  SetExceptionMask(savedExcMask); // set back exception mask
{$else}
  Set8087CW(Saved8087CW);
{$endif}
{$ifdef R_on}
  {$R+,Q+}
{$endif}
end.
