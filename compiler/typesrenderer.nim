#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import renderer, strutils, ast, types

const defaultParamSeparator* = ","

proc renderPlainSymbolName*(n: PNode): string =
  ## Returns the first non '*' nkIdent node from the tree.
  ##
  ## Use this on documentation name nodes to extract the *raw* symbol name,
  ## without decorations, parameters, or anything. That can be used as the base
  ## for the HTML hyperlinks.
  case n.kind
  of nkPostfix, nkAccQuoted:
    result = renderPlainSymbolName(n[^1])
  of nkIdent:
    result = n.ident.s
  of nkSym:
    result = n.sym.renderDefinitionName(noQuotes = true)
  of nkPragmaExpr:
    result = renderPlainSymbolName(n[0])
  else:
    result = ""
    #internalError(n.info, "renderPlainSymbolName() with " & $n.kind)

proc renderType(n: PNode): string =
  ## Returns a string with the node type or the empty string.
  case n.kind:
  of nkIdent: result = n.ident.s
  of nkSym: result = typeToString(n.sym.typ)
  of nkVarTy:
    if n.len == 1:
      result = renderType(n[0])
    else:
      result = "var"
  of nkRefTy:
    if n.len == 1:
      result = "ref." & renderType(n[0])
    else:
      result = "ref"
  of nkPtrTy:
    if n.len == 1:
      result = "ptr." & renderType(n[0])
    else:
      result = "ptr"
  of nkProcTy:
    assert n.len != 1
    if n.len > 1:
      let params = n[0]
      assert params.kind == nkFormalParams
      assert params.len > 0
      result = "proc("
      for i in 1..<params.len: result.add(renderType(params[i]) & ',')
      result[^1] = ')'
    else:
      result = "proc"
  of nkIdentDefs:
    assert n.len >= 3
    let typePos = n.len - 2
    let typeStr = renderType(n[typePos])
    result = typeStr
    for i in 1..<typePos:
      assert n[i].kind in {nkSym, nkIdent}
      result.add(',' & typeStr)
  of nkTupleTy:
    result = "tuple["
    for i in 0..<n.len: result.add(renderType(n[i]) & ',')
    result[^1] = ']'
  of nkBracketExpr:
    assert n.len >= 2
    result = renderType(n[0]) & '['
    for i in 1..<n.len: result.add(renderType(n[i]) & ',')
    result[^1] = ']'
  of nkCommand:
    result = renderType(n[0])
    for i in 1..<n.len:
      if i > 1: result.add ", "
      result.add(renderType(n[i]))
  else: result = ""


proc renderParamTypes(found: var seq[string], n: PNode) =
  ## Recursive helper, adds to `found` any types, or keeps diving the AST.
  ##
  ## The normal `doc` generator doesn't include .typ information, so the
  ## function won't render types for parameters with default values. The `doc`
  ## generator does include the information.
  case n.kind
  of nkFormalParams:
    for i in 1..<n.len: renderParamTypes(found, n[i])
  of nkIdentDefs:
    # These are parameter names + type + default value node.
    let typePos = n.len - 2
    assert typePos > 0
    var typeStr = renderType(n[typePos])
    if typeStr.len < 1 and n[typePos+1].kind != nkEmpty:
      # Try with the last node, maybe its a default value.
      let typ = n[typePos+1].typ
      if not typ.isNil: typeStr = typeToString(typ, preferExported)
      if typeStr.len < 1: return
    for i in 0..<typePos:
      found.add(typeStr)
  else:
    found.add($n)
    #internalError(n.info, "renderParamTypes(found,n) with " & $n.kind)

proc renderParamTypes*(n: PNode, sep = defaultParamSeparator): string =
  ## Returns the types contained in `n` joined by `sep`.
  ##
  ## This proc expects to be passed as `n` the parameters of any callable. The
  ## string output is meant for the HTML renderer. If there are no parameters,
  ## the empty string is returned. The parameters will be joined by `sep` but
  ## other characters may appear too, like ``[]`` or ``|``.
  result = ""
  var found: seq[string] = @[]
  renderParamTypes(found, n)
  if found.len > 0:
    result = found.join(sep)
