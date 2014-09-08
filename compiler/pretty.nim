#
#
#           The Nim Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the code "prettifier". This is part of the toolchain
## to convert Nim code into a consistent style.

import 
  strutils, os, options, ast, astalgo, msgs, ropes, idents, passes,
  intsets, strtabs, semdata, prettybase


type
  StyleCheck* {.pure.} = enum None, Confirm, Auto

var
  gOverWrite* = true
  gStyleCheck*: StyleCheck
  gCheckExtern*: bool

type
  TGen = object of TPassContext
    module*: PSym
  PGen = ref TGen

proc overwriteFiles*() =
  let doStrip = options.getConfigVar("pretty.strip").normalize == "on"
  for i in 0 .. high(gSourceFiles):
    if not gSourceFiles[i].dirty: continue
    let newFile = if gOverWrite: gSourceFiles[i].fullpath
                  else: gSourceFiles[i].fullpath.changeFileExt(".pretty.nim")
    try:
      var f = open(newFile, fmWrite)
      for line in gSourceFiles[i].lines:
        if doStrip:
          f.write line.strip(leading = false, trailing = true)
        else:
          f.write line
        f.write("\L")
      f.close
    except IOError:
      rawMessage(errCannotOpenFile, newFile)

proc `=~`(s: string, a: openArray[string]): bool =
  for x in a:
    if s.startsWith(x): return true

proc beautifyName(s: string, k: TSymKind): string =
  # minimal set of rules here for transition:
  # GC_ is allowed

  let allUpper = allCharsInSet(s, {'A'..'Z', '0'..'9', '_'})
  if allUpper and k in {skConst, skEnumField, skType}: return s
  result = newStringOfCap(s.len)
  var i = 0
  case k
  of skType, skGenericParam:
    # Types should start with a capital unless builtins like 'int' etc.:
    if s =~ ["int", "uint", "cint", "cuint", "clong", "cstring", "string",
             "char", "byte", "bool", "openArray", "seq", "array", "void",
             "pointer", "float", "csize", "cdouble", "cchar", "cschar",
             "cshort", "cu", "nil", "expr", "stmt", "typedesc", "auto", "any",
             "range", "openarray", "varargs", "set", "cfloat"
             ]:
      result.add s[i]
    else:
      result.add toUpper(s[i])
  of skConst, skEnumField:
    # for 'const' we keep how it's spelt; either upper case or lower case:
    result.add s[0]
  else:
    # as a special rule, don't transform 'L' to 'l'
    if s.len == 1 and s[0] == 'L': result.add 'L'
    elif '_' in s: result.add(s[i])
    else: result.add toLower(s[0])
  inc i
  while i < s.len:
    if s[i] == '_':
      if i > 0 and s[i-1] in {'A'..'Z'}:
        # don't skip '_' as it's essential for e.g. 'GC_disable'
        result.add('_')
        inc i
        result.add s[i]
      else:
        inc i
        result.add toUpper(s[i])
    elif allUpper:
      result.add toLower(s[i])
    else:
      result.add s[i]
    inc i

proc checkStyle(info: TLineInfo, s: string, k: TSymKind) =
  let beau = beautifyName(s, k)
  if s != beau:
    message(info, hintName, beau)

proc checkDef*(n: PNode; s: PSym) =
  if gStyleCheck == StyleCheck.None: return
  # operators stay as they are:
  if s.kind in {skResult, skTemp} or s.name.s[0] notin prettybase.Letters:
    return
  if s.kind in {skType, skGenericParam} and sfAnon in s.flags: return

  if {sfImportc, sfExportc} * s.flags == {} or gCheckExtern:
    checkStyle(n.info, s.name.s, s.kind)

proc checkDef(c: PGen; n: PNode) =
  if n.kind != nkSym: return
  checkDef(n, n.sym)

proc checkUse*(info: TLineInfo; s: PSym) =
  if info.fileIndex < 0: return
  # we simply convert it to what it looks like in the definition
  # for consistency
  
  # operators stay as they are:
  if s.kind in {skResult, skTemp} or s.name.s[0] notin prettybase.Letters:
    return
  if s.kind in {skType, skGenericParam} and sfAnon in s.flags: return
  let newName = s.name.s
  
  loadFile(info)
  
  let line = gSourceFiles[info.fileIndex].lines[info.line-1]
  var first = min(info.col.int, line.len)
  if first < 0: return
  #inc first, skipIgnoreCase(line, "proc ", first)
  while first > 0 and line[first-1] in prettybase.Letters: dec first
  if first < 0: return
  if line[first] == '`': inc first
  
  let last = first+identLen(line, first)-1
  if differ(line, first, last, newName):
    # last-first+1 != newName.len or 
    var x = line.substr(0, first-1) & newName & line.substr(last+1)    
    system.shallowCopy(gSourceFiles[info.fileIndex].lines[info.line-1], x)
    gSourceFiles[info.fileIndex].dirty = true

proc check(c: PGen, n: PNode) =
  case n.kind
  of nkSym: checkUse(n.info, n.sym)
  of nkBlockStmt, nkBlockExpr, nkBlockType:
    checkDef(c, n[0])
    check(c, n.sons[1])
  of nkForStmt, nkParForStmt:
    let L = n.len
    for i in countup(0, L-3):
      checkDef(c, n[i])
    check(c, n[L-2])
    check(c, n[L-1])
  of nkProcDef, nkLambdaKinds, nkMethodDef, nkIteratorDef, nkTemplateDef,
      nkMacroDef, nkConverterDef:
    checkDef(c, n[namePos])
    for i in namePos+1 .. <n.len: check(c, n.sons[i])
  of nkIdentDefs, nkVarTuple:
    let a = n
    checkMinSonsLen(a, 3)
    let L = len(a)
    for j in countup(0, L-3): checkDef(c, a.sons[j])
    check(c, a.sons[L-2])
    check(c, a.sons[L-1])
  of nkTypeSection, nkConstSection:
    for i in countup(0, sonsLen(n) - 1):
      let a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      checkSonsLen(a, 3)
      checkDef(c, a.sons[0])
      check(c, a.sons[1])
      check(c, a.sons[2])
  else:
    for i in 0 .. <n.safeLen: check(c, n.sons[i])

proc processSym(c: PPassContext, n: PNode): PNode = 
  result = n
  check(PGen(c), n)

proc myOpen(module: PSym): PPassContext =
  var g: PGen
  new(g)
  g.module = module
  result = g

const prettyPass* = makePass(open = myOpen, process = processSym)

