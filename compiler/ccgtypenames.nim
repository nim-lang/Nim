#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Module to map Nim types to unique C *identifiers*. The code
## generator becomes easier when we can predict the name of a
## type.

import ast, types, int128, modulegraphs, renderer, ropes, options
from strutils import toLowerAscii

const
  irrelevantForBackend* = {tyGenericBody, tyGenericInst, tyGenericInvocation,
                          tyDistinct, tyRange, tyStatic, tyAlias, tySink,
                          tyInferred, tyOwned}

proc isImportedCppType*(t: PType): bool =
  let x = t.skipTypes(irrelevantForBackend)
  result = (t.sym != nil and sfInfixCall in t.sym.flags) or
           (x.sym != nil and sfInfixCall in x.sym.flags)

proc uniqueCTypeName(result: var string; s: string) =
  for c in s:
    case c
    of 'a'..'z':
      result.add c
    of 'A'..'Z':
      result.add toLowerAscii(c)
    else:
      # We mangle upper letters and digits too so that there cannot
      # be clashes with our special meanings
      result.addInt ord(c)

proc uniqueCTypeName(c: var string; t: PType; g: ModuleGraph) =
  # based on sighashes.hashType, but simplified.
  # There are two ideas at play here: Structural types like
  # tuples must map to a unique name based on the structure,
  # nominal types like objects and enums can have the name
  # for readability, but ultimately are distinguished by the
  # compiler's ID mechanism.
  if t == nil:
    c &= "NULL"
    return
  case t.kind
  of tyGenericInvocation:
    c &= 'L'
    for i in 0..<t.len:
      if i > 0: c &= '_'
      c.uniqueCTypeName t[i], g
    c &= 'T'
  of tyTuple:
    c &= "TUPL"
    for i in 0..<t.len:
      if i > 0: c &= '_'
      c.uniqueCTypeName t[i], g
    c &= 'T'
  of tyDistinct, tyRange:
    # the C backend strips away 'tyDistinct':
    c.uniqueCTypeName t[0], g
  of tyGenericInst:
    if sfInfixCall in t.base.sym.flags or (isImportedCppType(t.base) and t.base.kind == tyObject):
      # This is an imported C++ generic type.
      # We cannot trust the `lastSon` to hold a properly populated and unique
      # value for each instantiation, so we hash the generic parameters here:
      c &= 'L'
      let normalizedType = t.skipGenericAlias
      for i in 0..<normalizedType.len - 1:
        if i > 0: c &= '_'
        c.uniqueCTypeName t[i], g
      c &= 'T'
    else:
      c.uniqueCTypeName t.lastSon, g
  of tyAlias, tySink, tyUserTypeClasses, tyInferred, tyGenericBody, tyOwned:
    c.uniqueCTypeName t.lastSon, g
  of tyBool, tyChar, tyInt..tyUInt64:
    # no canonicalization for integral types, so that e.g. ``pid_t`` is
    # produced instead of ``NI``:
    if t.sym != nil and {sfCompilerProc, sfExportc} * t.sym.flags != {}:
      c &= $t.sym.loc.r
    else:
      case t.kind
      of tyBool: c &= "NIM_BOOL"
      of tyChar: c &= "NIM_CHAR"
      of tyInt: c &= "NI"
      of tyInt8..tyInt64:
        c &= "NI"
        c.addInt getSize(g.config, t)*8
      of tyFloat..tyFloat128:
        c &= "NF"
        c.addInt getSize(g.config, t)*8
      else:
        c &= "NU"
        c.addInt getSize(g.config, t)*8

  of tyObject, tyEnum:
    let s = t.sym
    if {sfCompilerProc, sfExportc} * s.flags != {}:
      c &= $t.sym.loc.r
    else:
      c.uniqueCTypeName s.name.s
      c &= '_'
      c &= $g.ifaces[t.itemId.module].uniqueName
      c &= '_'
      c.addInt t.itemId.item
  of tyArray:
    c &= "NA"
    c.addInt toInt64Checked(lengthOrd(g.config, t[0]), 0)
    c &= 'L'
    c.uniqueCTypeName t[1], g
    c &= 'T'
  of tySet:
    c &= "SL"
    c.uniqueCTypeName t.lastSon, g
    c &= 'T'
  of tySequence:
    c &= "QL"
    c.uniqueCTypeName t.lastSon, g
    c &= 'T'
  of tyOpenArray:
    c &= "OL"
    c.uniqueCTypeName t.lastSon, g
    c &= 'T'
  of tyVarargs:
    c &= "VL"
    c.uniqueCTypeName t.lastSon, g
    c &= 'T'
  of tyUncheckedArray:
    c &= "UL"
    c.uniqueCTypeName t.lastSon, g
    c &= 'T'
  of tyRef:
    c &= "RL"
    c.uniqueCTypeName t.lastSon, g
    c &= 'T'
  of tyPtr:
    c &= "PL"
    c.uniqueCTypeName t.lastSon, g
    c &= 'T'
  of tyVar:
    c &= "VL"
    c.uniqueCTypeName t.lastSon, g
    if tfVarIsPtr in t.flags: c &= "_Varisptr"
    c &= 'T'
  of tyLent:
    c &= "LL"
    c.uniqueCTypeName t.lastSon, g
    if tfVarIsPtr in t.flags: c &= "_Varisptr"
    c &= 'T'
  of tyProc:
    c &= (if tfIterator in t.flags: "IL" else: "FL")
    for i in 0..<t.len:
      if i > 0: c &= '_'
      c.uniqueCTypeName t[i], g
    if tfVarargs in t.flags: c &= "_Varargs"
    c &= '_'
    c &= $t.callConv
    c &= 'T'
  of tyNone: c &= "NN"
  of tyEmpty: c &= "NE"
  of tyNil: c &= "NIM_POINTER"
  of tyUntyped: c &= "NUT"
  of tyTyped: c &= "NYT"
  of tyGenericParam: c &= "NGP"
  of tyOrdinal: c &= "NORD"
  of tyPointer: c &= "NIM_POINTER"
  of tyString:
    if optSeqDestructors in g.config.globalOptions:
      c &= "NimStringV2"
    else:
      c &= "NimStringV1"
  of tyCString: c &= "NCSTRING"
  of tyForward: c &= "NFRWD"
  of tyProxy: c &= "NERR"
  of tyStatic, tyFromExpr:
    c &= "NSTATICL"
    if t.n != nil:
      c.uniqueCTypeName(renderTree(t.n))
      c &= '_'
    c.uniqueCTypeName t[0], g
    c &= 'T'
  of tyBuiltInTypeClass, tyCompositeTypeClass, tyAnd, tyOr, tyNot,
      tyAnything, tyConcept, tyVoid, tyTypeDesc:
    c &= 'N'
    c.addInt ord(t.kind)
    c &= 'L'
    for i in 0..<t.len:
      if i > 0: c &= '_'
      c.uniqueCTypeName t[i], g
    c &= 'T'

proc uniqueCTypeName*(t: PType; g: ModuleGraph): string =
  result = newStringOfCap(30)
  uniqueCTypeName(result, t, g)
