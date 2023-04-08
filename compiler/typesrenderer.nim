#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import renderer, strutils, ast, types

when defined(nimPreviewSlimSystem):
  import std/assertions


const defaultParamSeparator* = ","

template mayNormalize(s: string): string =
  if toNormalize:
    s.nimIdentNormalize
  else:
    s

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

proc renderType(n: PNode, toNormalize: bool): string =
  ## Returns a string with the node type or the empty string.
  ## This proc should be kept in sync with `toLangSymbols` from
  ## ``lib/packages/docutils/dochelpers.nim``.
  case n.kind:
  of nkIdent: result = mayNormalize(n.ident.s)
  of nkSym: result = mayNormalize(typeToString(n.sym.typ))
  of nkVarTy:
    if n.len == 1:
      result = renderType(n[0], toNormalize)
    else:
      result = "var"
  of nkRefTy:
    if n.len == 1:
      result = "ref." & renderType(n[0], toNormalize)
    else:
      result = "ref"
  of nkPtrTy:
    if n.len == 1:
      result = "ptr." & renderType(n[0], toNormalize)
    else:
      result = "ptr"
  of nkProcTy:
    assert n.len != 1
    if n.len > 1 and n[0].kind == nkFormalParams:
      let params = n[0]
      assert params.len > 0
      result = "proc("
      for i in 1..<params.len: result.add(renderType(params[i], toNormalize) & ',')
      result[^1] = ')'
    else:
      result = "proc"
  of nkIdentDefs:
    assert n.len >= 3
    let typePos = n.len - 2
    let typeStr = renderType(n[typePos], toNormalize)
    result = typeStr
    for i in 1..<typePos:
      assert n[i].kind in {nkSym, nkIdent}
      result.add(',' & typeStr)
  of nkTupleTy:
    result = "tuple["
    for i in 0..<n.len: result.add(renderType(n[i], toNormalize) & ',')
    result[^1] = ']'
  of nkBracketExpr:
    assert n.len >= 2
    result = renderType(n[0], toNormalize) & '['
    for i in 1..<n.len: result.add(renderType(n[i], toNormalize) & ',')
    result[^1] = ']'
  of nkCommand:
    result = renderType(n[0], toNormalize)
    for i in 1..<n.len:
      if i > 1: result.add ", "
      result.add(renderType(n[i], toNormalize))
  else: result = ""


proc renderParamNames*(n: PNode, toNormalize=false): seq[string] =
  ## Returns parameter names of routine `n`.
  doAssert n.kind == nkFormalParams
  case n.kind
  of nkFormalParams:
    for i in 1..<n.len:
      if n[i].kind == nkIdentDefs:
        # These are parameter names + type + default value node.
        let typePos = n[i].len - 2
        for j in 0..<typePos:
          result.add mayNormalize($n[i][j])
      else:  # error
        result.add($n[i])
  else:  #error
    result.add $n


proc renderParamTypes*(found: var seq[string], n: PNode, toNormalize=false) =
  ## Recursive helper, adds to `found` any types, or keeps diving the AST.
  ##
  ## The normal `doc` generator doesn't include .typ information, so the
  ## function won't render types for parameters with default values. The `doc`
  ## generator does include the information.
  case n.kind
  of nkFormalParams:
    for i in 1..<n.len: renderParamTypes(found, n[i], toNormalize)
  of nkIdentDefs:
    # These are parameter names + type + default value node.
    let typePos = n.len - 2
    assert typePos > 0
    var typeStr = renderType(n[typePos], toNormalize)
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

proc renderParamTypes*(n: PNode, sep = defaultParamSeparator,
                       toNormalize=false): string =
  ## Returns the types contained in `n` joined by `sep`.
  ##
  ## This proc expects to be passed as `n` the parameters of any callable. The
  ## string output is meant for the HTML renderer. If there are no parameters,
  ## the empty string is returned. The parameters will be joined by `sep` but
  ## other characters may appear too, like ``[]`` or ``|``.
  result = ""
  var found: seq[string] = @[]
  renderParamTypes(found, n, toNormalize)
  if found.len > 0:
    result = found.join(sep)

proc renderOutType*(n: PNode, toNormalize=false): string =
  assert n.kind == nkFormalParams
  result = renderType(n[0], toNormalize)
