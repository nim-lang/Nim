//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

unit genhelp;

// This module contains some helper routines used by the different
// code generators.

interface

{$include 'config.inc'}

uses
  nsystem,
  ast, astalgo, trees, msgs, options, platform;

function hasSideEffect(t: PNode): Boolean;

function ReturnsNewThing(op: PNode): Boolean;


function containsGarbageCollectedRef(typ: PType): Boolean;
// returns true if typ contains a reference, sequence or string (all the things
// that are garbage-collected)

function containsHiddenPointer(typ: PType): Boolean;
// returns true if typ contains a string, table or sequence (all the things
// that need to be copied deeply)

function containsObject(typ: PType): Boolean;
// Returns true if typ contains an object type directly; then it has to
// be initialized in a complex way that sets up the typeid field.

function isGarbageCollected(typ: PType): Boolean;

function pointerOf(typ: PType): PType;

implementation

function pointerOf(typ: PType): PType;
begin
  result := newType(unknownLineInfo, tyPtr);
  result.baseType := typ;
  result.align := platform.PtrSize;
  result.size := platform.PtrSize;
end;

function isGarbageCollected(typ: PType): Boolean;
begin
  result := typ.Kind in [tyTable, tyRef, tySequence, tyString]
end;

function ReturnsNewThing(op: PNode): Boolean;
var
  s: PSym;
begin
  result := false;
  if op.kind = nkCall then begin
    if op.sons[0].kind = nkSym then begin
      s := op.sons[0].sym;
      result := (sfReturnsNew in s.flags)
    end
  end
  else if op.typ.Kind = tyArrayConstr then
    result := true // array constructor returns a newly allocated thing
end;

function containsHiddenPointer(typ: PType): Boolean;
var
  t: PType;
  i: int;
begin
  t := typ;
  result := false;
  if t = nil then exit;
  case t.Kind of
    tySequence, tyString, tyTable: result := true;
    tyArray, tyArrayConstr, tyOpenArray:
      result := containsHiddenPointer(t.baseType);
    tySubtype: result := containsHiddenPointer(typ.baseType);
    tyRecord, tyObject: begin
      if (t.baseType <> nil) and containsHiddenPointer(t.baseType) then
        result := true
      else
        // walk through all fields:
        for i := 0 to seqTableLen(t.symList)-1 do
          if containsHiddenPointer(seqTableAt(t.symList, i).typ) then begin
            result := true; break
          end;
    end
    else result := false
  end
end;

function containsGarbageCollectedRef(typ: PType): Boolean;
var
  t: PType;
  i: int;
begin
  t := typ;
  result := false;
  if t = nil then exit;
  case t.Kind of
    tySequence, tyRef, tyString, tyTable: result := true;
    tyArray: result := containsGarbageCollectedRef(t.baseType);
    tyRecord, tyObject: begin
      if (t.baseType <> nil) and containsGarbageCollectedRef(t.baseType) then
        result := true
      else
        // walk through all fields:
        for i := 0 to seqTableLen(t.symList)-1 do
          if containsGarbageCollectedRef(SeqTableAt(t.symList, i).typ) then
          begin
            result := true; break
          end;
    end
    else result := false
  end
end;

function containsObject(typ: PType): Boolean;
var
  t: PType;
  i: int;
begin
  t := typ;
  result := false;
  if t = nil then exit;
  case t.Kind of
    tyArray, tyArrayConstr:
      result := containsObject(t.baseType);
    tyObject: result := true;
    tySubtype: result := containsObject(typ.baseType);
    tyRecord: begin
      // walk through all fields:
      for i := 0 to seqTableLen(t.symList)-1 do
        if containsObject(SeqTableAt(t.symList, i).typ) then begin
          result := true; break
        end;
    end
    else result := false
  end
end;

function hasSideEffect(t: PNode): Boolean;
{var
  it: PNode; }
begin
  result := t.kind in [nkCall, nkArrayConstr, nkRecordConstr, nkSetConstr]
  // assume side effect for operations
        {
  if t.Kind = nkOperation then begin
    // this is for function pointers:
    if hasSideEffect(t.left) then begin
      result := true; exit
    end;
    it := t.right;
    while it <> nil do begin
      if hasSideEffect(it) then begin
        result := true; exit
      end;
      it := it.next
    end;
    result := true
  end;
  result := false            }
end;

end.
