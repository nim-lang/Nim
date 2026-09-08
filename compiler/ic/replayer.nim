#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Module that contains code to replay global VM state changes and pragma
## state like ``{.compile: "foo.c".}``. For IC (= Incremental compilation)
## support.

import ".." / [ast, modulegraphs, trees, extccomp, btrees,
  msgs, lineinfos, pathutils, options, cgmeth]

import std/[tables, os, strutils, syncio]

when defined(nimPreviewSlimSystem):
  import std/assertions

const BackendActionsExt* = ".cflags"
  ## Sidecar written by a module's `cg` stage next to its `.c`, carrying the C
  ## compile/link directives that module's `{.passL.}`/`{.compile.}`/… pragmas
  ## recorded. See `writeBackendActions`.

proc writeBackendActions*(g: ModuleGraph; module: PSym; list: PNode;
                          outfile: string) =
  ## Serialize the backend-relevant replay actions of ONE module to `outfile`,
  ## one tab-separated action per line.
  ##
  ## The `link` stage used to recover these by loading the whole import closure
  ## as `PrecompiledModule`s and re-running `replayBackendActions` over each —
  ## a 3.7s whole-program graph load, per link, purely to recover a handful of
  ## strings and the modules' `.c` paths. The producing `cg` process already has
  ## them in hand, so it writes them down instead and `link` reads them back
  ## (`applyBackendActions`). Written unconditionally, even when empty: it is a
  ## declared nifmake output of the `cg` rule, and a missing output re-fires the
  ## rule for ever.
  ##
  ## `localpassc` needs the module's own source path, which only the writer can
  ## resolve, so it is baked in here as a third field.
  var content = ""
  if list != nil:
    for n in list:
      if n.kind == nkReplayAction and n.len >= 2 and
          n[0].kind == nkStrLit and n[1].kind == nkStrLit:
        case n[0].strVal
        of "compile":
          if n.len == 4 and n[2].kind == nkStrLit and n[3].kind == nkStrLit:
            content.add "compile\t" & n[1].strVal & "\t" & n[2].strVal & "\t" &
                        n[3].strVal & "\n"
        of "link", "passl", "passc", "cppdefine":
          content.add n[0].strVal & "\t" & n[1].strVal & "\n"
        of "localpassc":
          content.add "localpassc\t" & n[1].strVal & "\t" &
                      toFullPathConsiderDirty(g.config, module.info.fileIndex).string & "\n"
        else: discard
  writeFile(outfile, content)

proc applyBackendActions*(g: ModuleGraph; infile: string) =
  ## Apply one module's recorded C directives (see `writeBackendActions`). The
  ## `link` stage's replacement for loading that module and replaying its AST.
  if not fileExists(infile): return
  for line in lines(infile):
    if line.len == 0: continue
    let f = line.split('\t')
    case f[0]
    of "compile":
      if f.len == 4:
        let cname = AbsoluteFile f[1]
        var cf = Cfile(nimname: splitFile(cname).name, cname: cname,
                       obj: AbsoluteFile f[2],
                       flags: {CfileFlag.External}, customArgs: f[3])
        extccomp.addExternalFileToCompile(g.config, cf)
    of "link":
      if f.len == 2: extccomp.addExternalFileToLink(g.config, AbsoluteFile f[1])
    of "passl":
      if f.len == 2: extccomp.addLinkOption(g.config, f[1])
    of "passc":
      if f.len == 2: extccomp.addCompileOption(g.config, f[1])
    of "localpassc":
      if f.len == 3: extccomp.addLocalCompileOption(g.config, f[1], AbsoluteFile f[2])
    of "cppdefine":
      if f.len == 2: options.cppDefine(g.config, f[1])
    else: discard

proc replayStateChanges*(module: PSym; g: ModuleGraph; list: PNode) =
  ## `list` is an `nkStmtList` of `nkReplayAction` nodes (macro-cache puts/incs/
  ## adds/incls and a few pragmas) recorded for `module`. Under the NIF backend a
  ## loaded module's `ast` is never reconstructed, so the caller passes the replay
  ## actions it parsed out of the module's NIF directly.
  assert list != nil
  assert list.kind == nkStmtList
  for n in list:
    assert n.kind == nkReplayAction
    # Fortunately only a tiny subset of the available pragmas need to
    # be replayed here. This is always a subset of ``pragmas.stmtPragmas``.
    if n.len >= 2:
      internalAssert g.config, n[0].kind == nkStrLit and n[1].kind == nkStrLit
      case n[0].strVal
      of "hint": message(g.config, n.info, hintUser, n[1].strVal)
      of "warning": message(g.config, n.info, warnUser, n[1].strVal)
      of "error": localError(g.config, n.info, errUser, n[1].strVal)
      of "compile":
        internalAssert g.config, n.len == 4 and n[2].kind == nkStrLit
        let cname = AbsoluteFile n[1].strVal
        var cf = Cfile(nimname: splitFile(cname).name, cname: cname,
                       obj: AbsoluteFile n[2].strVal,
                       flags: {CfileFlag.External},
                       customArgs: n[3].strVal)
        extccomp.addExternalFileToCompile(g.config, cf)
      of "link":
        extccomp.addExternalFileToLink(g.config, AbsoluteFile n[1].strVal)
      of "passl":
        extccomp.addLinkOption(g.config, n[1].strVal)
      of "passc":
        extccomp.addCompileOption(g.config, n[1].strVal)
      of "localpassc":
        extccomp.addLocalCompileOption(g.config, n[1].strVal, toFullPathConsiderDirty(g.config, module.info.fileIndex))
      of "cppdefine":
        options.cppDefine(g.config, n[1].strVal)
      of "inc":
        let destKey = n[1].strVal
        let by = n[2].intVal
        let v = getOrDefault(g.cacheCounters, destKey)
        g.cacheCounters[destKey] = v+by
      of "put":
        let destKey = n[1].strVal
        let key = n[2].strVal
        let val = n[3]
        if not contains(g.cacheTables, destKey):
          g.cacheTables[destKey] = initBTree[string, PNode]()
        if not contains(g.cacheTables[destKey], key):
          g.cacheTables[destKey].add(key, val)
        # else: the same key was already replayed. Under IC the import closure is
        # replayed (direct module + transitive deps), so the same registration can
        # legitimately be reached twice; re-applying it is a no-op, not an error.
      of "incl":
        let destKey = n[1].strVal
        let val = n[2]
        if not contains(g.cacheSeqs, destKey):
          g.cacheSeqs[destKey] = newTree(nkStmtList, val)
        else:
          block search:
            for existing in g.cacheSeqs[destKey]:
              if exprStructuralEquivalent(existing, val, strictSymEquality=true):
                break search
            g.cacheSeqs[destKey].add val
      of "add":
        let destKey = n[1].strVal
        let val = n[2]
        if not contains(g.cacheSeqs, destKey):
          g.cacheSeqs[destKey] = newTree(nkStmtList, val)
        else:
          g.cacheSeqs[destKey].add val
      else:
        internalAssert g.config, false

proc replayBackendActions*(g: ModuleGraph; module: PSym; list: PNode) =
  ## Applies the backend-relevant replay actions (C compile/link directives)
  ## found in a NIF-loaded module's top-level statement list. The `nifc`
  ## backend loads modules without going through sem's `replayStateChanges`,
  ## so e.g. math's `{.passL: "-lm".}` was lost and the final link failed
  ## with undefined references. VM cache actions are deliberately NOT
  ## replayed here — codegen does not run macros.
  if list == nil: return
  for n in list:
    if n.kind == nkReplayAction and n.len >= 2 and
        n[0].kind == nkStrLit and n[1].kind == nkStrLit:
      case n[0].strVal
      of "compile":
        if n.len == 4 and n[2].kind == nkStrLit:
          let cname = AbsoluteFile n[1].strVal
          var cf = Cfile(nimname: splitFile(cname).name, cname: cname,
                         obj: AbsoluteFile n[2].strVal,
                         flags: {CfileFlag.External},
                         customArgs: n[3].strVal)
          extccomp.addExternalFileToCompile(g.config, cf)
      of "link":
        extccomp.addExternalFileToLink(g.config, AbsoluteFile n[1].strVal)
      of "passl":
        extccomp.addLinkOption(g.config, n[1].strVal)
      of "passc":
        extccomp.addCompileOption(g.config, n[1].strVal)
      of "localpassc":
        extccomp.addLocalCompileOption(g.config, n[1].strVal,
          toFullPathConsiderDirty(g.config, module.info.fileIndex))
      of "cppdefine":
        options.cppDefine(g.config, n[1].strVal)
      else:
        discard
