//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit treetab;

// Implements a table from trees to trees. Does structural equavilent checking.

interface

{$include 'config.inc'}

uses
  nsystem, nhashes, ast, astalgo, types;

function NodeTableGet(const t: TNodeTable; key: PNode): int;
procedure NodeTablePut(var t: TNodeTable; key: PNode; val: int);

function NodeTableTestOrSet(var t: TNodeTable; key: PNode; val: int): int;

implementation

function hashTree(n: PNode): THash;
var
  i: int;
begin
  result := 0;
  if n = nil then exit;
  result := ord(n.kind);
  case n.kind of
    nkEmpty, nkNilLit, nkType: begin end;
    nkIdent: result := concHash(result, n.ident.h);
    nkSym: result := concHash(result, n.sym.name.h);
    nkCharLit..nkInt64Lit: begin
      if (n.intVal >= low(int)) and (n.intVal <= high(int)) then
        result := concHash(result, int(n.intVal));
    end;
    nkFloatLit..nkFloat64Lit: begin
      if (n.floatVal >= -1000000.0) and (n.floatVal <= 1000000.0) then
        result := concHash(result, toInt(n.floatVal));
    end;
    nkStrLit..nkTripleStrLit:
      result := concHash(result, GetHashStr(n.strVal));
    else begin
      for i := 0 to sonsLen(n)-1 do
        result := concHash(result, hashTree(n.sons[i]));
    end
  end
end;

function TreesEquivalent(a, b: PNode): Boolean;
var
  i: int;
begin
  result := false;
  if a = b then begin
    result := true
  end
  else if (a <> nil) and (b <> nil) and (a.kind = b.kind) then begin
    case a.kind of
      nkEmpty, nkNilLit, nkType: result := true;
      nkSym:
        result := a.sym.id = b.sym.id;
      nkIdent:
        result := a.ident.id = b.ident.id;
      nkCharLit..nkInt64Lit:
        result := a.intVal = b.intVal;
      nkFloatLit..nkFloat64Lit:
        result := a.floatVal = b.floatVal;
      nkStrLit..nkTripleStrLit:
        result := a.strVal = b.strVal;
      else if sonsLen(a) = sonsLen(b) then begin
        for i := 0 to sonsLen(a)-1 do
          if not TreesEquivalent(a.sons[i], b.sons[i]) then exit;
        result := true
      end
    end;
    if result then result := sameTypeOrNil(a.typ, b.typ);
  end
end;

function NodeTableRawGet(const t: TNodeTable; k: THash; key: PNode): int;
var
  h: THash;
begin
  h := k and high(t.data);
  while t.data[h].key <> nil do begin
    if (t.data[h].h = k) and TreesEquivalent(t.data[h].key, key) then begin
      result := h; exit
    end;
    h := nextTry(h, high(t.data))
  end;
  result := -1
end;

function NodeTableGet(const t: TNodeTable; key: PNode): int;
var
  index: int;
begin
  index := NodeTableRawGet(t, hashTree(key), key);
  if index >= 0 then result := t.data[index].val
  else result := low(int)
end;

procedure NodeTableRawInsert(var data: TNodePairSeq; k: THash;
                             key: PNode; val: int);
var
  h: THash;
begin
  h := k and high(data);
  while data[h].key <> nil do h := nextTry(h, high(data));
  assert(data[h].key = nil);
  data[h].h := k;
  data[h].key := key;
  data[h].val := val;
end;

procedure NodeTablePut(var t: TNodeTable; key: PNode; val: int);
var
  index, i: int;
  n: TNodePairSeq;
  k: THash;
begin
  k := hashTree(key);
  index := NodeTableRawGet(t, k, key);
  if index >= 0 then begin
    assert(t.data[index].key <> nil);
    t.data[index].val := val
  end
  else begin
    if mustRehash(length(t.data), t.counter) then begin
    {@ignore}
      setLength(n, length(t.data) * growthFactor);
      fillChar(n[0], length(n)*sizeof(n[0]), 0);
    {@emit
      newSeq(n, length(t.data) * growthFactor); }
      for i := 0 to high(t.data) do
        if t.data[i].key <> nil then
          NodeTableRawInsert(n, t.data[i].h, t.data[i].key, t.data[i].val);
    {@ignore}
      t.data := n;
    {@emit
      swap(t.data, n);
    }
    end;
    NodeTableRawInsert(t.data, k, key, val);
    inc(t.counter)
  end;
end;

function NodeTableTestOrSet(var t: TNodeTable; key: PNode; val: int): int;
var
  index, i: int;
  n: TNodePairSeq;
  k: THash;
begin
  k := hashTree(key);
  index := NodeTableRawGet(t, k, key);
  if index >= 0 then begin
    assert(t.data[index].key <> nil);
    result := t.data[index].val
  end
  else begin
    if mustRehash(length(t.data), t.counter) then begin
    {@ignore}
      setLength(n, length(t.data) * growthFactor);
      fillChar(n[0], length(n)*sizeof(n[0]), 0);
    {@emit
      newSeq(n, length(t.data) * growthFactor); }
      for i := 0 to high(t.data) do
        if t.data[i].key <> nil then
          NodeTableRawInsert(n, t.data[i].h, t.data[i].key, t.data[i].val);
    {@ignore}
      t.data := n;
    {@emit
      swap(t.data, n);
    }
    end;
    NodeTableRawInsert(t.data, k, key, val);
    result := val;
    inc(t.counter)
  end;
end;

end.
