#
#
#           The Nim Compiler
#        (c) Copyright 2017 Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, renderer, strutils, msgs, options, idents, os, lineinfos,
  pathutils

proc getModuleName*(conf: ConfigRef; n: PNode): string =
  # This returns a short relative module name without the nim extension
  # e.g. like "system", "importer" or "somepath/module"
  # The proc won't perform any checks that the path is actually valid
  case n.kind
  of nkStrLit, nkRStrLit, nkTripleStrLit:
    try:
      result =
        pathSubs(conf, n.strVal, toFullPath(conf, n.info).splitFile().dir)
    except ValueError:
      localError(conf, n.info, "invalid path: " & n.strVal)
      result = n.strVal
  of nkIdent:
    result = n.ident.s
  of nkSym:
    result = n.sym.name.s
  of nkInfix:
    let n0 = n[0]
    let n1 = n[1]
    let modname = getModuleName(conf, n[2])
    # hacky way to implement 'x / y /../ z':
    result = getModuleName(conf, n1)
    result.add renderTree(n0, {renderNoComments}).replace(" ")
    result.add modname
  of nkPrefix:
    # hacky way to implement 'x / y /../ z':
    result = renderTree(n, {renderNoComments}).replace(" ")
  of nkDotExpr:
    localError(conf, n.info, warnDeprecated, "using '.' instead of '/' in import paths is deprecated")
    result = renderTree(n, {renderNoComments}).replace(".", "/")
  of nkImportAs:
    result = getModuleName(conf, n.sons[0])
  else:
    localError(conf, n.info, "invalid module name: '$1'" % n.renderTree)
    result = ""

proc checkModuleName*(conf: ConfigRef; n: PNode; doLocalError=true): FileIndex =
  # This returns the full canonical path for a given module import
  let modulename = getModuleName(conf, n)
  let fullPath = findModule(conf, modulename, toFullPath(conf, n.info))
  if fullPath.isEmpty:
    if doLocalError:
      let m = if modulename.len > 0: modulename else: $n
      localError(conf, n.info, "cannot open file: " & m)
    result = InvalidFileIdx
  else:
    result = fileInfoIdx(conf, fullPath)
