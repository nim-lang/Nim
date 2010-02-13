#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module declares some helpers for the C code generator.

import 
  ast, astalgo, ropes, lists, nhashes, strutils, types, msgs

proc toCChar*(c: Char): string
proc makeCString*(s: string): PRope
proc makeLLVMString*(s: string): PRope
proc TableGetType*(tab: TIdTable, key: PType): PObject
proc GetUniqueType*(key: PType): PType
# implementation

var gTypeTable: array[TTypeKind, TIdTable]

proc initTypeTables() = 
  for i in countup(low(TTypeKind), high(TTypeKind)): InitIdTable(gTypeTable[i])
  
proc GetUniqueType(key: PType): PType = 
  var 
    t: PType
    k: TTypeKind
  # this is a hotspot in the compiler!
  result = key
  if key == nil: return 
  k = key.kind
  case k #
         #  case key.Kind of
         #    tyEmpty, tyChar, tyBool, tyNil, tyPointer, tyString, tyCString, 
         #    tyInt..tyFloat128, tyProc, tyAnyEnum: begin end;
         #    tyNone, tyForward: 
         #      InternalError('GetUniqueType: ' + typeToString(key));
         #    tyGenericParam, tyGeneric, tyAbstract, tySequence,
         #    tyOpenArray, tySet, tyVar, tyRef, tyPtr, tyArrayConstr,
         #    tyArray, tyTuple, tyRange: begin
         #      // we have to do a slow linear search because types may need
         #      // to be compared by their structure:
         #      if IdTableHasObjectAsKey(gTypeTable, key) then exit;
         #      for h := 0 to high(gTypeTable.data) do begin
         #        t := PType(gTypeTable.data[h].key);
         #        if (t <> nil) and sameType(t, key) then begin result := t; exit end
         #      end;
         #      IdTablePut(gTypeTable, key, key);
         #    end;
         #    tyObject, tyEnum: begin
         #      result := PType(IdTableGet(gTypeTable, key));
         #      if result = nil then begin
         #        IdTablePut(gTypeTable, key, key);
         #        result := key;
         #      end
         #    end;
         #    tyGenericInst, tyAbstract: result := GetUniqueType(lastSon(key));
         #  end; 
  of tyObject, tyEnum: 
    result = PType(IdTableGet(gTypeTable[k], key))
    if result == nil: 
      IdTablePut(gTypeTable[k], key, key)
      result = key
  of tyGenericInst, tyDistinct, tyOrdinal: 
    result = GetUniqueType(lastSon(key))
  of tyProc: 
    nil
  else: 
    # we have to do a slow linear search because types may need
    # to be compared by their structure:
    if IdTableHasObjectAsKey(gTypeTable[k], key): return 
    for h in countup(0, high(gTypeTable[k].data)): 
      t = PType(gTypeTable[k].data[h].key)
      if (t != nil) and sameType(t, key): 
        return t
    IdTablePut(gTypeTable[k], key, key)

proc TableGetType(tab: TIdTable, key: PType): PObject = 
  var t: PType
  # returns nil if we need to declare this type
  result = IdTableGet(tab, key)
  if (result == nil) and (tab.counter > 0): 
    # we have to do a slow linear search because types may need
    # to be compared by their structure:
    for h in countup(0, high(tab.data)): 
      t = PType(tab.data[h].key)
      if t != nil: 
        if sameType(t, key): 
          return tab.data[h].val

proc toCChar(c: Char): string = 
  case c
  of '\0'..'\x1F', '\x80'..'\xFF': result = '\\' & toOctal(c)
  of '\'', '\"', '\\': result = '\\' & c
  else: result = $(c)
  
proc makeCString(s: string): PRope = 
  # BUGFIX: We have to split long strings into many ropes. Otherwise
  # this could trigger an InternalError(). See the ropes module for
  # further information.
  const 
    MaxLineLength = 64
  var res: string
  result = nil
  res = "\""
  for i in countup(0, len(s) + 0 - 1): 
    if (i - 0 + 1) mod MaxLineLength == 0: 
      add(res, '\"')
      add(res, "\n")
      app(result, toRope(res)) # reset:
      setlen(res, 1)
      res[0] = '\"'
    add(res, toCChar(s[i]))
  add(res, '\"')
  app(result, toRope(res))

proc makeLLVMString(s: string): PRope = 
  const 
    MaxLineLength = 64
  var res: string
  result = nil
  res = "c\""
  for i in countup(0, len(s) + 0 - 1): 
    if (i - 0 + 1) mod MaxLineLength == 0: 
      app(result, toRope(res))
      setlen(res, 0)
    case s[i]
    of '\0'..'\x1F', '\x80'..'\xFF', '\"', '\\': 
      add(res, '\\')
      add(res, toHex(ord(s[i]), 2))
    else: add(res, s[i])
  add(res, "\\00\"")
  app(result, toRope(res))

InitTypeTables()