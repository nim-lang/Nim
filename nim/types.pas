//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit types;

// this module contains routines for accessing and iterating over types

interface

{$include 'config.inc'}

uses
  nsystem, ast, astalgo, trees, msgs, strutils, platform;

function firstOrd(t: PType): biggestInt;
function lastOrd(t: PType): biggestInt;
function lengthOrd(t: PType): biggestInt;

type
  TPreferedDesc = (preferName, preferDesc);
function TypeToString(typ: PType; prefer: TPreferedDesc = preferName): string;
function getProcHeader(sym: PSym): string;

function base(t: PType): PType;


// ------------------- type iterator: ----------------------------------------
type
  TTypeIter = function (t: PType; closure: PObject): bool;
    // should return true if the iteration should stop

  TTypeMutator = function (t: PType; closure: PObject): PType;
    // copy t and mutate it

  TTypePredicate = function (t: PType): bool;

function IterOverType(t: PType; iter: TTypeIter; closure: PObject): bool;
// Returns result of `iter`.

function mutateType(t: PType; iter: TTypeMutator; closure: PObject): PType;
// Returns result of `iter`.



function SameType(x, y: PType): Boolean;
function SameTypeOrNil(a, b: PType): Boolean;

type
  TParamsEquality = (paramsNotEqual,      // parameters are not equal
                     paramsEqual,         // parameters are equal
                     paramsIncompatible); // they are equal, but their
                                          // identifiers or their return
                                          // type differ (i.e. they cannot be
                                          // overloaded)
  // this used to provide better error messages
function equalParams(a, b: PNode): TParamsEquality;
// returns whether the parameter lists of the procs a, b are exactly the same


function isOrdinalType(t: PType): Boolean;
function enumHasWholes(t: PType): Boolean;

function skipRange(t: PType): PType;
function skipGeneric(t: PType): PType;
function skipGenericRange(t: PType): PType;
function skipVar(t: PType): PType;
function skipVarGeneric(t: PType): PType;
function skipVarGenericRange(t: PType): PType;
function skipPtrsGeneric(t: PType): PType;

function elemType(t: PType): PType;

function containsObject(t: PType): bool;
function containsGarbageCollectedRef(typ: PType): Boolean;
function containsHiddenPointer(typ: PType): Boolean;

function isCompatibleToCString(a: PType): bool;

function getOrdValue(n: PNode): biggestInt;


function computeSize(typ: PType): biggestInt;
function getSize(typ: PType): biggestInt;

function isPureObject(typ: PType): boolean;

function inheritanceDiff(a, b: PType): int;
// | returns: 0 iff `a` == `b`
// | returns: -x iff `a` is the x'th direct superclass of `b`
// | returns: +x iff `a` is the x'th direct subclass of `b`
// | returns: `maxint` iff `a` and `b` are not compatible at all


function InvalidGenericInst(f: PType): bool;
// for debugging

implementation

function InvalidGenericInst(f: PType): bool;
begin
  result := (f.kind = tyGenericInst) and (lastSon(f) = nil);
end;

function inheritanceDiff(a, b: PType): int;
var
  x, y: PType;
begin
  // conversion to superclass?
  x := a;
  result := 0;
  while (x <> nil) do begin
    if x.id = b.id then exit;
    x := x.sons[0];
    dec(result);
  end;
  // conversion to baseclass?
  y := b;
  result := 0;
  while (y <> nil) do begin
    if y.id = a.id then exit;
    y := y.sons[0];
    inc(result);
  end;
  result := high(int);
end;

function isPureObject(typ: PType): boolean;
var
  t: PType;
begin
  t := typ;
  while t.sons[0] <> nil do t := t.sons[0];
  result := (t.sym <> nil) and (sfPure in t.sym.flags);
end;

function getOrdValue(n: PNode): biggestInt;
begin
  case n.kind of
    nkCharLit..nkInt64Lit: result := n.intVal;
    nkNilLit: result := 0;
    else begin
      liMessage(n.info, errOrdinalTypeExpected);
      result := 0
    end
  end
end;

function isCompatibleToCString(a: PType): bool;
begin
  result := false;
  if a.kind = tyArray then
    if (firstOrd(a.sons[0]) = 0)
    and (skipRange(a.sons[0]).kind in [tyInt..tyInt64])
    and (a.sons[1].kind = tyChar) then
      result := true
end;

function getProcHeader(sym: PSym): string;
var
  i: int;
  n, p: PNode;
begin
  result := sym.name.s + '(';
  n := sym.typ.n;
  for i := 1 to sonsLen(n)-1 do begin
    p := n.sons[i];
    assert(p.kind = nkSym);
    result := result +{&} p.sym.name.s +{&} ': ' +{&} typeToString(p.sym.typ);
    if i <> sonsLen(n)-1 then result := result + ', ';
  end;
  result := result + ')';
  if n.sons[0].typ <> nil then
    result := result +{&} ': ' +{&} typeToString(n.sons[0].typ);
end;

function elemType(t: PType): PType;
begin
  assert(t <> nil);
  case t.kind of
    tyGenericInst: result := elemType(lastSon(t));
    tyArray, tyArrayConstr: result := t.sons[1];
    else result := t.sons[0];
  end;
  assert(result <> nil);
end;

function skipGeneric(t: PType): PType;
begin
  result := t;
  while result.kind = tyGenericInst do result := lastSon(result)
end;

function skipRange(t: PType): PType;
begin
  result := t;
  while result.kind = tyRange do result := base(result)
end;

function skipAbstract(t: PType): PType;
begin
  result := t;
  while result.kind in [tyRange, tyGenericInst] do
    result := lastSon(result);
end;

function skipVar(t: PType): PType;
begin
  result := t;
  while result.kind = tyVar do result := result.sons[0];
end;

function skipVarGeneric(t: PType): PType;
begin
  result := t;
  while result.kind in [tyGenericInst, tyVar] do result := lastSon(result);
end;

function skipPtrsGeneric(t: PType): PType;
begin
  result := t;
  while result.kind in [tyGenericInst, tyVar, tyPtr, tyRef] do
    result := lastSon(result);
end;

function skipVarGenericRange(t: PType): PType;
begin
  result := t;
  while result.kind in [tyGenericInst, tyVar, tyRange] do
    result := lastSon(result);
end;

function skipGenericRange(t: PType): PType;
begin
  result := t;
  while result.kind in [tyGenericInst, tyVar, tyRange] do
    result := lastSon(result);
end;

function isOrdinalType(t: PType): Boolean;
begin
  assert(t <> nil);
  result := (t.Kind in [tyChar, tyInt..tyInt64, tyBool, tyEnum])
    or (t.Kind = tyRange) and isOrdinalType(t.sons[0]);
end;

function enumHasWholes(t: PType): Boolean;
var
  b: PType;
begin
  b := t;
  while b.kind = tyRange do b := b.sons[0];
  result := (b.Kind = tyEnum) and (tfEnumHasWholes in b.flags)
end;

function iterOverTypeAux(var marker: TIntSet; t: PType; iter: TTypeIter;
                         closure: PObject): bool; forward;

function iterOverNode(var marker: TIntSet; n: PNode; iter: TTypeIter;
                      closure: PObject): bool;
var
  i: int;
begin
  result := false;
  if n <> nil then begin
    case n.kind of
      nkNone..nkNilLit: begin // a leaf
        result := iterOverTypeAux(marker, n.typ, iter, closure);
      end;
      else begin
        for i := 0 to sonsLen(n)-1 do begin
          result := iterOverNode(marker, n.sons[i], iter, closure);
          if result then exit;
        end
      end
    end
  end
end;

function iterOverTypeAux(var marker: TIntSet; t: PType; iter: TTypeIter;
                         closure: PObject): bool;
var
  i: int;
begin
  result := false;
  if t = nil then exit;
  result := iter(t, closure);
  if result then exit;
  if not IntSetContainsOrIncl(marker, t.id) then begin
    for i := 0 to sonsLen(t)-1 do begin
      result := iterOverTypeAux(marker, t.sons[i], iter, closure);
      if result then exit;
    end;
    if t.n <> nil then
      result := iterOverNode(marker, t.n, iter, closure)
  end
end;

function IterOverType(t: PType; iter: TTypeIter; closure: PObject): bool;
var
  marker: TIntSet;
begin
  IntSetInit(marker);
  result := iterOverTypeAux(marker, t, iter, closure);
end;

function searchTypeForAux(t: PType; predicate: TTypePredicate;
                          var marker: TIntSet): bool; forward;

function searchTypeNodeForAux(n: PNode; p: TTypePredicate;
                              var marker: TIntSet): bool;
var
  i: int;
begin
  result := false;
  case n.kind of
    nkRecList: begin
      for i := 0 to sonsLen(n)-1 do begin
        result := searchTypeNodeForAux(n.sons[i], p, marker);
        if result then exit
      end
    end;
    nkRecCase: begin
      assert(n.sons[0].kind = nkSym);
      result := searchTypeNodeForAux(n.sons[0], p, marker);
      if result then exit;
      for i := 1 to sonsLen(n)-1 do begin
        case n.sons[i].kind of
          nkOfBranch, nkElse: begin
            result := searchTypeNodeForAux(lastSon(n.sons[i]), p, marker);
            if result then exit;
          end;
          else internalError('searchTypeNodeForAux(record case branch)');
        end
      end
    end;
    nkSym: begin
      result := searchTypeForAux(n.sym.typ, p, marker);
    end;
    else internalError(n.info, 'searchTypeNodeForAux()');
  end;
end;

function searchTypeForAux(t: PType; predicate: TTypePredicate;
                          var marker: TIntSet): bool;
// iterates over VALUE types!
var
  i: int;
begin
  result := false;
  if t = nil then exit;
  if IntSetContainsOrIncl(marker, t.id) then exit;
  result := Predicate(t);
  if result then exit;
  case t.kind of
    tyObject: begin
      result := searchTypeForAux(t.sons[0], predicate, marker);
      if not result then
        result := searchTypeNodeForAux(t.n, predicate, marker);
    end;
    tyGenericInst: result := searchTypeForAux(lastSon(t), predicate, marker);
    tyArray, tyArrayConstr, tySet, tyTuple: begin
      for i := 0 to sonsLen(t)-1 do begin
        result := searchTypeForAux(t.sons[i], predicate, marker);
        if result then exit
      end
    end
    else begin end
  end
end;

function searchTypeFor(t: PType; predicate: TTypePredicate): bool;
var
  marker: TIntSet;
begin
  IntSetInit(marker);
  result := searchTypeForAux(t, predicate, marker);
end;

function isObjectPredicate(t: PType): bool;
begin
  result := t.kind = tyObject
end;

function containsObject(t: PType): bool;
begin
  result := searchTypeFor(t, isObjectPredicate);
end;

function isGBCRef(t: PType): bool;
begin
  result := t.kind in [tyRef, tySequence, tyString];
end;

function containsGarbageCollectedRef(typ: PType): Boolean;
// returns true if typ contains a reference, sequence or string (all the things
// that are garbage-collected)
begin
  result := searchTypeFor(typ, isGBCRef);
end;

function isHiddenPointer(t: PType): bool;
begin
  result := t.kind in [tyString, tySequence];
end;

function containsHiddenPointer(typ: PType): Boolean;
// returns true if typ contains a string, table or sequence (all the things
// that need to be copied deeply)
begin
  result := searchTypeFor(typ, isHiddenPointer);
end;

function mutateTypeAux(var marker: TIntSet; t: PType; iter: TTypeMutator;
                       closure: PObject): PType; forward;

function mutateNode(var marker: TIntSet; n: PNode; iter: TTypeMutator;
                    closure: PObject): PNode;
var
  i: int;
begin
  result := nil;
  if n <> nil then begin
    result := copyNode(n);
    result.typ := mutateTypeAux(marker, n.typ, iter, closure);
    case n.kind of
      nkNone..nkNilLit: begin // a leaf
      end;
      else begin
        for i := 0 to sonsLen(n)-1 do
          addSon(result, mutateNode(marker, n.sons[i], iter, closure));
      end
    end
  end
end;

function mutateTypeAux(var marker: TIntSet; t: PType; iter: TTypeMutator;
                       closure: PObject): PType;
var
  i: int;
begin
  result := nil;
  if t = nil then exit;
  result := iter(t, closure);
  if not IntSetContainsOrIncl(marker, t.id) then begin
    for i := 0 to sonsLen(t)-1 do begin
      result.sons[i] := mutateTypeAux(marker, result.sons[i], iter, closure);
      if (result.sons[i] = nil) and (result.kind = tyGenericInst) then
        assert(false);
    end;
    if t.n <> nil then
      result.n := mutateNode(marker, t.n, iter, closure)
  end;
  assert(result <> nil);
end;

function mutateType(t: PType; iter: TTypeMutator; closure: PObject): PType;
var
  marker: TIntSet;
begin
  IntSetInit(marker);
  result := mutateTypeAux(marker, t, iter, closure);
end;

function rangeToStr(n: PNode): string;
begin
  assert(n.kind = nkRange);
  result := ValueToString(n.sons[0]) + '..' +{&} ValueToString(n.sons[1])
end;

function TypeToString(typ: PType; prefer: TPreferedDesc = preferName): string;
const
  typeToStr: array [TTypeKind] of string = (
    'None', 'bool', 'Char', '{}', 'Array Constructor [$1]', 'nil',
    'Generic', 'GenericInst', 'GenericParam',
    'enum', 'anyenum',
    'array[$1, $2]', 'object', 'tuple', 'set[$1]', 'range[$1]',
    'ptr ', 'ref ', 'var ', 'seq[$1]', 'proc', 'pointer',
    'OpenArray[$1]', 'string', 'CString', 'Forward',
    'int', 'int8', 'int16', 'int32', 'int64',
    'float', 'float32', 'float64', 'float128'
  );
var
  t: PType;
  i: int;
begin
  t := typ;
  result := '';
  if t = nil then exit;
  if (prefer = preferName) and (t.sym <> nil) then begin
    result := t.sym.Name.s;
    exit
  end;
  case t.Kind of
    tyGenericInst:
      result := typeToString(lastSon(t), prefer);
    tyArray: begin
      if t.sons[0].kind = tyRange then
        result := 'array[' +{&} rangeToStr(t.sons[0].n) +{&} ', '
                  +{&} typeToString(t.sons[1]) +{&} ']'
      else
        result := 'array[' +{&} typeToString(t.sons[0]) +{&} ', '
                  +{&} typeToString(t.sons[1]) +{&} ']'
    end;
    tyArrayConstr:
      result := 'Array constructor[' +{&} rangeToStr(t.sons[0].n) +{&} ', '
                +{&} typeToString(t.sons[1]) +{&} ']';
    tySequence: result := 'seq[' +{&} typeToString(t.sons[0]) +{&} ']';
    tySet: result := 'set[' +{&} typeToString(t.sons[0]) +{&} ']';
    tyOpenArray: result := 'openarray[' +{&} typeToString(t.sons[0]) +{&} ']';
    tyTuple: begin
      // we iterate over t.sons here, because t.n may be nil
      result := 'tuple[';
      if t.n <> nil then begin
        assert(sonsLen(t.n) = sonsLen(t));
        for i := 0 to sonsLen(t.n)-1 do begin
          assert(t.n.sons[i].kind = nkSym);
          result := result +{&} t.n.sons[i].sym.name.s +{&} ': '
                  +{&} typeToString(t.sons[i]);
          if i < sonsLen(t.n)-1 then result := result +{&} ', ';
        end
      end
      else begin
        for i := 0 to sonsLen(t)-1 do begin
          result := result +{&} typeToString(t.sons[i]);
          if i < sonsLen(t)-1 then result := result +{&} ', ';
        end
      end;
      addChar(result, ']')
    end;
    tyPtr, tyRef, tyVar:
      result := typeToStr[t.kind] +{&} typeToString(t.sons[0]);
    tyRange: begin
      result := 'range ' +{&} rangeToStr(t.n);
    end;
    tyProc: begin
      result := 'proc (';
      for i := 1 to sonsLen(t)-1 do begin
        result := result +{&} typeToString(t.sons[i]);
        if i < sonsLen(t)-1 then result := result +{&} ', ';
      end;
      addChar(result, ')');
      if t.sons[0] <> nil then
        result := result +{&} ': ' +{&} TypeToString(t.sons[0]);
      if t.callConv <> ccDefault then
        result := result +{&} '{.' +{&} CallingConvToStr[t.callConv] +{&} '.}';
    end;
    else begin
      result := typeToStr[t.kind]
    end
  end
end;

function resultType(t: PType): PType;
begin
  assert(t.kind = tyProc);
  result := t.sons[0] // nil is allowed
end;

function base(t: PType): PType;
begin
  result := t.sons[0]
end;

function firstOrd(t: PType): biggestInt;
begin
  case t.kind of
    tyBool, tyChar, tySequence, tyOpenArray: result := 0;
    tySet, tyVar: result := firstOrd(t.sons[0]);
    tyArray, tyArrayConstr: begin
      result := firstOrd(t.sons[0]);
    end;
    tyRange: begin
      assert(t.n <> nil);
      // range directly given:
      assert(t.n.kind = nkRange);
      result := getOrdValue(t.n.sons[0])
    end;
    tyInt: begin
      if platform.intSize = 4 then result := -(2147483646) - 2
      else result := $8000000000000000;
    end;
    tyInt8:  result := -128;
    tyInt16: result := -32768;
    tyInt32: result := -2147483646 - 2;
    tyInt64: result := $8000000000000000;
    tyEnum: begin
      // if basetype <> nil then return firstOrd of basetype
      if (sonsLen(t) > 0) and (t.sons[0] <> nil) then
        result := firstOrd(t.sons[0])
      else begin
        assert(t.n.sons[0].kind = nkSym);
        result := t.n.sons[0].sym.position;
      end;
    end;
    tyGenericInst: result := firstOrd(lastSon(t));
    else begin
      InternalError('invalid kind for first(' +{&}
        typeKindToStr[t.kind] +{&} ')');
      result := 0;
    end
  end
end;

function lastOrd(t: PType): biggestInt;
begin
  case t.kind of
    tyBool: result := 1;
    tyChar: result := 255;
    tySet, tyVar: result := lastOrd(t.sons[0]);
    tyArray, tyArrayConstr: begin
      result := lastOrd(t.sons[0]);
    end;
    tyRange: begin
      assert(t.n <> nil);
      // range directly given:
      assert(t.n.kind = nkRange);
      result := getOrdValue(t.n.sons[1]);
    end;
    tyInt: begin
      if platform.intSize = 4 then result := $7FFFFFFF
      else result := $7FFFFFFFFFFFFFFF;
    end;
    tyInt8:  result := $7F;
    tyInt16: result := $7FFF;
    tyInt32: result := $7FFFFFFF;
    tyInt64: result := $7FFFFFFFFFFFFFFF;
    tyEnum: begin
      assert(t.n.sons[sonsLen(t.n)-1].kind = nkSym);
      result := t.n.sons[sonsLen(t.n)-1].sym.position;
    end;
    tyGenericInst: result := firstOrd(lastSon(t));
    else begin
      InternalError('invalid kind for last(' +{&}
        typeKindToStr[t.kind] +{&} ')');
      result := 0;
    end
  end
end;

function lengthOrd(t: PType): biggestInt;
begin
  case t.kind of
    tyInt64, tyInt32, tyInt: result := lastOrd(t);
    else result := lastOrd(t) - firstOrd(t) + 1;
  end
end;

function equalParam(a, b: PSym): TParamsEquality;
begin
  if SameTypeOrNil(a.typ, b.typ) then begin
    if (a.ast = b.ast) then
      result := paramsEqual
    else if (a.ast <> nil) and (b.ast <> nil) then begin
      if ExprStructuralEquivalent(a.ast, b.ast) then result := paramsEqual
      else result := paramsIncompatible
    end
    else if (a.ast <> nil) then
      result := paramsEqual
    else if (b.ast <> nil) then
      result := paramsIncompatible
  end
  else
    result := paramsNotEqual
end;

function equalParams(a, b: PNode): TParamsEquality;
var
  i, len: int;
  m, n: PSym;
begin
  result := paramsEqual;
  len := sonsLen(a);
  if len <> sonsLen(b) then
    result := paramsNotEqual
  else begin
    for i := 1 to len-1 do begin
      m := a.sons[i].sym;
      n := b.sons[i].sym;
      assert((m.kind = skParam) and (n.kind = skParam));
      case equalParam(m, n) of
        paramsNotEqual: begin result := paramsNotEqual; exit end;
        paramsEqual: begin end;
        paramsIncompatible: result := paramsIncompatible;
      end;
      if (m.name.id <> n.name.id) then begin // BUGFIX
        result := paramsNotEqual; exit // paramsIncompatible;
        // continue traversal! If not equal, we can return immediately; else
        // it stays incompatible
      end
    end;
    // check their return type:
    if not SameTypeOrNil(a.sons[0].typ, b.sons[0].typ) then
      if (a.sons[0].typ = nil) or (b.sons[0].typ = nil) then
        result := paramsNotEqual // one proc has a result, the other not is OK
      else
        result := paramsIncompatible // overloading by different
                                     // result types does not work
  end
end;

function SameTypeOrNil(a, b: PType): Boolean;
begin
  if a = b then
    result := true
  else begin
    if (a = nil) or (b = nil) then result := false
    else result := SameType(a, b)
  end
end;

function SameLiteral(x, y: PNode): Boolean;
begin
  result := false;
  if x.kind = y.kind then
    case x.kind of
      nkCharLit..nkInt64Lit:
        result := x.intVal = y.intVal;
      nkFloatLit..nkFloat64Lit:
        result := x.floatVal = y.floatVal;
      nkNilLit:
        result := true
      else assert(false);
    end
end;

function SameRanges(a, b: PNode): Boolean;
begin
  result := SameLiteral(a.sons[0], b.sons[0]) and
    SameLiteral(a.sons[1], b.sons[1])
end;

function sameTuple(a, b: PType): boolean;
// two tuples are equivalent iff the names, types and positions are the same;
// however, both types may not have any field names (t.n may be nil) which
// complicates the matter a bit.
var
  i: int;
  x, y: PSym;
begin
  if sonsLen(a) = sonsLen(b) then begin
    result := true;
    for i := 0 to sonsLen(a)-1 do begin
      result := SameType(a.sons[i], b.sons[i]);
      if not result then exit
    end;
    if (a.n <> nil) and (b.n <> nil) then begin
      for i := 0 to sonsLen(a.n)-1 do begin
        // check field names: 
        if a.n.sons[i].kind <> nkSym then InternalError(a.n.info, 'sameTuple');
        if b.n.sons[i].kind <> nkSym then InternalError(b.n.info, 'sameTuple');
        x := a.n.sons[i].sym;
        y := b.n.sons[i].sym;
        result := x.name.id = y.name.id;
        if not result then break
      end
    end
  end
  else
    result := false;
end;

function SameType(x, y: PType): Boolean;
var
  i: int;
  a, b: PType;
begin
  a := skipGeneric(x);
  b := skipGeneric(y);
  assert(a <> nil);
  assert(b <> nil);
  if a.kind <> b.kind then begin result := false; exit end;
  case a.Kind of
    tyEnum, tyForward, tyObject:
      result := (a.id = b.id);
    tyTuple: 
      result := sameTuple(a, b);
    tyGenericInst:
      result := sameType(lastSon(a), lastSon(b));
    tyGenericParam, tyGeneric, tySequence,
    tyOpenArray, tySet, tyRef, tyPtr, tyVar, tyArrayConstr,
    tyArray, tyProc: begin
      if sonsLen(a) = sonsLen(b) then begin
        result := true;
        for i := 0 to sonsLen(a)-1 do begin
          result := SameTypeOrNil(a.sons[i], b.sons[i]); // BUGFIX
          if not result then exit
        end;
        if result and (a.kind = tyProc) then 
          result := a.callConv = b.callConv // BUGFIX
      end
      else
        result := false;
    end;
    tyRange: begin
      result := SameTypeOrNil(a.sons[0], b.sons[0])
        and SameValue(a.n.sons[0], b.n.sons[0])
        and SameValue(a.n.sons[1], b.n.sons[1])
    end;
    tyChar, tyBool, tyNil, tyPointer, tyString, tyCString, tyInt..tyFloat128:
      result := true;
    else begin
      InternalError('sameType(' +{&} typeKindToStr[a.kind] +{&} ', '
        +{&} typeKindToStr[b.kind] +{&} ')');
      result := false
    end
  end
end;


function align(address, alignment: biggestInt): biggestInt;
begin
  result := address + (alignment-1) and not (alignment-1);
end;

// we compute the size of types lazily:
function computeSizeAux(typ: PType; var a: biggestInt): biggestInt; forward;

function computeRecSizeAux(n: PNode; var a, currOffset: biggestInt): biggestInt;
var
  maxAlign, maxSize, b, res: biggestInt;
  i: int;
begin
  case n.kind of
    nkRecCase: begin
      assert(n.sons[0].kind = nkSym);
      result := computeRecSizeAux(n.sons[0], a, currOffset);
      maxSize := 0;
      maxAlign := 1;
      for i := 1 to sonsLen(n)-1 do begin
        case n.sons[i].kind of
          nkOfBranch, nkElse: begin
            res := computeRecSizeAux(lastSon(n.sons[i]), b, currOffset);
            maxSize := max(maxSize, res);
            maxAlign := max(maxAlign, b);
          end;
          else internalError('computeRecSizeAux(record case branch)');
        end
      end;
      currOffset := align(currOffset, maxAlign) + maxSize;
      result := align(result, maxAlign) + maxSize;
      a := maxAlign;
    end;
    nkRecList: begin
      result := 0;
      maxAlign := 1;
      for i := 0 to sonsLen(n)-1 do begin
        res := computeRecSizeAux(n.sons[i], b, currOffset);
        currOffset := align(currOffset, b) + res;
        result := align(result, b) + res;
        if b > maxAlign then maxAlign := b;
      end;
      //result := align(result, maxAlign);
      // XXX: check GCC alignment for this!
      a := maxAlign;
    end;
    nkSym: begin
      result := computeSizeAux(n.sym.typ, a);
      n.sym.offset := int(currOffset);
    end;
    else begin
      InternalError('computeRecSizeAux()');
      a := 1; result := -1
    end
  end
end;

function computeSizeAux(typ: PType; var a: biggestInt): biggestInt;
var
  i: int;
  res, maxAlign, len, currOffset: biggestInt;
begin
  if typ.size = -2 then begin
    // we are already computing the size of the type
    // --> illegal recursion in type
    result := -2;
    exit
  end;
  if typ.size >= 0 then begin // size already computed
    result := typ.size;
    a := typ.align;
    exit
  end;
  typ.size := -2; // mark as being computed
  case typ.kind of
    tyInt:   begin result := IntSize; a := result; end;
    tyInt8, tyBool, tyChar:  begin result := 1; a := result; end;
    tyInt16: begin result := 2; a := result; end;
    tyInt32, tyFloat32: begin result := 4; a := result; end;
    tyInt64, tyFloat64: begin result := 8; a := result; end;
    tyFloat: begin result := floatSize; a := result; end;
    tyProc: begin
      if typ.callConv = ccClosure then result := 2 * ptrSize
      else result := ptrSize;
      a := ptrSize;
    end;
    tyNil, tyCString, tyString, tySequence, tyPtr, tyRef,
    tyOpenArray: begin result := ptrSize; a := result; end;
    tyArray, tyArrayConstr: begin
      result := lengthOrd(typ.sons[0]) * computeSizeAux(typ.sons[1], a);
    end;
    tyEnum: begin
      if firstOrd(typ) < 0 then
        result := 4 // use signed int32
      else begin
        len := lastOrd(typ); // BUGFIX: use lastOrd!
        if len+1 < 1 shl 8 then result := 1
        else if len+1 < 1 shl 16 then result := 2
        else if len+1 < 1 shl 32 then result := 4
        else result := 8;
      end;
      a := result;
    end;
    tySet: begin
      len := lengthOrd(typ.sons[0]);
      if len <= 8 then result := 1
      else if len <= 16 then result := 2
      else if len <= 32 then result := 4
      else if len <= 64 then result := 8
      else if align(len, 8) mod 8 = 0 then result := align(len, 8) div 8
      else result := align(len, 8) div 8 + 1; // BUGFIX!
      a := result;
    end;
    tyRange: result := computeSizeAux(typ.sons[0], a);
    tyTuple: begin
      result := 0;
      maxAlign := 1;
      for i := 0 to sonsLen(typ)-1 do begin
        res := computeSizeAux(typ.sons[i], a);
        maxAlign := max(maxAlign, a);
        result := align(result, a) + res;
      end;
      result := align(result, maxAlign);
      a := maxAlign;
    end;
    tyObject: begin
      if typ.sons[0] <> nil then begin
        result := computeSizeAux(typ.sons[0], a);
        maxAlign := a
      end
      else if typ.kind = tyObject then begin
        result := intSize; maxAlign := result;
      end
      else begin
        result := 0; maxAlign := 1
      end;
      currOffset := result;
      result := computeRecSizeAux(typ.n, a, currOffset);
      if a < maxAlign then a := maxAlign;
      result := align(result, a);
    end;
    tyGenericInst: begin
      result := computeSizeAux(lastSon(typ), a);
    end;
    else begin
      //internalError('computeSizeAux()');
      result := -1;
    end
  end;
  typ.size := result;
  typ.align := int(a);
end;

function computeSize(typ: PType): biggestInt;
var
  a: biggestInt;
begin
  a := 1;
  result := computeSizeAux(typ, a);
end;

function getSize(typ: PType): biggestInt;
begin
  result := computeSize(typ);
  if result < 0 then
    InternalError('getSize(' +{&} typekindToStr[typ.kind] +{&} ')');
end;

end.

