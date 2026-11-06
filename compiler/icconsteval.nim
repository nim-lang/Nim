#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Conservative constant values for the IC dependency scanner. This reads
## declarations without running sem or the VM. Unsupported expressions and
## bindings that might be shadowed remain unknown.

import std/[os, tables, sets, strutils, strtabs, syncio]
import ast, idents, options, parser, lineinfos, platform
from commands import compileOptionValue

type
  ConstKind* = enum
    ckUnknown, ckBool, ckInt, ckString
  ConstValue* = object
    case kind*: ConstKind
    of ckBool: boolVal*: bool
    of ckInt: intVal*: BiggestInt
    of ckString: strVal*: string
    of ckUnknown: discard
  ConstScope = ref object
    filename: string
    isMain: bool
    valid: bool
    shadowedOperators: HashSet[string]
    declarations: Table[int, PNode]
    values: Table[int, ConstValue]
    blocked, resolving: HashSet[int]
    includes: seq[string]
  ConstContext* = ref object
    config: ConfigRef
    cache: IdentCache
    scopes: Table[(string, bool), ConstScope]
    operatorModules: Table[string, HashSet[string]]
  ConstParseError = object of CatchableError

const guardOperators = ["==", "!=", "<", "<=", ">", ">=", "and", "or", "not", "&", "+", "-",
  "defined", "compileOption"]

proc boolConst*(value: bool): ConstValue = ConstValue(kind: ckBool, boolVal: value)
proc intConst*(value: BiggestInt): ConstValue = ConstValue(kind: ckInt, intVal: value)
proc stringConst*(value: string): ConstValue = ConstValue(kind: ckString, strVal: value)

proc newConstContext*(config: ConfigRef): ConstContext =
  ConstContext(config: config, cache: newIdentCache())

proc nodeName(n: PNode): string =
  result = ""
  if n != nil:
    case n.kind
    of nkIdent: result = n.ident.s
    of nkAccQuoted:
      for child in n:
        if child.kind == nkIdent: result.add child.ident.s
        else: return ""
    of nkPostfix, nkPragmaExpr:
      if n.len > 0:
        result = nodeName(n[if n.kind == nkPostfix: 1 else: 0])
    of nkDotExpr:
      if n.len == 2:
        let left = nodeName(n[0])
        let right = nodeName(n[1])
        if left.len > 0 and right.len > 0: result = left & "." & right
    else: discard

proc blockName(c: ConstContext; scope: ConstScope; n: PNode) =
  let name = nodeName(n)
  if name.len > 0: scope.blocked.incl c.cache.getIdent(name).id

proc collectBindings(c: ConstContext; scope: ConstScope; n: PNode; moduleScope: bool) =
  ## A generic parameter or local declaration can shadow a module constant.
  ## Blocking its name for the whole file is conservative and needs no sem.
  if n == nil: return
  case n.kind
  of nkStmtList, nkConstSection:
    for child in n: collectBindings(c, scope, child, moduleScope)
  of nkWhenStmt:
    for branch in n:
      for child in branch: collectBindings(c, scope, child, moduleScope)
  of nkConstDef:
    if not moduleScope and n.len > 0: c.blockName(scope, n[0])
    for i in 1..<n.len: collectBindings(c, scope, n[i], false)
  of nkIdentDefs, nkVarTuple:
    for i in 0..<max(0, n.len - 2): c.blockName(scope, n[i])
    for child in n: collectBindings(c, scope, child, false)
  of nkForStmt, nkParForStmt:
    for i in 0..<max(0, n.len - 2): c.blockName(scope, n[i])
    for child in n: collectBindings(c, scope, child, false)
  of routineDefs, nkTypeDef:
    if n.len > 0:
      c.blockName(scope, n[0])
      if nodeName(n[0]) in guardOperators: scope.shadowedOperators.incl nodeName(n[0])
    for child in n: collectBindings(c, scope, child, false)
  else:
    for i in 0..<n.safeLen: collectBindings(c, scope, n[i], false)

proc builtinValue(c: ConstContext; scope: ConstScope; name: string): ConstValue =
  case name
  of "true": boolConst(true)
  of "false": boolConst(false)
  of "hostOS": stringConst(toLowerAscii(platform.OS[c.config.target.targetOS].name))
  of "hostCPU": stringConst(toLowerAscii(platform.CPU[c.config.target.targetCPU].name))
  of "buildOS": stringConst(toLowerAscii(platform.OS[c.config.target.hostOS].name))
  of "buildCPU": stringConst(toLowerAscii(platform.CPU[c.config.target.hostCPU].name))
  of "isMainModule": boolConst(scope.isMain)
  of "hasThreadSupport": boolConst(optThreads in c.config.globalOptions)
  of "usesDestructors":
    boolConst(isDefined(c.config, "gcDestructors") or isDefined(c.config, "gcHooks"))
  else: ConstValue()

proc compareConsts*(a, b: ConstValue; op: string): ConstValue =
  result = ConstValue()
  if a.kind == ckUnknown or a.kind != b.kind: return
  var order: int
  case a.kind
  of ckBool: order = cmp(a.boolVal, b.boolVal)
  of ckInt: order = cmp(a.intVal, b.intVal)
  of ckString: order = cmp(a.strVal, b.strVal)
  of ckUnknown: return
  case op
  of "==": result = boolConst(order == 0)
  of "!=": result = boolConst(order != 0)
  of "<": result = boolConst(order < 0)
  of "<=": result = boolConst(order <= 0)
  of ">": result = boolConst(order > 0)
  of ">=": result = boolConst(order >= 0)
  else: discard

proc evalExpr(c: ConstContext; scope: ConstScope; n: PNode; depth: int): ConstValue
proc lookup(c: ConstContext; scope: ConstScope; name: string; depth: int): ConstValue

proc evalExpr(c: ConstContext; scope: ConstScope; n: PNode; depth: int): ConstValue =
  result = ConstValue()
  if n == nil or depth > 64: return
  case n.kind
  of nkStrLit..nkTripleStrLit: result = stringConst(n.strVal)
  of nkIntLit..nkInt64Lit: result = intConst(n.intVal)
  of nkIdent: result = c.lookup(scope, n.ident.s, depth + 1)
  of nkPar:
    if n.len == 1: result = c.evalExpr(scope, n[0], depth + 1)
  of nkPrefix:
    if n.len == 2:
      if nodeName(n[0]) in scope.shadowedOperators: return
      let value = c.evalExpr(scope, n[1], depth + 1)
      case nodeName(n[0])
      of "not":
        if value.kind == ckBool: result = boolConst(not value.boolVal)
      of "-":
        if value.kind == ckInt and value.intVal != low(BiggestInt):
          result = intConst(-value.intVal)
      of "+":
        if value.kind == ckInt: result = value
      else: discard
  of nkInfix:
    if n.len == 3:
      let op = nodeName(n[0])
      if op in scope.shadowedOperators: return
      let a = c.evalExpr(scope, n[1], depth + 1)
      let b = c.evalExpr(scope, n[2], depth + 1)
      case op
      of "and":
        if (a.kind == ckBool and not a.boolVal) or (b.kind == ckBool and not b.boolVal):
          result = boolConst(false)
        elif a.kind == ckBool and b.kind == ckBool: result = boolConst(true)
      of "or":
        if (a.kind == ckBool and a.boolVal) or (b.kind == ckBool and b.boolVal):
          result = boolConst(true)
        elif a.kind == ckBool and b.kind == ckBool: result = boolConst(false)
      of "&":
        if a.kind == ckString and b.kind == ckString:
          result = stringConst(a.strVal & b.strVal)
      of "==", "!=", "<", "<=", ">", ">=": result = compareConsts(a, b, op)
      else: discard
  of nkCall, nkCommand:
    if n.len == 2:
      if nodeName(n[0]) in scope.shadowedOperators: return
      case nodeName(n[0])
      of "defined":
        let name = nodeName(n[1])
        if name.len > 0: result = boolConst(isDefined(c.config, name))
      of "compileOption":
        if n[1].kind in {nkStrLit..nkTripleStrLit}:
          var known = false
          let value = compileOptionValue(c.config, n[1].strVal, known)
          if known: result = boolConst(value)
      else: discard
  of nkWhenStmt, nkIfExpr:
    for branch in n:
      if branch.kind in {nkElifBranch, nkElifExpr} and branch.len == 2:
        let cond = c.evalExpr(scope, branch[0], depth + 1)
        if cond.kind != ckBool: return
        if cond.boolVal: return c.evalExpr(scope, branch[1], depth + 1)
      elif branch.kind in {nkElse, nkElseExpr} and branch.len == 1:
        return c.evalExpr(scope, branch[0], depth + 1)
  of nkStmtListExpr, nkStmtList:
    if n.len == 1: result = c.evalExpr(scope, n[0], depth + 1)
  else: discard

proc lookup(c: ConstContext; scope: ConstScope; name: string; depth: int): ConstValue =
  result = ConstValue()
  if depth > 64: return
  let id = c.cache.getIdent(name).id
  if id in scope.blocked: return
  if scope.values.hasKey(id): return scope.values[id]
  if not scope.declarations.hasKey(id): return c.builtinValue(scope, name)
  if id in scope.resolving: return
  scope.resolving.incl id
  defer: scope.resolving.excl id
  let declaration = scope.declarations[id]
  if declaration.len != 3: return
  if declaration[1].kind != nkEmpty and
     nodeName(declaration[1]) notin ["bool", "string", "int"]:
    return
  var defineKind = ""
  var defineName = name
  var head = declaration[0]
  if head.kind == nkPragmaExpr:
    for pragma in head[1]:
      let key = if pragma.kind in nkPragmaCallKinds: nodeName(pragma[0]) else: nodeName(pragma)
      if key in ["strdefine", "intdefine", "booldefine"]:
        defineKind = key
        if pragma.kind in nkPragmaCallKinds:
          if pragma.len != 2 or pragma[1].kind notin {nkStrLit..nkTripleStrLit}: return
          defineName = pragma[1].strVal
      elif key notin ["used", "deprecated"]:
        return
  if defineKind.len > 0 and isDefined(c.config, defineName):
    let raw = c.config.symbols[defineName]
    try:
      case defineKind
      of "strdefine": result = stringConst(raw)
      of "intdefine": result = intConst(raw.parseInt())
      of "booldefine": result = boolConst(raw.parseBool())
      else: discard
    except ValueError:
      return
  else:
    result = c.evalExpr(scope, declaration[2], depth + 1)
  if result.kind != ckUnknown: scope.values[id] = result

proc parseSource(c: ConstContext; filename: string): PNode =
  result = nil
  proc onError(conf: ConfigRef; info: TLineInfo; msg: TMsgKind; arg: string) =
    if msg in errMin..errMax: raise newException(ConstParseError, "unsupported source")
  try:
    result = parseString(readFile(filename), c.cache, c.config, filename, errorHandler = onError)
  except IOError, OSError, ConstParseError:
    discard

proc importNames(n: PNode): seq[string] =
  result = @[]
  case n.kind
  of nkIdent: result.add n.ident.s
  of nkStrLit..nkTripleStrLit: result.add n.strVal
  of nkImportAs:
    if n.len > 0: result = importNames(n[0])
  of nkInfix:
    if n.len == 3:
      if nodeName(n[0]) == "as": result = importNames(n[1])
      else:
        let left = importNames(n[1])
        if left.len == 1:
          for right in importNames(n[2]): result.add left[0] & "/" & right
  of nkPrefix:
    if n.len == 2:
      for path in importNames(n[1]): result.add nodeName(n[0]) & path
  of nkBracket:
    for child in n: result.add importNames(child)
  else: discard

proc importedPath(c: ConstContext; origin, name: string): string =
  var name = name
  if '$' in name:
    try: name = pathSubs(c.config, name, origin.parentDir)
    except ValueError: return ""
  findModule(c.config, name, origin).string

proc moduleOperators(c: ConstContext; filename: string): HashSet[string]
proc includePath(c: ConstContext; filename: string; n: PNode): string

proc collectOperatorImports(c: ConstContext; n: PNode; filename: string;
                            aliases: var Table[string, string]): HashSet[string] =
  ## Imported overloads need semantic overload resolution. Stay unknown even
  ## when an overload might only accept some other type.
  result = initHashSet[string]()
  if n == nil: return
  if n.kind in {nkImportStmt, nkImportExceptStmt, nkFromStmt}:
    let count = if n.kind == nkImportStmt: n.len else: min(n.len, 1)
    for i in 0..<count:
      for name in importNames(n[i]):
        let path = c.importedPath(filename, name)
        if path.len > 0 and path != filename:
          aliases[name.lastPathPart] = path
          if n[i].kind == nkImportAs and n[i].len == 2:
            aliases[nodeName(n[i][1])] = path
          result.incl c.moduleOperators(path)
  # A procedure/template body has a different import scope.
  if n.kind notin callableDefs:
    for i in 0..<n.safeLen:
      result.incl c.collectOperatorImports(n[i], filename, aliases)

proc exportedOperators(c: ConstContext; n: PNode; filename: string;
                       aliases: Table[string, string]): HashSet[string] =
  result = initHashSet[string]()
  if n == nil: return
  # An included file can add overloads to the exporting module too.
  if n.kind == nkIncludeStmt:
    for child in n:
      let path = c.includePath(filename, child)
      if path.len > 0: result.incl c.moduleOperators(path)
      else: result.incl toHashSet(guardOperators)
  if n.kind in routineDefs and n.len > 0 and nodeName(n[0]) in guardOperators:
    result.incl nodeName(n[0])
  if n.kind == nkExportStmt:
    for child in n:
      let name = nodeName(child)
      if name in guardOperators: result.incl name
      let path = aliases.getOrDefault(name, c.importedPath(filename, name))
      if path.len > 0 and path != filename: result.incl c.moduleOperators(path)
  if n.kind notin callableDefs:
    for i in 0..<n.safeLen:
      result.incl c.exportedOperators(n[i], filename, aliases)

proc moduleOperators(c: ConstContext; filename: string): HashSet[string] =
  if c.operatorModules.hasKey(filename): return c.operatorModules[filename]
  # A re-export cycle is ambiguous until sem has built the module interfaces.
  c.operatorModules[filename] = toHashSet(guardOperators)
  let tree = c.parseSource(filename)
  var aliases = initTable[string, string]()
  if tree == nil: return toHashSet(guardOperators)
  discard c.collectOperatorImports(tree, filename, aliases)
  result = c.exportedOperators(tree, filename, aliases)
  c.operatorModules[filename] = result

proc includePath(c: ConstContext; filename: string; n: PNode): string =
  result = ""
  let names = importNames(n)
  if names.len == 1:
    let name = names[0]
    let local = filename.parentDir / name.addFileExt("nim")
    if fileExists(local): return local
    for path in c.config.searchPaths:
      let candidate = path.string / name.addFileExt("nim")
      if fileExists(candidate): return candidate
    let found = c.importedPath(filename, name)
    if found.len > 0 and fileExists(found): return found

proc collectDeclarations(c: ConstContext; scope: ConstScope; n: PNode; filename: string)

proc collectFile(c: ConstContext; scope: ConstScope; filename: string) =
  if filename in scope.includes:
    scope.valid = false
    return
  scope.includes.add filename
  defer: scope.includes.setLen(scope.includes.len - 1)
  let tree = c.parseSource(filename)
  if tree == nil:
    scope.valid = false
  else:
    c.collectBindings(scope, tree, true)
    var aliases = initTable[string, string]()
    scope.shadowedOperators.incl c.collectOperatorImports(tree, filename, aliases)
    c.collectDeclarations(scope, tree, filename)

proc blockDeclarations(c: ConstContext; scope: ConstScope; n: PNode) =
  if n == nil: return
  if n.kind == nkConstDef and n.len > 0: c.blockName(scope, n[0])
  if n.kind == nkIncludeStmt:
    # An undecidable include may declare names that shadow known constants.
    scope.valid = false
  for i in 0..<n.safeLen: c.blockDeclarations(scope, n[i])

proc collectDeclarations(c: ConstContext; scope: ConstScope; n: PNode; filename: string) =
  if n == nil: return
  case n.kind
  of nkStmtList, nkConstSection:
    for child in n: c.collectDeclarations(scope, child, filename)
  of nkConstDef:
    if n.len == 3:
      let name = nodeName(n[0])
      if name.len > 0:
        let id = c.cache.getIdent(name).id
        if scope.declarations.hasKey(id): scope.blocked.incl id
        else: scope.declarations[id] = n
  of nkWhenStmt:
    for branch in n:
      if branch.kind == nkElifBranch and branch.len == 2:
        let cond = c.evalExpr(scope, branch[0], 0)
        if cond.kind != ckBool:
          c.blockDeclarations(scope, n)
          return
        if cond.boolVal:
          c.collectDeclarations(scope, branch[1], filename)
          return
      elif branch.kind == nkElse and branch.len == 1:
        c.collectDeclarations(scope, branch[0], filename)
        return
  of nkIncludeStmt:
    for child in n:
      let path = c.includePath(filename, child)
      if path.len == 0: scope.valid = false
      else: c.collectFile(scope, path)
  else: discard

proc constantScope(c: ConstContext; filename: string; isMain: bool): ConstScope =
  let key = (filename, isMain)
  if not c.scopes.hasKey(key):
    let scope = ConstScope(filename: filename, isMain: isMain, valid: true)
    c.scopes[key] = scope
    for name in c.config.implicitImports:
      let path = c.importedPath(filename, name)
      if path.len > 0 and path != filename:
        scope.shadowedOperators.incl c.moduleOperators(path)
    c.collectFile(scope, filename)
  result = c.scopes[key]

proc operationKnown*(c: ConstContext; filename, op: string; isMain = false): bool =
  ## Without semantic overload resolution, custom operators must stay unknown.
  let scope = c.constantScope(filename, isMain)
  result = scope.valid and op notin scope.shadowedOperators

proc getConstValue*(c: ConstContext; filename, name: string; isMain = false): ConstValue =
  ## Resolve simple declarations in this module and its selected includes.
  ## Imported constants, calls, type operations, and ambiguous bindings need sem.
  result = ConstValue()
  let scope = c.constantScope(filename, isMain)
  if scope.valid: result = c.lookup(scope, name, 0)
