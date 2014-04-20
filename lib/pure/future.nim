#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements experimental features which may soon be moved to
## the system module (or other more appropriate modules).

import macros

proc createProcType(p, b: PNimrodNode): PNimrodNode {.compileTime.} =
  #echo treeRepr(p)
  #echo treeRepr(b)
  result = newNimNode(nnkProcTy)
  var formalParams = newNimNode(nnkFormalParams)

  expectKind(b, nnkIdent)
  formalParams.add b

  case p.kind
  of nnkPar:
    for i in 0 .. <p.len:
      let ident = p[i]
      var identDefs = newNimNode(nnkIdentDefs)
      case ident.kind
      of nnkExprColonExpr:
        identDefs.add ident[0]
        identDefs.add ident[1]
      of nnkIdent:
        identDefs.add newIdentNode("i" & $i)
        identDefs.add(ident)
      else:
        error("Incorrect type list in proc type declaration.")
      identDefs.add newEmptyNode()
      formalParams.add identDefs
  of nnkIdent:
    var identDefs = newNimNode(nnkIdentDefs)
    identDefs.add newIdentNode("i0")
    identDefs.add(p)
    identDefs.add newEmptyNode()
    formalParams.add identDefs
  else:
    error("Incorrect type list in proc type declaration.")
  
  result.add formalParams
  result.add newEmptyNode()
  #echo(treeRepr(result))
  #echo(result.toStrLit())

macro `=>`*(p, b: expr): expr {.immediate.} =
  ## Syntax sugar for anonymous procedures.
  ##
  ## ..code-block:: nimrod
  ##
  ##   proc passTwoAndTwo(f: (int, int) -> int): int =
  ##     f(2, 2)
  ##
  ##   passTwoAndTwo((x, y) => x + y) # 4
  
  #echo treeRepr(p)
  #echo(treeRepr(b))
  var params: seq[PNimrodNode] = @[newIdentNode("auto")]

  case p.kind
  of nnkPar:
    for c in children(p):
      var identDefs = newNimNode(nnkIdentDefs)
      case c.kind
      of nnkExprColonExpr:
        identDefs.add(c[0])
        identDefs.add(c[1])
        identDefs.add(newEmptyNode())
      of nnkIdent:
        identDefs.add(c)
        identDefs.add(newEmptyNode())
        identDefs.add(newEmptyNode())
      else:
        error("Incorrect procedure parameter list.")
      params.add(identDefs)
  of nnkIdent:
    var identDefs = newNimNode(nnkIdentDefs)
    identDefs.add(p)
    identDefs.add(newEmptyNode())
    identDefs.add(newEmptyNode())
    params.add(identDefs)
  of nnkInfix:
    if p[0].kind == nnkIdent and p[0].ident == !"->":
      var procTy = createProcType(p[1], p[2])
      params[0] = procTy[0][0]
      for i in 1 .. <procTy[0].len:
        params.add(procTy[0][i])
    else:
      error("Expected proc type (->) got (" & $p[0].ident & ").")
  else:
    error("Incorrect procedure parameter list.")
  result = newProc(params = params, body = b, procType = nnkLambda)
  #echo(result.treeRepr)
  #echo(result.toStrLit())
  #return result # TODO: Bug?

macro `->`*(p, b: expr): expr {.immediate.} =
  ## Syntax sugar for procedure types.
  ##
  ## ..code-block:: nimrod
  ##
  ##   proc pass2(f: (float, float) -> float): float =
  ##     f(2, 2)
  ##   
  ##   # is the same as:
  ##
  ##   proc pass2(f: proc (x, y: float): float): float =
  ##     f(2, 2)

  createProcType(p, b)
