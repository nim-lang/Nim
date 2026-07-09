#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Precompiled config for the incremental compiler (`nim ic`).
##
## `nim ic` builds the program by spawning one `nim m` child per module (or
## strongly-connected import group) plus a final `nim nifc`. Each child is a
## full Nim process, so each would normally re-read the whole `nim.cfg` chain
## *and* re-run `config.nims` through the VM — work that is identical for every
## child and, because of the VM run, far from free. With ~85 modules in the
## compiler itself that config work is paid ~85 times during `koch bootic`.
##
## The fix mirrors Nimony's `.cfg.nif`: the driver parses config once, records
## the net effect, and the children replay it. Every config-file switch funnels
## through `processSwitch(..., passPP, ...)` (`nimconf.parseAssignment` and the
## `switch()` callback in `scriptconfig`), so the recorded sequence of those
## switches, replayed in order, reproduces an identical `ConfigRef` without any
## file read or VM run. The one config side effect that does not go through
## `processSwitch` is `cppDefine` (it mutates `conf.cppDefines` directly), so the
## resolved set is serialised alongside.
##
## Path-search switches are deliberately excluded from the recording (see
## `commands.processSwitch`): their resolved result already lives in
## `conf.searchPaths`, which the driver forwards to every child as absolute
## `--path` arguments; replaying their raw, config-dir-relative arguments here
## would misresolve.

import options, commands, lineinfos, pathutils, msgs
import std/[algorithm, os, sets, osproc, times, streams, syncio]
import "../dist/nimony/src/lib" / [nifbuilder, nifcoreparse]

const
  IcConfigVersion* = "2"
    ## Artifact format version. Bump on any layout change here so a child built
    ## by an older compiler rejects a stale artifact and falls back to normal
    ## config loading instead of replaying a format it cannot parse.

proc writeIcConfig*(conf: ConfigRef; outfile: string) =
  ## Serialise the resolved config (the config-file switches recorded during
  ## `loadConfigs`, the resolved `cppDefines`/`searchPaths`, the nimcache dir, and
  ## the list of config *source* files for staleness detection) into `outfile`.
  ## `OnlyIfChanged`: when the content is byte-identical to what is already on
  ## disk the file is left untouched so its mtime does not advance — otherwise
  ## every `nim ic` run would re-fire the whole nifmake graph (see `nifler`'s
  ## `produceConfig`, whose model this mirrors).
  var b = nifbuilder.open(outfile, writeMode = OnlyIfChanged)
  b.withTree "stmts":
    b.withTree "meta":
      b.addStrLit IcConfigVersion
    b.withTree "sources":
      # Every config file read while loading (nim.cfg chain + config.nims), so a
      # later run can decide via mtimes whether this artifact is still current
      # (see `sourcesChanged`).
      for f in conf.configFiles:
        b.addStrLit f.string
    b.withTree "nimcache":
      # Resolved build nimcache. Recorded (unlike the path-search switches) so the
      # driver, which replays this artifact instead of parsing `nim.cfg`, still
      # learns a `--nimcache:` set inside `nim.cfg` and builds in the right place.
      b.addStrLit conf.nimcacheDir.string
    b.withTree "cppdefines":
      # HashSet iteration order is unspecified; sort so the artifact is
      # byte-stable across runs (nifmake keys rebuilds off content changes).
      var defs: seq[string] = @[]
      for d in conf.cppDefines: defs.add d
      sort defs
      for d in defs: b.addStrLit d
    b.withTree "searchpaths":
      # The resolved (absolute) search paths. Path-search *switches* are skipped
      # below because their raw arguments are config-dir-relative; the net effect
      # lives here instead, so a replayer with no `--path` command-line arguments
      # (the `nim ic` driver itself) still resolves imports. `nim m`/`nim nifc`
      # children also receive these as forwarded `--path` args; the dedup on
      # replay makes the overlap harmless.
      for p in conf.searchPaths:
        b.addStrLit p.string
    b.withTree "switches":
      for sw in conf.icConfigSwitches:
        b.addTree "sw"
        b.addStrLit sw.switch
        b.addStrLit sw.arg
        b.endTree()
  b.close()

proc applyIcConfig*(conf: ConfigRef; infile: string): bool =
  ## Replay the precompiled config into `conf`. Returns false (and applies
  ## nothing meaningful) when the artifact is missing or written by a compiler
  ## with an incompatible format version, so the caller can fall back to reading
  ## the config files normally.
  if not fileExists(infile): return false
  var pool = newPool()
  var tags = newTagPool()
  let
    stmtsTag = tags.registerTag("stmts")
    metaTag = tags.registerTag("meta")
    sourcesTag = tags.registerTag("sources")
    nimcacheTag = tags.registerTag("nimcache")
    cppTag = tags.registerTag("cppdefines")
    pathsTag = tags.registerTag("searchpaths")
    switchesTag = tags.registerTag("switches")
    swTag = tags.registerTag("sw")
  var buf = parseFromFile(infile, 1000, pool, tags)
  var c = beginRead(buf)
  if c.kind != TagLit or c.cursorTagId != stmtsTag:
    endRead(c)
    return false
  var version = ""
  var sawMeta = false
  let info = unknownLineInfo
  c.loopInto:
    if c.kind == TagLit:
      if c.cursorTagId == metaTag:
        sawMeta = true
        c.loopInto:
          if c.kind == StrLit:
            version = strVal(c)
            inc c
          else:
            skip c
      elif c.cursorTagId == nimcacheTag:
        c.loopInto:
          if c.kind == StrLit:
            let nc = strVal(c)
            # Only when nimcache was not already pinned on the command line: a
            # `--nimcache:` argument the driver/child was launched with must win
            # over whatever `nim.cfg` recorded into the artifact.
            if nc.len > 0 and conf.nimcacheDir.isEmpty:
              conf.nimcacheDir = AbsoluteDir(nc)
            inc c
          else:
            skip c
      elif c.cursorTagId == sourcesTag:
        # Replay does not need the source list; it exists only for
        # `sourcesChanged`. Skip the whole section.
        skip c
      elif c.cursorTagId == cppTag:
        c.loopInto:
          if c.kind == StrLit:
            cppDefine(conf, strVal(c))
            inc c
          else:
            skip c
      elif c.cursorTagId == pathsTag:
        c.loopInto:
          if c.kind == StrLit:
            # Append preserving the serialised order (which already reflects the
            # driver's addPath insert-at-front sequence), deduping against any
            # path a child already received via a forwarded `--path` argument.
            let d = AbsoluteDir(strVal(c))
            if not conf.searchPaths.contains(d): conf.searchPaths.add d
            inc c
          else:
            skip c
      elif c.cursorTagId == switchesTag:
        c.loopInto:
          if c.kind == TagLit and c.cursorTagId == swTag:
            var sw = ""
            var arg = ""
            var idx = 0
            c.loopInto:
              if c.kind == StrLit:
                if idx == 0: sw = strVal(c)
                else: arg = strVal(c)
                inc idx
                inc c
              else:
                skip c
            processSwitch(sw, arg, passPP, info, conf)
          else:
            skip c
      else:
        skip c
    else:
      skip c
  endRead(c)
  result = sawMeta and version == IcConfigVersion

proc sourcesChanged*(configFile: string): bool =
  ## True when the precompiled config at `configFile` is missing, malformed,
  ## written by an incompatible version, or any recorded config *source* file is
  ## newer than it (or has vanished) — i.e. the artifact must be regenerated.
  ## Mirrors nifler's `sourcesChanged`: the source list lives inside the artifact
  ## so this needs no out-of-band knowledge of which `nim.cfg`s were read.
  if not fileExists(configFile): return true
  let modtime = getLastModificationTime(configFile)
  var pool = newPool()
  var tags = newTagPool()
  let
    stmtsTag = tags.registerTag("stmts")
    metaTag = tags.registerTag("meta")
    sourcesTag = tags.registerTag("sources")
  var buf = parseFromFile(configFile, 1000, pool, tags)
  var c = beginRead(buf)
  if c.kind != TagLit or c.cursorTagId != stmtsTag:
    endRead(c)
    return true
  var version = ""
  var depsChanged = false
  c.loopInto:
    if c.kind == TagLit and c.cursorTagId == metaTag:
      c.loopInto:
        if c.kind == StrLit:
          version = strVal(c)
          inc c
        else:
          skip c
    elif c.kind == TagLit and c.cursorTagId == sourcesTag:
      c.loopInto:
        if c.kind == StrLit:
          let dep = strVal(c)
          if not fileExists(dep) or getLastModificationTime(dep) >= modtime:
            depsChanged = true
          inc c
        else:
          skip c
    else:
      skip c
  endRead(c)
  result = depsChanged or version != IcConfigVersion

proc produceIcConfig*(conf: ConfigRef) =
  ## The `cmdIcConfig` command. By the time it runs, the normal pipeline has
  ## already fully parsed the `nim.cfg` chain and run `config.nims`, so the
  ## resolved config is sitting in `conf`; just serialise it to `--o`.
  let outPath = conf.icConfigOut
  if outPath.len == 0:
    rawMessage(conf, errGenerated, "icconfig: missing output path (--icConfigOut)")
    return
  createDir(parentDir(outPath))
  writeIcConfig(conf, outPath)

proc ensureIcConfig*(conf: ConfigRef) =
  ## Driver-side (`cmdIc`). Make sure an up-to-date precompiled config exists,
  ## (re)producing it in a *separate* process when missing or stale, then point
  ## `conf.icPreparsedConfig` at it so the driver replays the very same config its
  ## `nim m`/`nim nifc` children will — perfect speed (config parsed at most once,
  ## skipped entirely when nothing changed) and consistency (one producer, every
  ## process replays its output). The artifact lives in the nimcache derived from
  ## the command line (pre-config-parse), which is the one the children are told;
  ## a `--nimcache:` set inside `nim.cfg` is recovered from the artifact itself.
  let cacheDir = getNimcacheDir(conf).string
  # Start from a clean cache when the on-disk NIF format stamp is absent or stale
  # (see `icFormatVersion`). This must happen HERE, before the config artifact is
  # produced — `commandIc` performs the same check later, but by then the artifact
  # would already live in the cache and the wipe would delete it.
  createDir(cacheDir)
  let versionFile = cacheDir / "ic.version"
  let stamp = if fileExists(versionFile): readFile(versionFile) else: ""
  if stamp != icFormatVersion:
    removeDir(cacheDir)
    createDir(cacheDir)
    writeFile(versionFile, icFormatVersion)
  let outPath = cacheDir / "ic_config.cfg.nif"
  if not fileExists(outPath) or sourcesChanged(outPath):
    createDir(cacheDir)
    # Re-invoke ourselves as the config producer: reuse this process's command
    # line, dropping the command argument (`ic`/`track`) in favour of `icconfig`
    # and the explicit output path. Every switch must land BEFORE the project
    # file, because anything after the project is swallowed into
    # `config.arguments` by `cmdLineRest` (and a non-empty `arguments` without
    # `--run` is a hard error). Callers may legitimately put switches after the
    # project — `nim track PROJ --def:...` — so we re-order rather than replay
    # verbatim: all `-`-prefixed switches first (in encounter order), then the
    # non-switch project token(s). The producer re-reads `nim.cfg` itself.
    var pargs = @["icconfig", "--icConfigOut:" & outPath]
    var rest: seq[string] = @[]
    var droppedCmd = false
    for a in commandLineParams():
      if a.len == 0: continue
      if a[0] == '-':
        pargs.add a
      elif not droppedCmd:
        droppedCmd = true  # drop the original command token (`ic`/`track`)
      else:
        rest.add a  # project file (and any further non-switch tokens) go last
    for a in rest: pargs.add a
    let p = startProcess(getAppFilename(), args = pargs,
                         options = {poStdErrToStdOut})
    let outp = p.outputStream.readAll()
    let code = p.waitForExit()
    p.close()
    if code != 0 or not fileExists(outPath):
      rawMessage(conf, errGenerated,
        "failed to produce precompiled config (exit code " & $code & "):\n" & outp)
      return
  conf.icPreparsedConfig = outPath
