#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the style checker.

import
  strutils, os, intsets, strtabs

import options, ast, astalgo, msgs, semdata, ropes, idents,
  lineinfos, pathutils

const
  Letters* = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF', '_'}

proc identLen*(line: string, start: int): int =
  while start+result < line.len and line[start+result] in Letters:
    inc result

type
  StyleCheck* {.pure.} = enum None, Warn, Auto

var
  gOverWrite* = true
  gStyleCheck*: StyleCheck
  gCheckExtern*, gOnlyMainfile*: bool

proc overwriteFiles*(conf: ConfigRef) =
  let doStrip = options.getConfigVar(conf, "pretty.strip").normalize == "on"
  for i in 0 .. high(conf.m.fileInfos):
    if conf.m.fileInfos[i].dirty and
        (not gOnlyMainfile or FileIndex(i) == conf.projectMainIdx):
      let newFile = if gOverWrite: conf.m.fileInfos[i].fullpath
                    else: conf.m.fileInfos[i].fullpath.changeFileExt(".pretty.nim")
      try:
        var f = open(newFile.string, fmWrite)
        for line in conf.m.fileInfos[i].lines:
          if doStrip:
            f.write line.strip(leading = false, trailing = true)
          else:
            f.write line
          f.write(conf.m.fileInfos[i], "\L")
        f.close
      except IOError:
        rawMessage(conf, errGenerated, "cannot open file: " & newFile.string)

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
             "cshort", "cu", "nil", "typedesc", "auto", "any",
             "range", "openarray", "varargs", "set", "cfloat", "ref", "ptr",
             "untyped", "typed", "static", "sink", "lent", "type"]:
      result.add s[i]
    else:
      result.add toUpperAscii(s[i])
  of skConst, skEnumField:
    # for 'const' we keep how it's spelt; either upper case or lower case:
    result.add s[0]
  else:
    # as a special rule, don't transform 'L' to 'l'
    if s.len == 1 and s[0] == 'L': result.add 'L'
    elif '_' in s: result.add(s[i])
    else: result.add toLowerAscii(s[0])
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
        result.add toUpperAscii(s[i])
    elif allUpper:
      result.add toLowerAscii(s[i])
    else:
      result.add s[i]
    inc i

proc differ*(line: string, a, b: int, x: string): bool =
  let y = line[a..b]
  result = cmpIgnoreStyle(y, x) == 0 and y != x

proc replaceInFile(conf: ConfigRef; info: TLineInfo; newName: string) =
  let line = conf.m.fileInfos[info.fileIndex.int].lines[info.line.int-1]
  var first = min(info.col.int, line.len)
  if first < 0: return
  #inc first, skipIgnoreCase(line, "proc ", first)
  while first > 0 and line[first-1] in Letters: dec first
  if first < 0: return
  if line[first] == '`': inc first

  let last = first+identLen(line, first)-1
  if differ(line, first, last, newName):
    # last-first+1 != newName.len or
    var x = line.substr(0, first-1) & newName & line.substr(last+1)
    system.shallowCopy(conf.m.fileInfos[info.fileIndex.int].lines[info.line.int-1], x)
    conf.m.fileInfos[info.fileIndex.int].dirty = true

proc lintReport(conf: ConfigRef; info: TLineInfo, beau: string) =
  if optStyleError in conf.globalOptions:
    localError(conf, info, "name should be: '$1'" % beau)
  else:
    message(conf, info, hintName, beau)

proc checkStyle(conf: ConfigRef; cache: IdentCache; info: TLineInfo, s: string, k: TSymKind; sym: PSym) =
  let beau = beautifyName(s, k)
  if s != beau:
    if gStyleCheck == StyleCheck.Auto:
      sym.name = getIdent(cache, beau)
      replaceInFile(conf, info, beau)
    else:
      lintReport(conf, info, beau)

proc styleCheckDefImpl(conf: ConfigRef; cache: IdentCache; info: TLineInfo; s: PSym; k: TSymKind) =
  # operators stay as they are:
  if k in {skResult, skTemp} or s.name.s[0] notin Letters: return
  if k in {skType, skGenericParam} and sfAnon in s.flags: return
  if {sfImportc, sfExportc} * s.flags == {} or gCheckExtern:
    checkStyle(conf, cache, info, s.name.s, k, s)

proc nep1CheckDefImpl(conf: ConfigRef; info: TLineInfo; s: PSym; k: TSymKind) =
  # operators stay as they are:
  if k in {skResult, skTemp} or s.name.s[0] notin Letters: return
  if k in {skType, skGenericParam} and sfAnon in s.flags: return
  if s.typ != nil and s.typ.kind == tyTypeDesc: return
  if {sfImportc, sfExportc} * s.flags != {}: return
  let beau = beautifyName(s.name.s, k)
  if s.name.s != beau:
    lintReport(conf, info, beau)

template styleCheckDef*(conf: ConfigRef; info: TLineInfo; s: PSym; k: TSymKind) =
  if {optStyleHint, optStyleError} * conf.globalOptions != {}:
    nep1CheckDefImpl(conf, info, s, k)
  when defined(nimfix):
    if gStyleCheck != StyleCheck.None: styleCheckDefImpl(conf, cache, info, s, k)

template styleCheckDef*(conf: ConfigRef; info: TLineInfo; s: PSym) =
  styleCheckDef(conf, info, s, s.kind)
template styleCheckDef*(conf: ConfigRef; s: PSym) =
  styleCheckDef(conf, s.info, s, s.kind)

proc styleCheckUseImpl(conf: ConfigRef; info: TLineInfo; s: PSym) =
  if info.fileIndex.int < 0: return
  # we simply convert it to what it looks like in the definition
  # for consistency

  # operators stay as they are:
  if s.kind in {skResult, skTemp} or s.name.s[0] notin Letters:
    return
  if s.kind in {skType, skGenericParam} and sfAnon in s.flags: return
  let newName = s.name.s

  replaceInFile(conf, info, newName)
  #if newName == "File": writeStackTrace()

template styleCheckUse*(info: TLineInfo; s: PSym) =
  when defined(nimfix):
    if gStyleCheck != StyleCheck.None: styleCheckUseImpl(conf, info, s)
