## Generate effective NIF representation for `Enum`

import ".." / compiler / [ast, options]

import std / [syncio, assertions, strutils, tables]

# We need to duplicate this type here as ast.nim's version of it does not work
# as it sets the string values explicitly breaking our logic...
type
  TCallingConventionMirror = enum
    ccNimCall
    ccStdCall
    ccCDecl
    ccSafeCall
    ccSysCall
    ccInline
    ccNoInline
    ccFastCall
    ccThisCall
    ccClosure
    ccNoConvention
    ccMember

const
  SpecialCases = [
    ("nkCommand", "cmd"),
    ("nkIfStmt", "if"),
    ("nkError", "err"),
    ("nkType", "onlytype"),
    ("nkTypeSection", "type"),
    ("tySequence", "seq"),
    ("tyVar", "mut"),
    ("tyProc", "proctype"),
    ("tyUncheckedArray", "uarray"),
    ("nkExprEqExpr", "vv"),
    ("nkExprColonExpr", "kv"),
    ("nkDerefExpr", "deref"),
    ("nkReturnStmt", "ret"),
    ("nkBreakStmt", "brk"),
    ("nkStmtListExpr", "expr"),
    ("nkEnumFieldDef", "efld"),
    ("nkNilLit", "nil"),
    ("ccNoConvention", "noconv"),
    ("mExpr", "exprm"),
    ("mStmt", "stmtm"),
    ("mEqNimrodNode", "eqnimnode"),
    ("mPNimrodNode", "nimnode"),
    ("mNone", "nonem"),
    ("mAsgn", "asgnm"),
    ("mOf", "ofm"),
    ("mAddr", "addrm"),
    ("mType", "typem"),
    ("mStatic", "staticm"),
    ("mRange", "rangem"),
    ("mVar", "varm"),
    ("mInSet", "contains"),
    ("mNil", "nilm"),
    ("tyBuiltInTypeClass", "bconcept"),
    ("tyUserTypeClass", "uconcept"),
    ("tyUserTypeClassInst", "uconceptinst"),
    ("tyCompositeTypeClass", "cconcept"),
    ("tyGenericInvocation", "ginvoke"),
    ("tyGenericBody", "gbody"),
    ("tyGenericInst", "ginst"),
    ("tyGenericParam", "gparam"),
    ("nkStmtList", "stmts"),
    ("nkDotExpr", "dot"),
    ("nkBracketExpr", "at")
  ]
  SuffixesToReplace = [
    ("Section", ""), ("Branch", ""), ("Stmt", ""), ("I", ""),
    ("Expr", "x"), ("Def", "")
  ]
  PrefixesToReplace = [
    ("Length", "len"),
    ("SetLength", "setlen"),
    ("Append", "add")
  ]
  AdditionalNodes = [
    "nf", # "node flag"
    "tf", # "type flag"
    "sf", # "sym flag"
    "htype", # annotated with a hidden type
    "missing"
  ]

proc genEnum[E](f: var File; enumName: string; known: var OrderedTable[string, bool]; prefixLen = 2) =
  var mappingA = initOrderedTable[string, E]()
  var cases = ""
  for e in low(E)..high(E):
    var es = $e
    if es.startsWith("nkHidden"):
      es = es.replace("nkHidden", "nkh") # prefix will be removed
    else:
      for (suffix, repl) in items SuffixesToReplace:
        if es.len - prefixLen > suffix.len and es.endsWith(suffix):
          es.setLen es.len - len(suffix)
          es.add repl
          break
      for (suffix, repl) in items PrefixesToReplace:
        if es.len - prefixLen > suffix.len and es.substr(prefixLen).startsWith(suffix):
          es = es.substr(0, prefixLen-1) & repl & es.substr(prefixLen+suffix.len)
          break

    let s = es.substr(prefixLen)
    var done = false
    for enu, key in items SpecialCases:
      if $e == enu:
        assert(not mappingA.hasKey(key))
        if known.hasKey(key): echo "conflict: ", key
        known[key] = true
        assert key.len > 0
        mappingA[key] = e
        cases.add "  of " & $e & ": " & escape(key) & "\n"
        done = true
        break
    if not done:
      let key = s.toLowerAscii
      if not mappingA.hasKey(key):
        assert key.len > 0, $e
        if known.hasKey(key): echo "conflict: ", key
        known[key] = true
        mappingA[key] = e
        cases.add "  of " & $e & ": " & escape(key) & "\n"
        done = true
    if not done:
      var d = 0
      while d < 10:
        let key = s.toLowerAscii & $d
        if not mappingA.hasKey(key):
          assert key.len > 0
          mappingA[key] = e
          cases.add "  of " & $e & ": " & escape(key) & "\n"
          done = true
          break
        inc d
    if not done:
      echo "Could not map: " & s
  #echo mapping
  var code = ""
  code.add "proc toNifTag*(s: " & enumName & "): string =\n"
  code.add "  case s\n"
  code.add cases
  code.add "\n\n"
  let procname = "parse" # & enumName.substr(1)
  code.add "proc " & procname & "*(t: typedesc[" & enumName & "]; s: string): " & enumName & " =\n"
  code.add "  case s\n"
  for (k, v) in pairs mappingA:
    code.add "  of " & escape(k) & ": " & $v & "\n"
  code.add "  else: " & $low(E) & "\n\n\n"
  f.write code

proc genEnum[E](f: var File; enumName: string; prefixLen = 2) =
  var known = initOrderedTable[string, bool]()
  genEnum[E](f, enumName, known, prefixLen)


proc genFlags[E](f: var File; enumName: string; prefixLen = 2) =
  var mappingA = initOrderedTable[string, E]()
  var mappingB = initOrderedTable[string, E]()
  var cases = ""
  for e in low(E)..high(E):
    let s = ($e).substr(prefixLen)
    var done = false
    for c in s:
      if c in {'A'..'Z'}:
        let key = $c.toLowerAscii
        if not mappingA.hasKey(key):
          mappingA[key] = e
          cases.add "    of " & $e & ": dest.add " & escape(key) & "\n"
          done = true
          break
    if not done:
      var d = 0
      while d < 10:
        let key = $s[0].toLowerAscii & $d
        if not mappingB.hasKey(key):
          mappingB[key] = e
          cases.add "    of " & $e & ": dest.add " & escape(key) & "\n"
          done = true
          break
        inc d
    if not done:
      quit "Could not map: " & s
  #echo mapping
  var code = ""
  code.add "proc genFlags*(s: set[" & enumName & "]; dest: var string) =\n"
  code.add "  for e in s:\n"
  code.add "    case e\n"
  code.add cases
  code.add "\n\n"
  code.add "proc parse*(t: typedesc[" & enumName & "]; s: string): set[" & enumName & "] =\n"
  code.add "  result = {}\n"
  code.add "  var i = 0\n"
  code.add "  while i < s.len:\n"
  code.add "    case s[i]\n"
  for c in 'a'..'z':
    var letterFound = false
    var digitsFound = 0
    for d in '0'..'9':
      if mappingB.hasKey($c & $d):
        if not letterFound:
          letterFound = true
          code.add "    of '" & c & "':\n"
        if digitsFound == 0:
          code.add "      if"
        else:
          code.add "      elif"
        inc digitsFound
        code.add " i+1 < s.len and s[i+1] == '" & d & "':\n"
        code.add "        result.incl " & $mappingB[$c & $d] & "\n"
        code.add "        inc i\n"

    if mappingA.hasKey($c):
      if digitsFound == 0:
        code.add "    of '" & c & "': "
      else:
        code.add "      else: "
      code.add "result.incl " & $mappingA[$c] & "\n"

  code.add "    else: discard\n"
  code.add "    inc i\n\n"
  f.write code

var f = open("compiler/icnif/enum2nif.nim", fmWrite)
f.write "# Generated by tools/enumgen.nim. DO NOT EDIT!\n\n"
f.write "import \"..\" / [ast, options]\n\n"
# use the same mapping for TNodeKind and TMagic so that we can detect conflicts!
var nodeTags = initOrderedTable[string, bool]()
for a in AdditionalNodes:
  nodeTags[a] = true

genEnum[TNodeKind](f, "TNodeKind", nodeTags)
genEnum[TSymKind](f, "TSymKind")
genEnum[TTypeKind](f, "TTypeKind")
genEnum[TLocKind](f, "TLocKind", 3)
genEnum[TCallingConventionMirror](f, "TCallingConvention", 2)
genEnum[TMagic](f, "TMagic", nodeTags, 1)
genEnum[TStorageLoc](f, "TStorageLoc")
genEnum[TLibKind](f, "TLibKind")
genFlags[TSymFlag](f, "TSymFlag")
genFlags[TNodeFlag](f, "TNodeFlag")
genFlags[TTypeFlag](f, "TTypeFlag")
genFlags[TLocFlag](f, "TLocFlag")
genFlags[TOption](f, "TOption", 3)

f.close()
