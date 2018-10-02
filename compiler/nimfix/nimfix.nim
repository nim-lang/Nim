#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nimfix is a tool that helps to convert old-style Nimrod code to Nim code.

import strutils, os, parseopt
import compiler/[options, commands, modules, sem, passes, passaux, linter, msgs,
  nimconf, extccomp, condsyms, modulegraphs, idents, pathutils, cmdlinehelper]

const Usage = """
Nimfix - Tool to patch Nim code
Usage:
  nimfix [options] projectfile.nim

Options:
  --overwriteFiles:on|off          overwrite the original nim files.
                                   DEFAULT is ON!
  --wholeProject                   overwrite every processed file.
  --checkExtern:on|off             style check also extern names
  --styleCheck:on|off|auto         performs style checking for identifiers
                                   and suggests an alternative spelling;
                                   'auto' corrects the spelling.
  --bestEffort                     try to fix the code even when there
                                   are errors.

In addition, all command line options of Nim are supported.
"""

proc mainCommand(graph: ModuleGraph) =
  let conf = graph.config
  clearPasses(graph)
  registerPass(graph, verbosePass)
  registerPass(graph, semPass)
  conf.cmd = cmdPretty
  wantMainModule(conf)

  if not fileExists(conf.projectFull):
    quit "cannot find file: " & conf.projectFull.string

  if not conf.projectFull.isEmpty:
    # current path is always looked first for modules
    conf.searchPaths.insert(conf.projectPath, 0)

  conf.searchPaths.add(conf.libpath)

  compileProject(graph)
  overwriteFiles(conf)

proc processCmdLine*(pass: TCmdLinePass, cmd: string, config: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  var argsCount = 0
  gOnlyMainfile = true
  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongoption, cmdShortOption:
      case p.key.normalize
      of "overwritefiles":
        case p.val.normalize
        of "on": gOverWrite = true
        of "off": gOverWrite = false
        else: localError(config, gCmdLineInfo, "'on' or 'off' expected, but '$1' found" % p.val)
      of "checkextern":
        case p.val.normalize
        of "on": gCheckExtern = true
        of "off": gCheckExtern = false
        else: localError(config, gCmdLineInfo, "'on' or 'off' expected, but '$1' found" % p.val)
      of "stylecheck":
        case p.val.normalize
        of "off": gStyleCheck = StyleCheck.None
        of "on": gStyleCheck = StyleCheck.Warn
        of "auto": gStyleCheck = StyleCheck.Auto
        else: localError(config, gCmdLineInfo, "'on', 'off' or 'auto' expected, but '$1' found" % p.val)
      of "wholeproject": gOnlyMainfile = false
      of "besteffort": config.errorMax = high(int) # don't stop after first error
      else:
        processSwitch(pass, p, config)
    of cmdArgument:
      config.projectName = unixToNativePath(p.key)
      # if processArgument(pass, p, argsCount): break

proc handleCmdLine(cache: IdentCache; config: ConfigRef) =
  let self = NimProg(
    processCmdLine: processCmdLine,
    mainCommand: mainCommand
  )
  config.command = "nimfix"
  self.initDefinesProg(config, "nimfix")

  if paramCount() == 0:
    stdout.writeLine(Usage)
    return

  self.processCmdLineAndProjectPath(config)

  # Find Nim's prefix dir.
  let binaryPath = findExe("nim")
  if binaryPath == "":
    raise newException(IOError,
        "Cannot find Nim standard library: Nim compiler not in PATH")
  config.prefixDir = AbsoluteDir binaryPath.splitPath().head.parentDir()
  if not dirExists(config.prefixDir / RelativeDir"lib"):
    config.prefixDir = AbsoluteDir""

  discard self.loadConfigsAndRunMainCommand(cache, config)

when compileOption("gc", "v2") or compileOption("gc", "refc"):
  GC_disableMarkAndSweep()

handleCmdline(newIdentCache(), newConfigRef())
