//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit nhashes;

{$include 'config.inc'}

interface

uses
  charsets, nsystem, strutils;

const
  SmallestSize = (1 shl 3) - 1;
  DefaultSize = (1 shl 11) - 1;
  BiggestSize = (1 shl 28) - 1;

type
  THash = type int;
  PHash = ^THash;
  THashFunc = function (str: PChar): THash;

function GetHash(str: PChar): THash;
function GetHashCI(str: PChar): THash;

function GetDataHash(Data: Pointer; Size: int): THash;

function hashPtr(p: Pointer): THash;

function GetHashStr(const s: string): THash;
function GetHashStrCI(const s: string): THash;

function getNormalizedHash(const s: string): THash;

//function nextPowerOfTwo(x: int): int;

function concHash(h: THash; val: int): THash;
function finishHash(h: THash): THash;

implementation

{@ignore}
{$ifopt Q+} { we need Q- here! }
  {$define Q_on}
  {$Q-}
{$endif}

{$ifopt R+}
  {$define R_on}
  {$R-}
{$endif}
{@emit}

function nextPowerOfTwo(x: int): int;
begin
  result := x -{%} 1;
  // complicated, to make it a nop if sizeof(int) == 4,
  // because shifting more than 31 bits is undefined in C
  result := result or (result shr ((sizeof(int)-4)* 8));
  result := result or (result shr 16);
  result := result or (result shr 8);
  result := result or (result shr 4);
  result := result or (result shr 2);
  result := result or (result shr 1);
  Inc(result)
end;

function concHash(h: THash; val: int): THash;
begin
  result := h +{%} val;
  result := result +{%} result shl 10;
  result := result xor (result shr 6);
end;

function finishHash(h: THash): THash;
begin
  result := h +{%} h shl 3;
  result := result xor (result shr 11);
  result := result +{%} result shl 15;
end;

function GetDataHash(Data: Pointer; Size: int): THash;
var
  h: THash;
  p: PChar;
  i, s: int;
begin
  h := 0;
  p := {@cast}pchar(Data);
  i := 0;
  s := size;
  while s > 0 do begin
    h := h +{%} ord(p[i]);
    h := h +{%} h shl 10;
    h := h xor (h shr 6);
    Inc(i); Dec(s)
  end;
  h := h +{%} h shl 3;
  h := h xor (h shr 11);
  h := h +{%} h shl 15;
  result := THash(h)
end;

function hashPtr(p: Pointer): THash;
begin
  result := ({@cast}THash(p)) shr 3; // skip the alignment
end;

function GetHash(str: PChar): THash;
var
  h: THash;
  i: int;
begin
  h := 0;
  i := 0;
  while str[i] <> #0 do begin
    h := h +{%} ord(str[i]);
    h := h +{%} h shl 10;
    h := h xor (h shr 6);
    Inc(i)
  end;
  h := h +{%} h shl 3;
  h := h xor (h shr 11);
  h := h +{%} h shl 15;
  result := THash(h)
end;

function GetHashStr(const s: string): THash;
var
  h: THash;
  i: int;
begin
  h := 0;
  for i := 1 to Length(s) do begin
    h := h +{%} ord(s[i]);
    h := h +{%} h shl 10;
    h := h xor (h shr 6);
  end;
  h := h +{%} h shl 3;
  h := h xor (h shr 11);
  h := h +{%} h shl 15;
  result := THash(h)
end;

function getNormalizedHash(const s: string): THash;
var
  h: THash;
  c: Char;
  i: int;
begin
  h := 0;
  for i := strStart to length(s)+strStart-1 do begin
    c := s[i];
    if c = '_' then continue; // skip _
    if c in ['A'..'Z'] then c := chr(ord(c) + (ord('a')-ord('A'))); // toLower()
    h := h +{%} ord(c);
    h := h +{%} h shl 10;
    h := h xor (h shr 6);
  end;
  h := h +{%} h shl 3;
  h := h xor (h shr 11);
  h := h +{%} h shl 15;
  result := THash(h)
end;

function GetHashStrCI(const s: string): THash;
var
  h: THash;
  c: Char;
  i: int;
begin
  h := 0;
  for i := strStart to length(s)+strStart-1 do begin
    c := s[i];
    if c in ['A'..'Z'] then c := chr(ord(c) + (ord('a')-ord('A'))); // toLower()
    h := h +{%} ord(c);
    h := h +{%} h shl 10;
    h := h xor (h shr 6);
  end;
  h := h +{%} h shl 3;
  h := h xor (h shr 11);
  h := h +{%} h shl 15;
  result := THash(h)
end;

function GetHashCI(str: PChar): THash;
var
  h: THash;
  c: Char;
  i: int;
begin
  h := 0;
  i := 0;
  while str[i] <> #0 do begin
    c := str[i];
    if c in ['A'..'Z'] then c := chr(ord(c) + (ord('a')-ord('A'))); // toLower()
    h := h +{%} ord(c);
    h := h +{%} h shl 10;
    h := h xor (h shr 6);
    Inc(i)
  end;
  h := h +{%} h shl 3;
  h := h xor (h shr 11);
  h := h +{%} h shl 15;
  result := THash(h)
end;

{@ignore}
{$ifdef Q_on}
  {$undef Q_on}
  {$Q+}
{$endif}

{$ifdef R_on}
  {$undef R_on}
  {$R+}
{$endif}
{@emit}

end.
