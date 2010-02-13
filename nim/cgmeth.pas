//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit cgmeth;

// This module implements code generation for multi methods.
  
interface

{$include 'config.inc'}

uses
  sysutils, nsystem, 
  options, ast, astalgo, msgs, idents, rnimsyn, types, magicsys;

procedure methodDef(s: PSym);
function methodCall(n: PNode): PNode;
function generateMethodDispatchers(): PNode;

implementation

const
  skipPtrs = {@set}[tyVar, tyPtr, tyRef, tyGenericInst];

function genConv(n: PNode; d: PType; downcast: bool): PNode;
var
  dest, source: PType;
  diff: int;
begin
  dest := skipTypes(d, abstractPtrs);
  source := skipTypes(n.typ, abstractPtrs);
  if (source.kind = tyObject) and (dest.kind = tyObject) then begin
    diff := inheritanceDiff(dest, source);
    if diff = high(int) then InternalError(n.info, 'cgmeth.genConv');
    if diff < 0 then begin
      result := newNodeIT(nkObjUpConv, n.info, d);
      addSon(result, n);
      if downCast then
        InternalError(n.info, 'cgmeth.genConv: no upcast allowed');
    end
    else if diff > 0 then begin
      result := newNodeIT(nkObjDownConv, n.info, d);
      addSon(result, n);
      if not downCast then
        InternalError(n.info, 'cgmeth.genConv: no downcast allowed');
    end
    else result := n
  end
  else result := n
end;

function methodCall(n: PNode): PNode;
var
  disp: PSym;
  i: int;
begin
  result := n;
  disp := lastSon(result.sons[0].sym.ast).sym;
  result.sons[0].sym := disp;
  for i := 1 to sonsLen(result)-1 do
    result.sons[i] := genConv(result.sons[i], disp.typ.sons[i], true)
end;

var
  gMethods: array of TSymSeq;

function sameMethodBucket(a, b: PSym): bool;
var
  i: int;
  aa, bb: PType;
begin
  result := false;
  if a.name.id <> b.name.id then exit;
  if sonsLen(a.typ) <> sonsLen(b.typ) then exit;
  // check for return type:
  if not sameTypeOrNil(a.typ.sons[0], b.typ.sons[0]) then exit;
  for i := 1 to sonsLen(a.typ)-1 do begin
    aa := a.typ.sons[i];
    bb := b.typ.sons[i];
    while true do begin
      aa := skipTypes(aa, {@set}[tyGenericInst]);
      bb := skipTypes(bb, {@set}[tyGenericInst]);
      if (aa.kind = bb.kind) and (aa.kind in [tyVar, tyPtr, tyRef]) then begin
        aa := aa.sons[0];
        bb := bb.sons[0];
      end
      else
        break
    end;
    if sameType(aa, bb)
    or (aa.kind = tyObject) and (bb.kind = tyObject)
        and (inheritanceDiff(bb, aa) < 0) then begin end
    else exit;
  end;
  result := true
end;

procedure methodDef(s: PSym);
var
  i, L, q: int;
  disp: PSym;
begin 
  L := length(gMethods);
  for i := 0 to L-1 do begin
    if sameMethodBucket(gMethods[i][0], s) then begin
    {@ignore}
      q := length(gMethods[i]);
      setLength(gMethods[i], q+1);
      gMethods[i][q] := s;
    {@emit
      add(gMethods[i], s);
    }
      // store a symbol to the dispatcher:
      addSon(s.ast, lastSon(gMethods[i][0].ast));
      exit
    end
  end;
{@ignore}
  setLength(gMethods, L+1);
  setLength(gMethods[L], 1);
  gMethods[L][0] := s;
{@emit
  add(gMethods, @[s]);
}
  // create a new dispatcher:
  disp := copySym(s);
  disp.typ := copyType(disp.typ, disp.typ.owner, false);
  if disp.typ.callConv = ccInline then disp.typ.callConv := ccDefault;
  disp.ast := copyTree(s.ast);
  disp.ast.sons[codePos] := nil;
  if s.typ.sons[0] <> nil then
    disp.ast.sons[resultPos].sym := copySym(s.ast.sons[resultPos].sym);
  addSon(s.ast, newSymNode(disp));
end;

function relevantCol(methods: TSymSeq; col: int): bool;
var
  t: PType;
  i: int;
begin
  // returns true iff the position is relevant
  t := methods[0].typ.sons[col];
  result := false;
  if skipTypes(t, skipPtrs).kind = tyObject then 
    for i := 1 to high(methods) do
      if not SameType(methods[i].typ.sons[col], t) then begin
        result := true; exit
      end
end;

function cmpSignatures(a, b: PSym; const relevantCols: TIntSet): int;
var
  col, d: int;
  aa, bb: PType;
begin
  result := 0;
  for col := 1 to sonsLen(a.typ)-1 do
    if intSetContains(relevantCols, col) then begin
      aa := skipTypes(a.typ.sons[col], skipPtrs);
      bb := skipTypes(b.typ.sons[col], skipPtrs);
      d := inheritanceDiff(aa, bb);
      if (d <> high(int)) then begin
        result := d; exit
      end
    end
end;

procedure sortBucket(var a: TSymSeq; const relevantCols: TIntSet);
// we use shellsort here; fast and simple
var
  N, i, j, h: int;
  v: PSym;
begin
  N := length(a);
  h := 1; repeat h := 3*h+1; until h > N;
  repeat
    h := h div 3;
    for i := h to N-1 do begin
      v := a[i]; j := i;
      while cmpSignatures(a[j-h], v, relevantCols) >= 0 do begin
        a[j] := a[j-h]; j := j - h;
        if j < h then break
      end;
      a[j] := v;
    end;
  until h = 1
end;

function genDispatcher(methods: TSymSeq; const relevantCols: TIntSet): PSym;
var
  disp, cond, call, ret, a, isn: PNode;
  base, curr, ands, iss: PSym;
  meth, col, paramLen: int;
begin
  base := lastSon(methods[0].ast).sym;
  result := base;
  paramLen := sonsLen(base.typ);
  disp := newNodeI(nkIfStmt, base.info);
  ands := getSysSym('and');
  iss := getSysSym('is');
  for meth := 0 to high(methods) do begin
    curr := methods[meth];
    // generate condition:
    cond := nil;
    for col := 1 to paramLen-1 do begin
      if IntSetContains(relevantCols, col) then begin
        isn := newNodeIT(nkCall, base.info, getSysType(tyBool));
        addSon(isn, newSymNode(iss));
        addSon(isn, newSymNode(base.typ.n.sons[col].sym));
        addSon(isn, newNodeIT(nkType, base.info, curr.typ.sons[col]));
        if cond <> nil then begin
          a := newNodeIT(nkCall, base.info, getSysType(tyBool));
          addSon(a, newSymNode(ands));
          addSon(a, cond);
          addSon(a, isn);
          cond := a
        end
        else
          cond := isn
      end
    end;
    // generate action:
    call := newNodeI(nkCall, base.info);
    addSon(call, newSymNode(curr));
    for col := 1 to paramLen-1 do begin
      addSon(call, genConv(newSymNode(base.typ.n.sons[col].sym),
                           curr.typ.sons[col], false));
    end;
    if base.typ.sons[0] <> nil then begin
      a := newNodeI(nkAsgn, base.info);
      addSon(a, newSymNode(base.ast.sons[resultPos].sym));
      addSon(a, call);
      ret := newNodeI(nkReturnStmt, base.info);
      addSon(ret, a);
    end
    else
      ret := call;
    a := newNodeI(nkElifBranch, base.info);
    addSon(a, cond);
    addSon(a, ret);
    addSon(disp, a);
  end;
  result.ast.sons[codePos] := disp;
end;

function generateMethodDispatchers(): PNode;
var
  bucket, col: int;
  relevantCols: TIntSet;
begin
  result := newNode(nkStmtList);
  for bucket := 0 to length(gMethods)-1 do begin
    IntSetInit(relevantCols);
    for col := 1 to sonsLen(gMethods[bucket][0].typ)-1 do
      if relevantCol(gMethods[bucket], col) then IntSetIncl(relevantCols, col);
    sortBucket(gMethods[bucket], relevantCols);
    addSon(result, newSymNode(genDispatcher(gMethods[bucket], relevantCols)));
  end
end;

initialization
  {@emit gMethods := @[]; }
end.
