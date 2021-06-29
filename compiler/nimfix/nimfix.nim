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
import compiler/[options, commands, modules, sem,
  passes, passaux, linter,
  msgs, nimconf,
  extccomp, condsyms,
  modulegraphs, idents]

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

proc mainCommand =
  registerPass verbosePass
  registerPass semPass
  conf.setCmd cmdNimfix
  searchPaths.add options.libpath
  if gProjectFull.len != 0:
    # current path is always looked first for modules
    searchPaths.insert(gProjectPath, 0)

  compileProject(newModuleGraph(), newIdentCache())
  pretty.overwriteFiles()

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
        else: localError(gCmdLineInfo, errOnOrOffExpected)
      of "checkextern":
        case p.val.normalize
        of "on": gCheckExtern = true
        of "off": gCheckExtern = false
        else: localError(gCmdLineInfo, errOnOrOffExpected)
      of "stylecheck":
        case p.val.normalize
        of "off": gStyleCheck = StyleCheck.None
        of "on": gStyleCheck = StyleCheck.Warn
        of "auto": gStyleCheck = StyleCheck.Auto
        else: localError(gCmdLineInfo, errOnOrOffExpected)
      of "wholeproject": gOnlyMainfile = false
      of "besteffort": msgs.gErrorMax = high(int) # don't stop after first error
      else:
        processSwitch(pass, p, config)
    of cmdArgument:
      options.gProjectName = unixToNativePath(p.key)
      # if processArgument(pass, p, argsCount): break

proc handleCmdLine(config: ConfigRef) =
  if paramCount() == 0:
    stdout.writeLine(Usage)
  else:
    processCmdLine(passCmd1, "", config)
    if gProjectName != "":
      try:
        gProjectFull = canonicalizePath(gProjectName)
      except OSError:
        gProjectFull = gProjectName
      var p = splitFile(gProjectFull)
      gProjectPath = p.dir
      gProjectName = p.name
    else:
      gProjectPath = getCurrentDir()
    loadConfigs(DefaultConfig, config) # load all config files
    # now process command line arguments again, because some options in the
    # command line can overwrite the config file's settings
    extccomp.initVars()
    processCmdLine(passCmd2, "", config)
    mainCommand()

when compileOption("gc", "refc"):
  GC_disableMarkAndSweep()

condsyms.initDefines()
defineSymbol "nimfix"
handleCmdline newConfigRef()
