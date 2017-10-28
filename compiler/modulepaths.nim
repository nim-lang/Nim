#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, renderer, gorgeimpl, strutils, msgs, options, idents, ospaths

proc lookupPackage(pkg, subdir: PNode): string =
  let sub = if subdir != nil: renderTree(subdir, {renderNoComments}).replace(" ") else: ""
  case pkg.kind
  of nkStrLit, nkRStrLit, nkTripleStrLit:
    result = scriptableImport(pkg.strVal, sub, pkg.info)
  of nkIdent:
    result = scriptableImport(pkg.ident.s, sub, pkg.info)
  else:
    localError(pkg.info, "package name must be an identifier or string literal")
    result = ""

proc getModuleName*(n: PNode): string =
  # This returns a short relative module name without the nim extension
  # e.g. like "system", "importer" or "somepath/module"
  # The proc won't perform any checks that the path is actually valid
  case n.kind
  of nkStrLit, nkRStrLit, nkTripleStrLit:
    try:
      result = pathSubs(n.strVal, n.info.toFullPath().splitFile().dir)
    except ValueError:
      localError(n.info, "invalid path: " & n.strVal)
      result = n.strVal
  of nkIdent:
    result = n.ident.s
  of nkSym:
    result = n.sym.name.s
  of nkInfix:
    let n0 = n[0]
    let n1 = n[1]
    if n0.kind == nkIdent and n0.ident.id == getIdent("as").id:
      # XXX hack ahead:
      n.kind = nkImportAs
      n.sons[0] = n.sons[1]
      n.sons[1] = n.sons[2]
      n.sons.setLen(2)
      return getModuleName(n.sons[0])
    if n1.kind == nkPrefix and n1[0].kind == nkIdent and n1[0].ident.s == "$":
      if n0.kind == nkIdent and n0.ident.s == "/":
        result = lookupPackage(n1[1], n[2])
      else:
        localError(n.info, "only '/' supported with $package notation")
        result = ""
    else:
      # hacky way to implement 'x / y /../ z':
      result = getModuleName(n1)
      result.add renderTree(n0, {renderNoComments})
      result.add getModuleName(n[2])
  of nkPrefix:
    if n.sons[0].kind == nkIdent and n.sons[0].ident.s == "$":
      result = lookupPackage(n[1], nil)
    else:
      # hacky way to implement 'x / y /../ z':
      result = renderTree(n, {renderNoComments}).replace(" ")
  of nkDotExpr:
    result = renderTree(n, {renderNoComments}).replace(".", "/")
  of nkImportAs:
    result = getModuleName(n.sons[0])
  else:
    localError(n.info, errGenerated, "invalid module name: '$1'" % n.renderTree)
    result = ""

proc checkModuleName*(n: PNode; doLocalError=true): int32 =
  # This returns the full canonical path for a given module import
  let modulename = n.getModuleName
  let fullPath = findModule(modulename, n.info.toFullPath)
  if fullPath.len == 0:
    if doLocalError:
      localError(n.info, errCannotOpenFile, modulename)
    result = InvalidFileIDX
  else:
    result = fullPath.fileInfoIdx