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
  intsets, strtabs

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
  for i in 0 .. high(gSourceFiles):
    if not gSourceFiles[i].dirty: continue
    let newFile = gSourceFiles[i].fullpath.changeFileExt(".pretty.nim")
    try:
      var f = open(newFile, fmWrite)
      for line in gSourceFiles[i].lines:
        f.writeln(line)
      f.close
    except EIO:
      rawMessage(errCannotOpenFile, newFile)

proc `=~`(s: string, a: openArray[string]): bool =
  for x in a:
    if s.startsWith(x): return true

proc beautifyName(s: string, k: TSymKind): string =
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
  let allUpper = allCharsInSet(s, {'A'..'Z', '0'..'9', '_'})
  while i < s.len:
    if s[i] == '_':
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
    Message(info, errGenerated,
      "name does not adhere to naming convention; should be: " & beau)

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

var cannotRename = initIntSet()

proc processSym(c: PPassContext, n: PNode): PNode =
  result = n
  var g = PGen(c)
  case n.kind
  of nkSym:
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
    var first = n.info.col.int
    if first < 0: return
    #inc first, skipIgnoreCase(line, "proc ", first)
    while first > 0 and line[first-1] in Letters: dec first
    if line[first] == '`': inc first

    if {sfImportc, sfExportc} * s.flags != {}:
      # careful, we must ensure the resulting name still matches the external
      # name:
      if newName != s.name.s and newName != s.loc.r.ropeToStr and
          lfFullExternalName notin s.loc.flags:
        Message(n.info, errGenerated,
          "cannot rename $# to $# due to external name" % [s.name.s, newName])
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
  else:
    for i in 0 .. <n.safeLen:
      discard processSym(c, n.sons[i])

proc myOpen(module: PSym): PPassContext =
  var g: PGen
  new(g)
  g.module = module
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

