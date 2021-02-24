#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the style checker.

import strutils

import options, ast, msgs, idents, lineinfos, wordrecg

const
  Letters* = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF', '_'}

proc identLen*(line: string, start: int): int =
  while start+result < line.len and line[start+result] in Letters:
    inc result

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
             "pointer", "float", "csize", "csize_t", "cdouble", "cchar", "cschar",
             "cshort", "cu", "nil", "typedesc", "auto", "any",
             "range", "openarray", "varargs", "set", "cfloat", "ref", "ptr",
             "untyped", "typed", "static", "sink", "lent", "type", "owned"]:
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
      if i+1 >= s.len:
        discard "trailing underscores should be stripped off"
      elif i > 0 and s[i-1] in {'A'..'Z'}:
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

proc differ*(line: string, a, b: int, x: string): string =
  proc substrEq(s: string, pos, last: int, substr: string): bool =
    result = true
    for i in 0..<substr.len:
      if pos+i > last or s[pos+i] != substr[i]: return false

  result = ""
  if not substrEq(line, a, b, x):
    let y = line[a..b]
    if cmpIgnoreStyle(y, x) == 0:
      result = y

proc nep1CheckDefImpl(conf: ConfigRef; info: TLineInfo; s: PSym; k: TSymKind) =
  # operators stay as they are:
  if k in {skResult, skTemp} or s.name.s[0] notin Letters: return
  if k in {skType, skGenericParam} and sfAnon in s.flags: return
  if s.typ != nil and s.typ.kind == tyTypeDesc: return
  if {sfImportc, sfExportc} * s.flags != {}: return
  if optStyleCheck notin s.options: return
  let beau = beautifyName(s.name.s, k)
  if s.name.s != beau:
    lintReport(conf, info, beau, s.name.s)

template styleCheckDef*(conf: ConfigRef; info: TLineInfo; s: PSym; k: TSymKind) =
  if {optStyleHint, optStyleError} * conf.globalOptions != {}:
    nep1CheckDefImpl(conf, info, s, k)

template styleCheckDef*(conf: ConfigRef; info: TLineInfo; s: PSym) =
  styleCheckDef(conf, info, s, s.kind)
template styleCheckDef*(conf: ConfigRef; s: PSym) =
  styleCheckDef(conf, s.info, s, s.kind)

proc differs(conf: ConfigRef; info: TLineInfo; newName: string): string =
  let line = sourceLine(conf, info)
  var first = min(info.col.int, line.len)
  if first < 0: return
  #inc first, skipIgnoreCase(line, "proc ", first)
  while first > 0 and line[first-1] in Letters: dec first
  if first < 0: return
  if first+1 < line.len and line[first] == '`': inc first

  let last = first+identLen(line, first)-1
  result = differ(line, first, last, newName)

proc styleCheckUse*(conf: ConfigRef; info: TLineInfo; s: PSym) =
  if info.fileIndex.int < 0: return
  # we simply convert it to what it looks like in the definition
  # for consistency

  # operators stay as they are:
  if s.kind == skTemp or s.name.s[0] notin Letters or sfAnon in s.flags:
    return

  let newName = s.name.s
  let oldName = differs(conf, info, newName)
  if oldName.len > 0:
    lintReport(conf, info, newName, oldName)

proc checkPragmaUse*(conf: ConfigRef; info: TLineInfo; w: TSpecialWord; pragmaName: string) =
  let wanted = $w
  if pragmaName != wanted:
    lintReport(conf, info, wanted, pragmaName)
