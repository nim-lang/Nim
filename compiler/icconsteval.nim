#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Direct boolean constants for the IC dependency scanner. Operators, calls,
## type conversions, and other expressions need semantic analysis.

import std/[os, tables, sets, strutils, strtabs, syncio]
import ast, idents, options, parser, lineinfos

type
  ConstKind* = enum
    ckUnknown, ckBool
  ConstValue* = object
    case kind*: ConstKind
    of ckBool: boolVal*: bool
    of ckUnknown: discard
  ConstScope = ref object
    valid: bool
    declarations: Table[int, PNode]
    values: Table[int, ConstValue]
    blocked, resolving: HashSet[int]
    includes: seq[string]
  ConstContext* = ref object
    config: ConfigRef
    cache: IdentCache
    scopes: Table[string, ConstScope]
  ConstParseError = object of CatchableError

proc newConstContext*(config: ConfigRef): ConstContext =
  ConstContext(config: config, cache: newIdentCache())

proc nodeName(n: PNode): string =
  result = ""
  if n != nil:
    case n.kind
    of nkIdent: result = n.ident.s
    of nkPostfix, nkPragmaExpr:
      if n.len > 0: result = nodeName(n[if n.kind == nkPostfix: 1 else: 0])
    else: discard

proc blockName(c: ConstContext; scope: ConstScope; n: PNode) =
  let name = nodeName(n)
  if name.len > 0: scope.blocked.incl c.cache.getIdent(name).id

proc collectBindings(c: ConstContext; scope: ConstScope; n: PNode; moduleScope: bool) =
  ## Local and generic bindings can shadow a module constant. Leave their names
  ## unknown throughout this module rather than approximating semantic scopes.
  if n == nil: return
  case n.kind
  of nkStmtList, nkConstSection:
    for child in n: c.collectBindings(scope, child, moduleScope)
  of nkWhenStmt:
    for branch in n:
      for child in branch: c.collectBindings(scope, child, moduleScope)
  of nkConstDef:
    if not moduleScope and n.len > 0: c.blockName(scope, n[0])
    for i in 1..<n.len: c.collectBindings(scope, n[i], false)
  of nkIdentDefs, nkVarTuple, nkForStmt, nkParForStmt:
    for i in 0..<max(0, n.len - 2): c.blockName(scope, n[i])
    for child in n: c.collectBindings(scope, child, false)
  of routineDefs, nkTypeDef:
    if n.len > 0: c.blockName(scope, n[0])
    for child in n: c.collectBindings(scope, child, false)
  else:
    for i in 0..<n.safeLen: c.collectBindings(scope, n[i], false)

proc lookup(c: ConstContext; scope: ConstScope; name: string; depth: int): ConstValue

proc directValue(c: ConstContext; scope: ConstScope; n: PNode; depth: int): ConstValue =
  result = ConstValue()
  if n == nil or depth > 64: return
  case n.kind
  of nkIdent: result = c.lookup(scope, n.ident.s, depth + 1)
  of nkPar:
    if n.len == 1: result = c.directValue(scope, n[0], depth + 1)
  else: discard

proc lookup(c: ConstContext; scope: ConstScope; name: string; depth: int): ConstValue =
  result = ConstValue()
  if depth > 64: return
  let id = c.cache.getIdent(name).id
  if id in scope.blocked: return
  if scope.values.hasKey(id): return scope.values[id]
  if not scope.declarations.hasKey(id):
    case name
    of "true": return ConstValue(kind: ckBool, boolVal: true)
    of "false": return ConstValue(kind: ckBool, boolVal: false)
    else: return
  if id in scope.resolving: return
  scope.resolving.incl id
  defer: scope.resolving.excl id
  let declaration = scope.declarations[id]
  # An explicit type can name a user-defined type and involve conversions.
  if declaration.len != 3 or declaration[1].kind != nkEmpty: return
  var defineName = name
  var boolDefine = false
  let head = declaration[0]
  if head.kind == nkPragmaExpr:
    for pragma in head[1]:
      let key = if pragma.kind in nkPragmaCallKinds: nodeName(pragma[0]) else: nodeName(pragma)
      if key == "booldefine":
        boolDefine = true
        if pragma.kind in nkPragmaCallKinds:
          if pragma.len != 2 or pragma[1].kind notin {nkStrLit..nkTripleStrLit}: return
          defineName = pragma[1].strVal
      elif key notin ["used", "deprecated"]:
        return
  result = c.directValue(scope, declaration[2], depth + 1)
  if result.kind != ckBool: return
  if boolDefine and isDefined(c.config, defineName):
    try:
      result = ConstValue(kind: ckBool, boolVal: c.config.symbols[defineName].parseBool())
    except ValueError:
      return ConstValue()
  scope.values[id] = result

proc parseSource(c: ConstContext; filename: string): PNode =
  result = nil
  proc onError(conf: ConfigRef; info: TLineInfo; msg: TMsgKind; arg: string) =
    if msg in errMin..errMax: raise newException(ConstParseError, "unsupported source")
  try:
    result = parseString(readFile(filename), c.cache, c.config, filename, errorHandler = onError)
  except IOError, OSError, ConstParseError:
    discard

proc includeName(n: PNode): string =
  ## Include paths use import-path syntax, not value expressions.
  result = ""
  case n.kind
  of nkIdent: result = n.ident.s
  of nkStrLit..nkTripleStrLit: result = n.strVal
  of nkInfix:
    if n.len == 3 and nodeName(n[0]) == "/":
      let left = includeName(n[1])
      let right = includeName(n[2])
      if left.len > 0 and right.len > 0: result = left & "/" & right
  of nkPrefix:
    if n.len == 2 and nodeName(n[0]) in ["/", "./", "../"]:
      let suffix = includeName(n[1])
      if suffix.len > 0: result = nodeName(n[0]) & suffix
  else: discard

proc includePath(c: ConstContext; filename: string; n: PNode): string =
  result = ""
  let name = includeName(n)
  if name.len > 0:
    let local = filename.parentDir / name.addFileExt("nim")
    if fileExists(local): return local
    for path in c.config.searchPaths:
      let candidate = path.string / name.addFileExt("nim")
      if fileExists(candidate): return candidate
    let found = findModule(c.config, name, filename).string
    if found.len > 0 and fileExists(found): return found

proc collectDeclarations(c: ConstContext; scope: ConstScope; n: PNode; filename: string)

proc collectFile(c: ConstContext; scope: ConstScope; filename: string) =
  if filename in scope.includes or scope.includes.len >= 64:
    scope.valid = false
    return
  scope.includes.add filename
  defer: scope.includes.setLen(scope.includes.len - 1)
  let tree = c.parseSource(filename)
  if tree == nil:
    scope.valid = false
  else:
    c.collectBindings(scope, tree, true)
    c.collectDeclarations(scope, tree, filename)

proc blockDeclarations(c: ConstContext; scope: ConstScope; n: PNode) =
  if n == nil: return
  if n.kind == nkConstDef and n.len > 0: c.blockName(scope, n[0])
  if n.kind == nkIncludeStmt: scope.valid = false
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
        let cond = c.directValue(scope, branch[0], 0)
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

proc getConstValue*(c: ConstContext; filename, name: string): ConstValue =
  ## Only direct inferred boolean values and local aliases are resolved.
  result = ConstValue()
  if not c.scopes.hasKey(filename):
    let scope = ConstScope(valid: true)
    c.scopes[filename] = scope
    c.collectFile(scope, filename)
  let scope = c.scopes[filename]
  if scope.valid: result = c.lookup(scope, name, 0)
