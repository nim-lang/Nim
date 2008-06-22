//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit nimsets;

// this unit handles Morpork sets; it implements symbolic sets
// the code here should be reused in the Morpork standard library

interface

{$include 'config.inc'}

uses
  nsystem, ast, astalgo, trees, nversion, msgs, platform,
  bitsets, types, rnimsyn;

procedure toBitSet(s: PNode; out b: TBitSet);

// this function is used for case statement checking:
function overlap(a, b: PNode): Boolean;

function inSet(s: PNode; const elem: PNode): Boolean;
function someInSet(s: PNode; const a, b: PNode): Boolean;

function emptyRange(const a, b: PNode): Boolean;

function SetHasRange(s: PNode): Boolean;
// returns true if set contains a range (needed by the code generator)

// these are used for constant folding:
function unionSets(a, b: PNode): PNode;
function diffSets(a, b: PNode): PNode;
function intersectSets(a, b: PNode): PNode;
function symdiffSets(a, b: PNode): PNode;

function containsSets(a, b: PNode): Boolean;
function equalSets(a, b: PNode): Boolean;

function cardSet(s: PNode): BiggestInt;

implementation

function inSet(s: PNode; const elem: PNode): Boolean;
var
  i: int;
begin
  assert(s.kind in [nkSetConstr, nkConstSetConstr]);
  for i := 0 to sonsLen(s)-1 do
    if s.sons[i].kind = nkRange then begin
      if leValue(s.sons[i].sons[0], elem)
      and leValue(elem, s.sons[i].sons[1]) then begin
        result := true; exit
      end
    end
    else begin
      if sameValue(s.sons[i], elem) then begin
        result := true; exit
      end
    end;
  result := false
end;

function overlap(a, b: PNode): Boolean;
begin
  if a.kind = nkRange then begin
    if b.kind = nkRange then begin
      result := leValue(a.sons[0], b.sons[1]) 
           and leValue(b.sons[1], a.sons[1])  
         or leValue(a.sons[0], b.sons[0])     
           and leValue(b.sons[0], a.sons[1])  
    end
    else begin
      result := leValue(a.sons[0], b)
            and leValue(b, a.sons[1])
    end
  end
  else begin
    if b.kind = nkRange then begin
      result := leValue(b.sons[0], a)
            and leValue(a, b.sons[1])
    end
    else begin
      result := sameValue(a, b)
    end
  end
end;

function SomeInSet(s: PNode; const a, b: PNode): Boolean;
// checks if some element of a..b is in the set s
var
  i: int;
begin
  assert(s.kind in [nkSetConstr, nkConstSetConstr]);
  for i := 0 to sonsLen(s)-1 do
    if s.sons[i].kind = nkRange then begin
      if leValue(s.sons[i].sons[0], b)     
        and leValue(b, s.sons[i].sons[1])  
      or leValue(s.sons[i].sons[0], a)     
        and leValue(a, s.sons[i].sons[1]) then begin 
          result := true; exit
        end
    end
    else begin
      // a <= elem <= b
      if leValue(a, s.sons[i]) and leValue(s.sons[i], b) then begin
        result := true; exit
      end
    end;
  result := false
end;

procedure toBitSet(s: PNode; out b: TBitSet);
var
  i: int;
  first, j: BiggestInt;
begin
  first := firstOrd(s.typ.sons[0]);
  bitSetInit(b, int(getSize(s.typ)));
  for i := 0 to sonsLen(s)-1 do
    if s.sons[i].kind = nkRange then begin
      j := getOrdValue(s.sons[i].sons[0]);
      while j <= getOrdValue(s.sons[i].sons[1]) do begin
        BitSetIncl(b, j - first);
        inc(j)
      end
    end
    else
      BitSetIncl(b, getOrdValue(s.sons[i]) - first)
end;

function ToTreeSet(const s: TBitSet; settype: PType;
                   const info: TLineInfo): PNode;
var
  a, b, e, first: BiggestInt; // a, b are interval borders
  elemType: PType;
  n: PNode;
begin
  elemType := settype.sons[0];
  first := firstOrd(elemType);
  result := newNode(nkConstSetConstr);
  result.typ := settype;
  result.info := info;

  e := 0;
  while e < high(s)*elemSize do begin
    if bitSetIn(s, e) then begin
      a := e; b := e;
      repeat
        Inc(b);
      until (b > high(s)*elemSize) or not bitSetIn(s, b);
      Dec(b);
      if a = b then // a single element:
        addSon(result, newIntTypeNode(nkIntLit, a + first, elemType))
      else begin
        n := newNode(nkRange);
        n.typ := elemType;
        addSon(n, newIntTypeNode(nkIntLit, a + first, elemType));
        addSon(n, newIntTypeNode(nkIntLit, b + first, elemType));
        addSon(result, n);
      end;
      e := b
    end;
    Inc(e)
  end
end;

type
  TSetOP = (soUnion, soDiff, soSymDiff, soIntersect);

function nodeSetOp(a, b: PNode; op: TSetOp): PNode;
var
  x, y: TBitSet;
begin
  toBitSet(a, x);
  toBitSet(b, y);
  case op of
    soUnion:     BitSetUnion(x, y);
    soDiff:      BitSetDiff(x, y);
    soSymDiff:   BitSetSymDiff(x, y);
    soIntersect: BitSetIntersect(x, y);
  end;
  result := toTreeSet(x, a.typ, a.info);
end;

function unionSets(a, b: PNode): PNode;
begin
  result := nodeSetOp(a, b, soUnion);
end;

function diffSets(a, b: PNode): PNode;
begin
  result := nodeSetOp(a, b, soDiff);
end;

function intersectSets(a, b: PNode): PNode;
begin
  result := nodeSetOp(a, b, soIntersect)
end;

function symdiffSets(a, b: PNode): PNode;
begin
  result := nodeSetOp(a, b, soSymDiff);
end;

function containsSets(a, b: PNode): Boolean;
var
  x, y: TBitSet;
begin
  toBitSet(a, x);
  toBitSet(b, y);
  result := bitSetContains(x, y)
end;

function equalSets(a, b: PNode): Boolean;
var
  x, y: TBitSet;
begin
  toBitSet(a, x);
  toBitSet(b, y);
  result := bitSetEquals(x, y)
end;

function cardSet(s: PNode): BiggestInt;
var
  i: int;
begin
  // here we can do better than converting it into a compact set
  // we just count the elements directly
  result := 0;
  for i := 0 to sonsLen(s)-1 do
    if s.sons[i].kind = nkRange then
      result := result + getOrdValue(s.sons[i].sons[1]) -
                         getOrdValue(s.sons[i].sons[0]) + 1
    else
      Inc(result);
end;

function SetHasRange(s: PNode): Boolean;
var
  i: int;
begin
  assert(s.kind in [nkSetConstr, nkConstSetConstr]);
  for i := 0 to sonsLen(s)-1 do
    if s.sons[i].kind = nkRange then begin
      result := true; exit
    end;
  result := false
end;

function emptyRange(const a, b: PNode): Boolean;
begin
  result := not leValue(a, b) // a > b iff not (a <= b)
end;

end.
