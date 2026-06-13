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

import options, commands, lineinfos
import std/[algorithm, os, sets]
import "../dist/nimony/src/lib" / [nifbuilder, nifcoreparse]

const
  IcConfigVersion* = "1"
    ## Artifact format version. Bump on any layout change here so a child built
    ## by an older compiler rejects a stale artifact and falls back to normal
    ## config loading instead of replaying a format it cannot parse.

proc writeIcConfig*(conf: ConfigRef; outfile: string) =
  ## Serialise the config-file switches recorded during `loadConfigs` plus the
  ## resolved `cppDefines` set into the artifact at `outfile`.
  var b = nifbuilder.open(outfile)
  b.withTree "stmts":
    b.withTree "meta":
      b.addStrLit IcConfigVersion
    b.withTree "cppdefines":
      # HashSet iteration order is unspecified; sort so the artifact is
      # byte-stable across runs (nifmake keys rebuilds off content changes).
      var defs: seq[string] = @[]
      for d in conf.cppDefines: defs.add d
      sort defs
      for d in defs: b.addStrLit d
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
    cppTag = tags.registerTag("cppdefines")
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
      elif c.cursorTagId == cppTag:
        c.loopInto:
          if c.kind == StrLit:
            cppDefine(conf, strVal(c))
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
