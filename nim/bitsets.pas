//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit bitsets;

// this unit handles Nimrod sets; it implements symbolic sets
// the code here should be reused in the Nimrod standard library

interface

{$include 'config.inc'}

{@ignore}
uses
  nsystem;
{@emit}

type
  TBitSet = array of Byte; // we use byte here to avoid issues with
                           // cross-compiling; uint would be more efficient
                           // however

const
  ElemSize = sizeof(Byte) * 8;

procedure BitSetInit(out b: TBitSet; len: int);
procedure BitSetUnion(var x: TBitSet; const y: TBitSet);
procedure BitSetDiff(var x: TBitSet; const y: TBitSet);
procedure BitSetSymDiff(var x: TBitSet; const y: TBitSet);
procedure BitSetIntersect(var x: TBitSet; const y: TBitSet);
procedure BitSetIncl(var x: TBitSet; const elem: BiggestInt);
procedure BitSetExcl(var x: TBitSet; const elem: BiggestInt);

function BitSetIn(const x: TBitSet; const e: BiggestInt): Boolean;
function BitSetEquals(const x, y: TBitSet): Boolean;
function BitSetContains(const x, y: TBitSet): Boolean;

implementation

function BitSetIn(const x: TBitSet; const e: BiggestInt): Boolean;
begin
  result := (x[int(e div ElemSize)] and (1 shl (e mod ElemSize))) <> 0
end;

procedure BitSetIncl(var x: TBitSet; const elem: BiggestInt);
begin
  assert(elem >= 0);
  x[int(elem div ElemSize)] := toU8(x[int(elem div ElemSize)] or 
    int(1 shl (elem mod ElemSize)))
end;

procedure BitSetExcl(var x: TBitSet; const elem: BiggestInt);
begin
  x[int(elem div ElemSize)] := toU8(x[int(elem div ElemSize)] and
                          not int(1 shl (elem mod ElemSize)))
end;

procedure BitSetInit(out b: TBitSet; len: int);
begin
  {@emit b := [];}
  setLength(b, len);
{@ignore}
  fillChar(b[0], length(b)*sizeof(b[0]), 0);
{@emit}
end;

procedure BitSetUnion(var x: TBitSet; const y: TBitSet);
var
  i: int;
begin
  for i := 0 to high(x) do x[i] := toU8(x[i] or int(y[i]))
end;

procedure BitSetDiff(var x: TBitSet; const y: TBitSet);
var
  i: int;
begin
  for i := 0 to high(x) do x[i] := toU8(x[i] and not int(y[i]))
end;

procedure BitSetSymDiff(var x: TBitSet; const y: TBitSet);
var
  i: int;
begin
  for i := 0 to high(x) do x[i] := toU8(x[i] xor int(y[i]))
end;

procedure BitSetIntersect(var x: TBitSet; const y: TBitSet);
var
  i: int;
begin
  for i := 0 to high(x) do x[i] := toU8(x[i] and int(y[i]))
end;

function BitSetEquals(const x, y: TBitSet): Boolean;
var
  i: int;
begin
  for i := 0 to high(x) do
    if (x[i] <> int(y[i])) then begin
      result := false; exit;
    end;
  result := true
end;

function BitSetContains(const x, y: TBitSet): Boolean;
var
  i: int;
begin
  for i := 0 to high(x) do
    if (x[i] and not int(y[i])) <> 0 then begin
      result := false; exit;
    end;
  result := true
end;

end.
