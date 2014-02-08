#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the code "prettifier". This is part of the toolchain
## to convert Nimrod code into a consistent style.

import 
  strutils, os, options, ast, astalgo, msgs, ropes, idents, passes,
  intsets, strtabs, semdata
  
const
  removeTP = false # when true, "nimrod pretty" converts TTyp to Typ.

type
  TGen = object of TPassContext
    module*: PSym
  PGen = ref TGen
  
  TSourceFile = object
    lines: seq[string]
    dirty: bool
    fullpath: string

var
  gSourceFiles: seq[TSourceFile] = @[]
  gCheckExtern: bool
  rules: PStringTable

proc loadFile(info: TLineInfo) =
  let i = info.fileIndex
  if i >= gSourceFiles.len:
    gSourceFiles.setLen(i+1)
  if gSourceFiles[i].lines.isNil:
    gSourceFiles[i].lines = @[]
    let path = info.toFullPath
    gSourceFiles[i].fullpath = path
    # we want to die here for EIO:
    for line in lines(path):
      gSourceFiles[i].lines.add(line)

proc overwriteFiles*() =
  let overWrite = options.getConfigVar("pretty.overwrite").normalize == "on"
  let doStrip = options.getConfigVar("pretty.strip").normalize == "on"
  for i in 0 .. high(gSourceFiles):
    if not gSourceFiles[i].dirty: continue
    let newFile = if overWrite: gSourceFiles[i].fullpath
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
    except EIO:
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
    when removeTP:
      if s[0] == 'T' and s[1] in {'A'..'Z'}:
        i = 1
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

proc checkStyle*(info: TLineInfo, s: string, k: TSymKind) =
  let beau = beautifyName(s, k)
  if s != beau:
    message(info, errGenerated, "name should be: " & beau)

const
  Letters = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF', '_'}

proc identLen(line: string, start: int): int =
  while start+result < line.len and line[start+result] in Letters:
    inc result

proc differ(line: string, a, b: int, x: string): bool =
  let y = line[a..b]
  result = cmpIgnoreStyle(y, x) == 0 and y != x
  when false:
    var j = 0
    for i in a..b:
      if line[i] != x[j]: return true
      inc j
    return false

proc checkDef*(n: PNode; s: PSym) =
  # operators stay as they are:
  if s.kind in {skResult, skTemp} or s.name.s[0] notin Letters: return
  if s.kind in {skType, skGenericParam} and sfAnon in s.flags: return

  if {sfImportc, sfExportc} * s.flags == {} or gCheckExtern:
    checkStyle(n.info, s.name.s, s.kind)

proc checkDef(c: PGen; n: PNode) =
  if n.kind != nkSym: return
  checkDef(n, n.sym)

proc checkUse*(n: PNode, s: PSym) =
  if n.info.fileIndex < 0: return
  # we simply convert it to what it looks like in the definition
  # for consistency
  
  # operators stay as they are:
  if s.kind in {skResult, skTemp} or s.name.s[0] notin Letters: return
  if s.kind in {skType, skGenericParam} and sfAnon in s.flags: return
  let newName = s.name.s
  
  loadFile(n.info)
  
  let line = gSourceFiles[n.info.fileIndex].lines[n.info.line-1]
  var first = min(n.info.col.int, line.len)
  if first < 0: return
  #inc first, skipIgnoreCase(line, "proc ", first)
  while first > 0 and line[first-1] in Letters: dec first
  if first < 0: return
  if line[first] == '`': inc first
  
  let last = first+identLen(line, first)-1
  if differ(line, first, last, newName):
    # last-first+1 != newName.len or 
    var x = line.substr(0, first-1) & newName & line.substr(last+1)
    when removeTP:
      # the WinAPI module is full of 'TX = X' which after the substitution
      # becomes 'X = X'. We remove those lines:
      if x.match(peg"\s* {\ident} \s* '=' \s* y$1 ('#' .*)?"):
        x = ""
    
    system.shallowCopy(gSourceFiles[n.info.fileIndex].lines[n.info.line-1], x)
    gSourceFiles[n.info.fileIndex].dirty = true

when false:
  var cannotRename = initIntSet()

  proc beautifyName(s: string, k: TSymKind): string =
    let allUpper = allCharsInSet(s, {'A'..'Z', '0'..'9', '_'})
    result = newStringOfCap(s.len)
    var i = 0
    case k
    of skType, skGenericParam:
      # skip leading 'T'
      when removeTP:
        if s[0] == 'T' and s[1] in {'A'..'Z'}:
          i = 1
      if s =~ ["int", "uint", "cint", "cuint", "clong", "cstring", "string",
               "char", "byte", "bool", "openArray", "seq", "array", "void",
               "pointer", "float", "csize", "cdouble", "cchar", "cschar",
               "cshort", "cu"]:
        result.add s[i]
      else:
        result.add toUpper(s[i])
    of skConst, skEnumField:
      # for 'const' we keep how it's spelt; either upper case or lower case:
      result.add s[0]
    else:
      # as a special rule, don't transform 'L' to 'l'
      if s.len == 1 and s[0] == 'L': result.add 'L'
      else: result.add toLower(s[0])
    inc i
    while i < s.len:
      if s[i] == '_':
        inc i
        result.add toUpper(s[i])
      elif allUpper:
        result.add toLower(s[i])
      else:
        result.add s[i]
      inc i

  proc checkUse(c: PGen; n: PNode) =
    if n.info.fileIndex < 0: return
    let s = n.sym
    # operators stay as they are:
    if s.kind in {skResult, skTemp} or s.name.s[0] notin Letters: return
    if s.kind in {skType, skGenericParam} and sfAnon in s.flags: return
    
    if s.id in cannotRename: return
    
    let newName = if rules.hasKey(s.name.s): rules[s.name.s]
                  else: beautifyName(s.name.s, n.sym.kind)
    
    loadFile(n.info)
    
    let line = gSourceFiles[n.info.fileIndex].lines[n.info.line-1]
    var first = min(n.info.col.int, line.len)
    if first < 0: return
    #inc first, skipIgnoreCase(line, "proc ", first)
    while first > 0 and line[first-1] in Letters: dec first
    if first < 0: return
    if line[first] == '`': inc first
    
    if {sfImportc, sfExportc} * s.flags != {}:
      # careful, we must ensure the resulting name still matches the external
      # name:
      if newName != s.name.s and newName != s.loc.r.ropeToStr and
          lfFullExternalName notin s.loc.flags:
        #Message(n.info, errGenerated, 
        #  "cannot rename $# to $# due to external name" % [s.name.s, newName])
        cannotRename.incl(s.id)
        return
    let last = first+identLen(line, first)-1
    if differ(line, first, last, newName):
      # last-first+1 != newName.len or 
      var x = line.subStr(0, first-1) & newName & line.substr(last+1)
      when removeTP:
        # the WinAPI module is full of 'TX = X' which after the substitution
        # becomes 'X = X'. We remove those lines:
        if x.match(peg"\s* {\ident} \s* '=' \s* y$1 ('#' .*)?"):
          x = ""
      
      system.shallowCopy(gSourceFiles[n.info.fileIndex].lines[n.info.line-1], x)
      gSourceFiles[n.info.fileIndex].dirty = true

proc check(c: PGen, n: PNode) =
  case n.kind
  of nkSym: checkUse(n, n.sym)
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
  gCheckExtern = options.getConfigVar("pretty.checkextern").normalize == "on"
  result = g
  if rules.isNil:
    rules = newStringTable(modeStyleInsensitive)
    when removeTP:
      # XXX activate when the T/P stuff is deprecated
      let path = joinPath([getPrefixDir(), "config", "rename.rules.cfg"])
      for line in lines(path):
        if line.len > 0:
          let colon = line.find(':')
          if colon > 0:
            rules[line.substr(0, colon-1)] = line.substr(colon+1)
          else:
            rules[line] = line

const prettyPass* = makePass(open = myOpen, process = processSym)

