#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Backend-only driver for `nim ic`'s C-generation stages (the `nifc` command:
## `--icBackendStage:lower|cg|merge|emit|link`). This produces the separate
## `bin/nifc` binary that `deps.nim` invokes per rule instead of re-entering the
## monolithic `nim` compiler.
##
## Crucially, it imports NEITHER `main`/`pipelines` NOR `cmdlinehelper`/`nimconf`.
## Those are the only two edges that pull the frontend semantic analyzer (`sem`)
## and the NimScript VM (`scriptconfig`) into the ordinary compiler binary. The
## backend graph (`nifbackend` -> `cgen`/`ast2nif`/`transf`/`injectdestructors`/
## `modulegraphs`) is entirely sem-free, and config is replayed sem-free from the
## precompiled `.cfg.nif` via `icconfig.applyIcConfig` (no file read, no VM run).
##
## Keeping `sem` out of the closure is the prerequisite for building this binary
## with `-d:nimBackend`, under which `astdef` swaps `PNode` to a cursor-backed
## value representation: `sem`'s pervasive `PNode(kind: ...)` literal construction
## could not compile against such a type, but it is no longer linked here.

import std/[os, parseopt, strutils]

when defined(nimPreviewSlimSystem):
  import std/assertions

import
  commands, options, msgs, extccomp, idents, lineinfos,
  pathutils, modulegraphs, condsyms, platform, modules
import "../dist/checksums/src/checksums/sha1"

from ast import setUseIc
from ast2nif import registerNifAstTags
import icconfig
import nifbackend

proc hashMainCompilationParams(conf: ConfigRef): string =
  ## Mirrors `main.hashMainCompilationParams` (inlined to avoid importing `main`,
  ## which pulls in `pipelines`/`sem`).
  var state = newSha1State()
  state.update os.getAppFilename()
  state.update conf.commandLine
  state.update $conf.projectFull
  result = $SecureHash(state.finalize())

proc setOutFile(conf: ConfigRef) =
  ## Mirrors `main.setOutFile` (inlined, same reason).
  if conf.outFile.isEmpty:
    var base = conf.projectName
    if optUseNimcache in conf.globalOptions:
      base.add "_" & hashMainCompilationParams(conf)
    let targetName =
      if optGenDynLib in conf.globalOptions:
        platform.OS[conf.target.targetOS].dllFrmt % base
      elif optGenStaticLib in conf.globalOptions:
        (if conf.target.targetOS == osWindows: "$1.lib" else: "lib$1.a") % base
      else: base & platform.OS[conf.target.targetOS].exeExt
    conf.outFile = RelativeFile targetName

proc addCmdPrefix(result: var string, kind: CmdLineKind) =
  case kind
  of cmdLongOption: result.add "--"
  of cmdShortOption: result.add "-"
  of cmdArgument, cmdEnd: discard

proc processCmdLine(pass: TCmdLinePass, cmd: string; config: ConfigRef) =
  ## Slim copy of `nim.processCmdLine` (no nimble-lock probing, no stdin project):
  ## the `nifc` child is always launched by `deps.nim` with an explicit project
  ## NIF and forwarded switches.
  var p = parseopt.initOptParser(cmd)
  var argsCount = 0
  config.commandLine.setLen 0
  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption:
      config.commandLine.add " "
      config.commandLine.addCmdPrefix p.kind
      config.commandLine.add p.key.quoteShell
      if p.val.len > 0:
        config.commandLine.add ':'
        config.commandLine.add p.val.quoteShell
      processSwitch(pass, p, config)
    of cmdArgument:
      config.commandLine.add " "
      config.commandLine.add p.key.quoteShell
      if processArgument(pass, p, argsCount, config): break

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  # NIF tag registration must run before any NIF read/write, independent of
  # module init order (see ast2nif.registerNifAstTags).
  registerNifAstTags()
  condsyms.initDefines(conf.symbols)
  defineSymbol(conf.symbols, "nim_compiler")

  if paramCount() == 0:
    rawMessage(conf, errGenerated, "nifc: no arguments (expected a NIF project)")
    return

  # Pass 1: learn the command (`nifc`), the project NIF, and switches including
  # `--icPreparsedConfig` (needed before config replay below).
  processCmdLine(passCmd1, "", conf)
  if conf.projectName != "":
    setFromProjectName(conf, conf.projectName)
  else:
    conf.projectPath = AbsoluteDir canonicalizePath(conf, AbsoluteFile getCurrentDir())

  var graph = newModuleGraph(cache, conf)

  # Sem-free config: replay the precompiled `.cfg.nif` produced once by the
  # `nim icconfig` process. No `nimconf`, no `scriptconfig`, no VM. A missing or
  # format-incompatible artifact is fatal here (unlike the frontend, this binary
  # has no fallback config parser on purpose).
  setDefaultLibpath(conf)
  if conf.icPreparsedConfig.len == 0 or not applyIcConfig(conf, conf.icPreparsedConfig):
    rawMessage(conf, errGenerated,
      "nifc backend requires a valid precompiled config (--icPreparsedConfig)")
    return
  if conf.backend != backendJs: extccomp.initVars(conf)

  # Pass 2: command-line switches override the replayed config.
  processCmdLine(passCmd2, "", conf)

  if conf.selectedGC == gcUnselected:
    initOrcDefines(conf)

  if conf.cmd != cmdNifC:
    rawMessage(conf, errGenerated, "nifc: only the 'nifc' command is supported")
    return

  # cmdNifC arm, mirroring `main.mainCommand`:
  setUseIc(true)
  excl conf.features, Feature.vtables
  wantMainModule(conf)
  setOutFile(conf)

  # `main.commandNifC` body, inlined:
  extccomp.initVars(conf)
  if not extccomp.ccHasSaneOverflow(conf):
    conf.symbols.defineSymbol("nimEmulateOverflowChecks")
  nifbackend.generateCode(graph, conf.projectMainIdx)

when compileOption("gc", "refc"):
  GC_disableMarkAndSweep()

let conf = newConfigRef()
handleCmdLine(newIdentCache(), conf)
msgQuit(int8(conf.errorCounter > 0))
