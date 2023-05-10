#
#
#           The Nim Compiler
#        (c) Copyright 2022 Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Resolve paths using `ConfigRef.searchPaths` and `ConfigRef.lazyPaths`.

import
  std/[os, strutils, strtabs],
  renderer, options, lineinfos, pathutils

proc resolveAgainstSearchPaths(conf: ConfigRef; f: RelativeFile; suppressStdlib: bool): AbsoluteFile =
  for it in conf.searchPaths:
    if suppressStdlib and it.string.startsWith(conf.libpath.string):
      continue
    result = it / f
    if fileExists(result):
      return canonicalizePath(conf, result)
  result = AbsoluteFile""

proc resolveAgainstLazyPaths(conf: ConfigRef; f: RelativeFile): AbsoluteFile =
  for i, it in conf.lazyPaths:
    result = it / f
    if fileExists(result):
      # bring to front
      for j in countdown(i, 1):
        swap(conf.lazyPaths[j], conf.lazyPaths[j-1])
      return canonicalizePath(conf, result)
  result = AbsoluteFile""

template patchPath*(conf: ConfigRef) =
  # This is only exported for use by `modulepaths.patchModulePath`
  if not result.isEmpty and conf.moduleOverrides.len > 0:
    let key = getPackageName(conf, result.string) & "_" & splitFile(result).name
    if conf.moduleOverrides.hasKey(key):
      let ov = AbsoluteFile(conf.moduleOverrides[key])
      if not ov.isEmpty:
        result = ov

proc findFile*(conf: ConfigRef; f: string; suppressStdlib = false,
               lineInfo = unknownLineInfo, patch = true): AbsoluteFile =
  ## Resolve `f` against the module search paths to a canonical absolute form.
  ## `f` doesn't have to be a module path.
  ##
  ## Params:
  ## * `suppressStdlib`: When true, then no path in `ConfigRef.searchPaths` that
  ## is a subpath of `ConfigRef.libdir` is used for path resolution.
  ## * `lineInfo`: Source location of the path.
  ## * `patch`: When true, then any matching path overrides defined using
  ## `nimscript.patchFile` will replace the actual path.
  ##
  ## See Also:
  ## * `modulepaths.findModule`
  ## * `nimscript.patchFile`
  if f.isAbsolute:
    result = if f.fileExists: AbsoluteFile(f) else: AbsoluteFile""
  else:
    result = resolveAgainstSearchPaths(conf, RelativeFile f, suppressStdlib)
    if result.isEmpty:
      result = resolveAgainstSearchPaths(conf, RelativeFile f.toLowerAscii, suppressStdlib)
      if result.isEmpty:
        result = resolveAgainstLazyPaths(conf, RelativeFile f)
        if result.isEmpty:
          result = resolveAgainstLazyPaths(conf, RelativeFile f.toLowerAscii)
  if patch: # For `nimscript.patchFile`
    patchPath(conf)
