//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit ccgutils;

interface

{$include 'config.inc'}

// This module declares some helpers for the C code generator.

uses
  charsets, nsystem,
  ast, astalgo, ropes, lists, nhashes, strutils, types, msgs;

function toCChar(c: Char): string;
function makeCString(const s: string): PRope;
function makeLLVMString(const s: string): PRope;

function TableGetType(const tab: TIdTable; key: PType): PObject;
function GetUniqueType(key: PType): PType;

implementation

var
  gTypeTable: array [TTypeKind] of TIdTable;

procedure initTypeTables();
var
  i: TTypeKind;
begin
  for i := low(TTypeKind) to high(TTypeKind) do 
    InitIdTable(gTypeTable[i]);
end;

function GetUniqueType(key: PType): PType;
var
  t: PType;
  h: THash;
  k: TTypeKind;
begin
  // this is a hotspot in the compiler!
  result := key;
  if key = nil then exit;
  k := key.kind;
  case k of
    tyObject, tyEnum: begin
      result := PType(IdTableGet(gTypeTable[k], key));
      if result = nil then begin
        IdTablePut(gTypeTable[k], key, key);
        result := key;
      end
    end;
    tyGenericInst, tyDistinct, tyOrdinal: 
      result := GetUniqueType(lastSon(key));
    tyProc: begin end;
    else begin
      // we have to do a slow linear search because types may need
      // to be compared by their structure:
      if IdTableHasObjectAsKey(gTypeTable[k], key) then exit;
      for h := 0 to high(gTypeTable[k].data) do begin
        t := PType(gTypeTable[k].data[h].key);
        if (t <> nil) and sameType(t, key) then begin result := t; exit end
      end;
      IdTablePut(gTypeTable[k], key, key);
    end;
  end;
  (*
  case key.Kind of
    tyEmpty, tyChar, tyBool, tyNil, tyPointer, tyString, tyCString, 
    tyInt..tyFloat128, tyProc, tyAnyEnum: begin end;
    tyNone, tyForward: 
      InternalError('GetUniqueType: ' + typeToString(key));
    tyGenericParam, tyGeneric, tyAbstract, tySequence,
    tyOpenArray, tySet, tyVar, tyRef, tyPtr, tyArrayConstr,
    tyArray, tyTuple, tyRange: begin
      // we have to do a slow linear search because types may need
      // to be compared by their structure:
      if IdTableHasObjectAsKey(gTypeTable, key) then exit;
      for h := 0 to high(gTypeTable.data) do begin
        t := PType(gTypeTable.data[h].key);
        if (t <> nil) and sameType(t, key) then begin result := t; exit end
      end;
      IdTablePut(gTypeTable, key, key);
    end;
    tyObject, tyEnum: begin
      result := PType(IdTableGet(gTypeTable, key));
      if result = nil then begin
        IdTablePut(gTypeTable, key, key);
        result := key;
      end
    end;
    tyGenericInst, tyAbstract: result := GetUniqueType(lastSon(key));
  end; *)
end;

function TableGetType(const tab: TIdTable; key: PType): PObject;
var
  t: PType;
  h: THash;
begin // returns nil if we need to declare this type
  result := IdTableGet(tab, key);
  if (result = nil) and (tab.counter > 0) then begin
    // we have to do a slow linear search because types may need
    // to be compared by their structure:
    for h := 0 to high(tab.data) do begin
      t := PType(tab.data[h].key);
      if t <> nil then begin
        if sameType(t, key) then begin
          result := tab.data[h].val;
          exit
        end
      end
    end
  end
end;

function toCChar(c: Char): string;
begin
  case c of
    #0..#31, #128..#255: result := '\' + toOctal(c);
    '''', '"', '\': result := '\' + c;
    else result := {@ignore} c {@emit toString(c)}
  end;
end;

function makeCString(const s: string): PRope;
// BUGFIX: We have to split long strings into many ropes. Otherwise
// this could trigger an InternalError(). See the ropes module for
// further information.
const
  MaxLineLength = 64;
var
  i: int;
  res: string;
begin
  result := nil;
  res := '"'+'';
  for i := strStart to length(s)+strStart-1 do begin
    if (i-strStart+1) mod MaxLineLength = 0 then begin
      add(res, '"');
      add(res, nl);
      app(result, toRope(res)); 
      // reset:
      setLength(res, 1);
      res[strStart] := '"';
    end;
    add(res, toCChar(s[i]));
  end;
  addChar(res, '"');
  app(result, toRope(res));
end;

function makeLLVMString(const s: string): PRope;
const
  MaxLineLength = 64;
var
  i: int;
  res: string;
begin
  result := nil;
  res := 'c"';
  for i := strStart to length(s)+strStart-1 do begin
    if (i-strStart+1) mod MaxLineLength = 0 then begin
      app(result, toRope(res));
      setLength(res, 0);
    end;
    case s[i] of
     #0..#31, #128..#255, '"', '\': begin
       addChar(res, '\');
       add(res, toHex(ord(s[i]), 2));
     end
     else
       addChar(res, s[i])
    end;
  end;
  add(res, '\00"');
  app(result, toRope(res));
end;

begin
  InitTypeTables();
end.
