//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
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
  ast, astalgo, ropes, lists, hashes, strutils, types, msgs;

function toCChar(c: Char): string;
function makeCString(const s: string): PRope;

function TableGetType(const tab: TIdTable; key: PType): PObject;
function GetUniqueType(key: PType): PType;

implementation

var
  gTypeTable: TIdTable;

function GetUniqueType(key: PType): PType;
var
  t: PType;
  h: THash;
begin
  result := key;
  if key = nil then exit;
  assert(key.kind <> tyForward);
  if key.kind = tyGenericInst then begin
    result := GetUniqueType(lastSon(key));
    exit
  end;
  if IdTableHasObjectAsKey(gTypeTable, key) then exit;
  // we have to do a slow linear search because types may need
  // to be compared by their structure:
  for h := 0 to high(gTypeTable.data) do begin
    t := PType(gTypeTable.data[h].key);
    if (t <> nil) and sameType(t, key) then begin result := t; exit end
  end;
  IdTablePut(gTypeTable, key, key);
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
      res := res +{&} '"' +{&} nl;
      app(result, toRope(res));
      res := '"'+''; // reset
    end;
    res := res +{&} toCChar(s[i]);
  end;
  res := res +{&} '"'+'';
  app(result, toRope(res));
end;

initialization
  InitIdTable(gTypeTable);
end.
