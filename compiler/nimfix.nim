#
#
#           The Nim Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nimfix is a tool that helps to convert old-style Nimrod code to Nim code.

import strutils, os, parseopt
import options, commands, modules, sem, passes, passaux, pretty, msgs, nimconf,
  extccomp, condsyms, lists

const Usage = """
Nimfix - Tool to patch Nim code
Usage:
  nimfix [options] projectflie.nim

Options:
  --overwriteFiles:on|off          overwrite the original nim files.
                                   DEFAULT is ON!
  --checkExtern:on|off             style check also extern names
  --styleCheck:none|confirm|auto   performs style checking for identifiers
                                   and suggests an alternative spelling. If
                                   'auto', it automatically corrects the
                                   spelling. If 'confirm' it asks the user.

In addition, all command line options of Nim are supported.
"""

proc mainCommand =
  #msgs.gErrorMax = high(int)  # do not stop after first error
  registerPass verbosePass
  registerPass semPass
  registerPass prettyPass
  gCmd = cmdPretty
  appendStr(searchPaths, options.libpath)
  if gProjectFull.len != 0:
    # current path is always looked first for modules
    prependStr(searchPaths, gProjectPath)

  compileProject()
  pretty.overwriteFiles()

proc processCmdLine*(pass: TCmdLinePass, cmd: string) =
  var p = parseopt.initOptParser(cmd)
  var argsCount = 0
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
        of "none": gStyleCheck = StyleCheck.None
        of "confirm": gStyleCheck = StyleCheck.Confirm
        of "auto": gStyleCheck = StyleCheck.Auto
        else: localError(gCmdLineInfo, errGenerated,
                         "'none', 'confirm' or 'auto' expected")
      else:
        processSwitch(pass, p)
    of cmdArgument:
      options.gProjectName = unixToNativePath(p.key)
      # if processArgument(pass, p, argsCount): break

proc handleCmdLine() =
  if paramCount() == 0:
    stdout.writeln(Usage)
  else:
    processCmdLine(passCmd1, "")
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
    loadConfigs(DefaultConfig) # load all config files
    # now process command line arguments again, because some options in the
    # command line can overwite the config file's settings
    extccomp.initVars()
    processCmdLine(passCmd2, "")
    mainCommand()

when compileOption("gc", "v2") or compileOption("gc", "refc"):
  GC_disableMarkAndSweep()

condsyms.initDefines()
defineSymbol "nimfix"
handleCmdline()
