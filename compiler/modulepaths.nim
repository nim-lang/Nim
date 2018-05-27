#
#
#           The Nim Compiler
#        (c) Copyright 2017 Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, renderer, strutils, msgs, options, idents, os, lineinfos

import nimblecmd

when false:
  const
    considerParentDirs = not defined(noParentProjects)
    considerNimbleDirs = not defined(noNimbleDirs)

  proc findInNimbleDir(pkg, subdir, dir: string): string =
    var best = ""
    var bestv = ""
    for k, p in os.walkDir(dir, relative=true):
      if k == pcDir and p.len > pkg.len+1 and
          p[pkg.len] == '-' and p.startsWith(pkg):
        let (_, a) = getPathVersion(p)
        if bestv.len == 0 or bestv < a:
          bestv = a
          best = dir / p

    if best.len > 0:
      var f: File
      if open(f, best / changeFileExt(pkg, ".nimble-link")):
        # the second line contains what we're interested in, see:
        # https://github.com/nim-lang/nimble#nimble-link
        var override = ""
        discard readLine(f, override)
        discard readLine(f, override)
        close(f)
        if not override.isAbsolute():
          best = best / override
        else:
          best = override
    let f = if subdir.len == 0: pkg else: subdir
    let res = addFileExt(best / f, "nim")
    if best.len > 0 and fileExists(res):
      result = res

const stdlibDirs = [
  "pure", "core", "arch",
  "pure/collections",
  "pure/concurrency", "impure",
  "wrappers", "wrappers/linenoise",
  "windows", "posix", "js"]

when false:
  proc resolveDollar(project, source, pkg, subdir: string; info: TLineInfo): string =
    template attempt(a) =
      let x = addFileExt(a, "nim")
      if fileExists(x): return x

    case pkg
    of "stdlib":
      if subdir.len == 0:
        return options.libpath
      else:
        for candidate in stdlibDirs:
          attempt(options.libpath / candidate / subdir)
    of "root":
      let root = project.splitFile.dir
      if subdir.len == 0:
        return root
      else:
        attempt(root / subdir)
    else:
      when considerParentDirs:
        var p = parentDir(source.splitFile.dir)
        # support 'import $karax':
        let f = if subdir.len == 0: pkg else: subdir

        while p.len > 0:
          let dir = p / pkg
          if dirExists(dir):
            attempt(dir / f)
            # 2nd attempt: try to use 'karax/karax'
            attempt(dir / pkg / f)
            # 3rd attempt: try to use 'karax/src/karax'
            attempt(dir / "src" / f)
            attempt(dir / "src" / pkg / f)
          p = parentDir(p)

      when considerNimbleDirs:
        if not options.gNoNimblePath:
          var nimbleDir = getEnv("NIMBLE_DIR")
          if nimbleDir.len == 0: nimbleDir = getHomeDir() / ".nimble"
          result = findInNimbleDir(pkg, subdir, nimbleDir / "pkgs")
          if result.len > 0: return result
          when not defined(windows):
            result = findInNimbleDir(pkg, subdir, "/opt/nimble/pkgs")
            if result.len > 0: return result

  proc scriptableImport(pkg, sub: string; info: TLineInfo): string =
    result = resolveDollar(gProjectFull, info.toFullPath(), pkg, sub, info)
    if result.isNil: result = ""

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

proc getModuleName*(conf: ConfigRef; n: PNode): string =
  # This returns a short relative module name without the nim extension
  # e.g. like "system", "importer" or "somepath/module"
  # The proc won't perform any checks that the path is actually valid
  case n.kind
  of nkStrLit, nkRStrLit, nkTripleStrLit:
    try:
      result = pathSubs(conf, n.strVal, toFullPath(conf, n.info).splitFile().dir)
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
    if n0.kind == nkIdent and n0.ident.s == "as":
      # XXX hack ahead:
      n.kind = nkImportAs
      n.sons[0] = n.sons[1]
      n.sons[1] = n.sons[2]
      n.sons.setLen(2)
      return getModuleName(conf, n.sons[0])
    when false:
      if n1.kind == nkPrefix and n1[0].kind == nkIdent and n1[0].ident.s == "$":
        if n0.kind == nkIdent and n0.ident.s == "/":
          result = lookupPackage(n1[1], n[2])
        else:
          localError(n.info, "only '/' supported with $package notation")
          result = ""
    else:
      let modname = getModuleName(conf, n[2])
      if $n1 == "std":
        template attempt(a) =
          let x = addFileExt(a, "nim")
          if fileExists(x): return x
        for candidate in stdlibDirs:
          attempt(conf.libpath / candidate / modname)

      # hacky way to implement 'x / y /../ z':
      result = getModuleName(conf, n1)
      result.add renderTree(n0, {renderNoComments})
      result.add modname
  of nkPrefix:
    when false:
      if n.sons[0].kind == nkIdent and n.sons[0].ident.s == "$":
        result = lookupPackage(n[1], nil)
      else:
        discard
    # hacky way to implement 'x / y /../ z':
    result = renderTree(n, {renderNoComments}).replace(" ")
  of nkDotExpr:
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
  if fullPath.len == 0:
    if doLocalError:
      let m = if modulename.len > 0: modulename else: $n
      localError(conf, n.info, "cannot open file: " & m)
    result = InvalidFileIDX
  else:
    result = fileInfoIdx(conf, fullPath)
