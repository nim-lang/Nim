//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit debugids;

interface

{$include 'config.inc'}

uses
  nsystem, nos, strutils, ast;

const
  idfile = 'debugids.txt';

// This module implements debugging facilities for the ID mechanism.
procedure registerID(s: PSym);

procedure writeIDTable();
procedure loadIDTable();

implementation

type
  TIdSymTuple = record{@tuple} // keep id from sym to better detect bugs
    id: int;
    s: PSym;
  end;
  TIdSymTupleSeq = array of TIdSymTuple;
  TIdSymTable = record
    counter: int;
    data: TIdSymTupleSeq;
  end;

function TableRawGet(const t: TTable; key: PObject): int;
var
  h: THash;
begin
  h := hashNode(key) and high(t.data); // start with real hash value
  while t.data[h].key <> nil do begin
    if (t.data[h].key = key) then begin
      result := h; exit
    end;
    h := nextTry(h, high(t.data))
  end;
  result := -1
end;

function TableSearch(const t: TTable; key, closure: PObject;
                     comparator: TCmpProc): PObject;
var
  h: THash;
begin
  h := hashNode(key) and high(t.data); // start with real hash value
  while t.data[h].key <> nil do begin
    if (t.data[h].key = key) then
      if comparator(t.data[h].val, closure) then begin // BUGFIX 1
        result := t.data[h].val; exit
      end;
    h := nextTry(h, high(t.data))
  end;
  result := nil
end;

function TableGet(const t: TTable; key: PObject): PObject;
var
  index: int;
begin
  index := TableRawGet(t, key);
  if index >= 0 then result := t.data[index].val
  else result := nil
end;

procedure TableRawInsert(var data: TPairSeq; key, val: PObject);
var
  h: THash;
begin
  h := HashNode(key) and high(data);
  while data[h].key <> nil do begin
    assert(data[h].key <> key);
    h := nextTry(h, high(data))
  end;
  assert(data[h].key = nil);
  data[h].key := key;
  data[h].val := val;
end;

procedure TableEnlarge(var t: TTable);
var
  n: TPairSeq;
  i: int;
begin
{@ignore}
  n := emptySeq;
  setLength(n, length(t.data) * growthFactor);
  fillChar(n[0], length(n)*sizeof(n[0]), 0);
{@emit
  newSeq(n, length(t.data) * growthFactor); }
  for i := 0 to high(t.data) do
    if t.data[i].key <> nil then
      TableRawInsert(n, t.data[i].key, t.data[i].val);
{@ignore}
  t.data := n;
{@emit
  swap(t.data, n);
}
end;

procedure TablePut(var t: TTable; key, val: PObject);
var
  index: int;
begin
  index := TableRawGet(t, key);
  if index >= 0 then
    t.data[index].val := val
  else begin
    if mustRehash(length(t.data), t.counter) then TableEnlarge(t);
    TableRawInsert(t.data, key, val);
    inc(t.counter)
  end;
end;


end.
