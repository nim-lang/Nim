#
#
#           The Nim Compiler
#        (c) Copyright 2017 Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  std/[os, strutils, strtabs],
  ast, renderer, msgs, options, idents, lineinfos, pathutils

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
    when false:
      if n1.kind == nkPrefix and n1[0].kind == nkIdent and n1[0].ident.s == "$":
        if n0.kind == nkIdent and n0.ident.s == "/":
          result = lookupPackage(n1[1], n[2])
        else:
          localError(n.info, "only '/' supported with $package notation")
          result = ""
    else:
      let modname = getModuleName(conf, n[2])
      # hacky way to implement 'x / y /../ z':
      result = getModuleName(conf, n1)
      result.add renderTree(n0, {renderNoComments}).replace(" ")
      result.add modname
  of nkPrefix:
    when false:
      if n[0].kind == nkIdent and n[0].ident.s == "$":
        result = lookupPackage(n[1], nil)
      else:
        discard
    # hacky way to implement 'x / y /../ z':
    result = renderTree(n, {renderNoComments}).replace(" ")
  of nkDotExpr:
    localError(conf, n.info, warnDeprecated, "using '.' instead of '/' in import paths is deprecated")
    result = renderTree(n, {renderNoComments}).replace(".", "/")
  of nkImportAs:
    result = getModuleName(conf, n[0])
  else:
    localError(conf, n.info, "invalid module name: '$1'" % n.renderTree)
    result = ""

proc mangleModuleName*(conf: ConfigRef; path: AbsoluteFile): string =
  ## Mangle a relative module path to avoid path and symbol collisions.
  ##
  ## Used by backends that need to generate intermediary files from Nim modules.
  ## This is needed because the compiler uses a flat cache file hierarchy.
  ##
  ## Example:
  ## `foo-#head/../bar` becomes `@foo-@hhead@s..@sbar`
  "@m" & relativeTo(path, conf.projectPath).string.multiReplace(
    {$os.DirSep: "@s", $os.AltSep: "@s", "#": "@h", "@": "@@", ":": "@c"})

proc demangleModuleName*(path: string): string =
  ## Demangle a relative module path.
  result = path.multiReplace({"@@": "@", "@h": "#", "@s": "/", "@m": "", "@c": ":"})

proc rawFindFile(conf: ConfigRef; f: RelativeFile; suppressStdlib: bool): AbsoluteFile =
  for it in conf.searchPaths:
    if suppressStdlib and it.string.startsWith(conf.libpath.string):
      continue
    result = it / f
    if fileExists(result):
      return canonicalizePath(conf, result)
  result = AbsoluteFile""

proc rawFindFile2(conf: ConfigRef; f: RelativeFile): AbsoluteFile =
  for i, it in conf.lazyPaths:
    result = it / f
    if fileExists(result):
      # bring to front
      for j in countdown(i, 1):
        swap(conf.lazyPaths[j], conf.lazyPaths[j-1])

      return canonicalizePath(conf, result)
  result = AbsoluteFile""

template patchModule(conf: ConfigRef) {.dirty.} =
  ## Checks if replacement or patch modules are defined for a module path.
  ## This dirty template uses `result` as the target module and `currentModule`
  ## as the module that is importing the target.
  ##
  ## A patch specified by `nimscript.patchModule` takes precedence over one
  ## specified by `nimscript.patchFile`.
  ##
  ## See Also:
  ## * `nimscript.patchFile`
  ## * `nimscript.patchModule`
  ## * `resolveModulePatches`
  template hintPatched(target, patch) =
    if hintPatch in conf.notes: # skip the `canonicalImport` work if not needed
      localError(conf, lineInfo, hintPatch, @[
                canonicalImport(conf, target),
                canonicalImport(conf, patch)])
  if not result.isEmpty:
    var matched = false
    if conf.modulePatches.len > 0:
      # This handles `nimscript.patchModule`.
      if conf.modulePatches.hasKey(result.string):
        let patch = AbsoluteFile(conf.modulePatches[result.string])
        # This conditional check is so `findModule` compares the current module
        # to the patch module so that the patch module can import the module
        # that it is patching. This is relevant to `nimscript.patchModule` only.
        when declared(currentModule):
          if patch.string != currentModule:
            hintPatched(result, patch)
            result = patch
            matched = true
        else:
          hintPatched(result, patch)
          result = patch
          matched = true
    if not matched and conf.moduleOverrides.len > 0:
      # This handles `nimscript.patchFile`.
      let key = getPackageName(conf, result.string) & "_" & splitFile(result).name
      if conf.moduleOverrides.hasKey(key):
        let ov = AbsoluteFile(conf.moduleOverrides[key])
        if not ov.isEmpty:
          hintPatched(result, ov)
          result = ov

proc findFile*(conf: ConfigRef; f: string; suppressStdlib = false,
               lineInfo = unknownLineInfo, patch = true): AbsoluteFile =
  if f.isAbsolute:
    result = if f.fileExists: AbsoluteFile(f) else: AbsoluteFile""
  else:
    result = rawFindFile(conf, RelativeFile f, suppressStdlib)
    if result.isEmpty:
      result = rawFindFile(conf, RelativeFile f.toLowerAscii, suppressStdlib)
      if result.isEmpty:
        result = rawFindFile2(conf, RelativeFile f)
        if result.isEmpty:
          result = rawFindFile2(conf, RelativeFile f.toLowerAscii)
  if patch:
    patchModule(conf)

proc findModule*(conf: ConfigRef; modulename, currentModule: string,
                 lineInfo = unknownLineInfo, patch = true): AbsoluteFile =
  # returns path to module
  var m = addFileExt(modulename, NimExt)
  if m.startsWith(pkgPrefix):
    result = findFile(conf, m.substr(pkgPrefix.len), true, lineInfo, false)
  else:
    if m.startsWith(stdPrefix):
      let stripped = m.substr(stdPrefix.len)
      for candidate in stdlibDirs:
        let path = (conf.libpath.string / candidate / stripped)
        if fileExists(path):
          result = AbsoluteFile path
          break
    else: # If prefixed with std/ why would we add the current module path!
      let currentPath = currentModule.splitFile.dir
      result = AbsoluteFile currentPath / m
    if not fileExists(result):
      result = findFile(conf, m, lineInfo = lineInfo, patch = false)
  if patch:
    patchModule(conf)

proc checkModuleName*(conf: ConfigRef; n: PNode; doLocalError=true): FileIndex =
  ## This returns the full canonical path for a given module import
  let modulename = getModuleName(conf, n)
  let fullPath = findModule(conf, modulename, toFullPath(conf, n.info), lineInfo = n.info)
  if fullPath.isEmpty:
    if doLocalError:
      let m = if modulename.len > 0: modulename else: $n
      localError(conf, n.info, "cannot open file: " & m)
    result = InvalidFileIdx
  else:
    result = fileInfoIdx(conf, fullPath)

proc resolveModulePatches*(conf: ConfigRef) =
  ## Resolve the target and patch module paths set with `nimscript.patchModule`.
  ## This resolution needs performed after all module search paths have been defined.
  ##
  ## See Also:
  ## * `nimscript.patchModule`
  ## * `patchModule`
  ## * `addModulePatch`
  for patch in conf.unresolvedModulePatches:
    var
      resolvedTarget = patch.target
      resolvedPatch = patch.patch
    if not patch.target.isAbsolute:
      resolvedTarget = findModule(conf, patch.target, conf.projectFull.string, patch = false).string
      if resolvedTarget.len == 0:
        localError(conf, patch.lineInfo, warnCannotOpen, patch.target)
        continue
    elif not resolvedTarget.fileExists:
      localError(conf, patch.lineInfo, warnCannotOpen, patch.target)
      continue
    if not patch.patch.isAbsolute:
      resolvedPatch = findModule(conf, patch.patch, conf.projectFull.string, patch = false).string
      if resolvedPatch.len == 0:
        localError(conf, patch.lineInfo, warnCannotOpen, patch.patch)
        continue
    elif not resolvedTarget.fileExists:
      localError(conf, patch.lineInfo, warnCannotOpen, patch.patch)
      continue
    if resolvedTarget.len > 0 and resolvedPatch.len > 0:
      conf.modulePatches[resolvedTarget] = resolvedPatch

proc resolveModuleToIndex*(conf: ConfigRef; module, relativeTo: string): FileIndex =
  let fullPath = findModule(conf, module, relativeTo)
  if fullPath.isEmpty:
    result = InvalidFileIdx
  else:
    result = fileInfoIdx(conf, fullPath)

proc addModulePatch*(conf: ConfigRef; target, patch, relativeTo: string; lineInfo = unknownLineInfo) =
  ## First, path substitutions are performed on `target` and `patch`.
  ## The target module path is resolved after all search paths are defined.
  ## The patch module path first tries to be resolved against the the current
  ## script's path, and then fallsback to normal path resolution like the target.
  ##
  ## See Also:
  ## * `nimscript.patchModule`
  ## * `patchModule`
  ## * `resolveModulePatches`
  var target = target
  var patch = patch
  if {'$', '~'} in target:
    target = pathSubs(conf, target, relativeTo)
  if {'$', '~'} in patch:
    patch = pathSubs(conf, patch, relativeTo)
  if not patch.isAbsolute:
    let absPatch = relativeTo / addFileExt(patch, NimExt)
    if fileExists(absPatch):
      patch = absPatch
  conf.unresolvedModulePatches.add (target, patch, lineInfo)
