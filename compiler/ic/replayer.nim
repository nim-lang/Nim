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

import std/tables

when defined(nimPreviewSlimSystem):
  import std/assertions

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
