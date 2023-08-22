# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

import os, strutils, sets

import packageparser, common, packageinfo, options, nimscriptwrapper, cli

proc execHook*(options: Options, hookAction: ActionType, before: bool): bool =
  ## Returns whether to continue.
  result = true

  # For certain commands hooks should not be evaluated.
  if hookAction in noHookActions:
    return

  var nimbleFile = ""
  try:
    nimbleFile = findNimbleFile(getCurrentDir(), true)
  except NimbleError: return true
  # PackageInfos are cached so we can read them as many times as we want.
  let pkgInfo = getPkgInfoFromFile(nimbleFile, options)
  let actionName =
    if hookAction == actionCustom: options.action.command
    else: ($hookAction)[6 .. ^1]
  let hookExists =
    if before: actionName.normalize in pkgInfo.preHooks
    else: actionName.normalize in pkgInfo.postHooks
  if pkgInfo.isNimScript and hookExists:
    let res = execHook(nimbleFile, actionName, before, options)
    if res.success:
      result = res.retVal

proc execCustom*(nimbleFile: string, options: Options,
                 execResult: var ExecutionResult[bool]): bool =
  ## Executes the custom command using the nimscript backend.

  if not execHook(options, actionCustom, true):
    raise nimbleError("Pre-hook prevented further execution.")

  if not nimbleFile.isNimScript(options):
    writeHelp()

  execResult = execTask(nimbleFile, options.action.command, options)
  if not execResult.success:
    raise nimbleError(msg = "Failed to execute task $1 in $2" %
                             [options.action.command, nimbleFile])

  if execResult.command.normalize == "nop":
    display("Warning:", "Using `setCommand 'nop'` is not necessary.", Warning,
            HighPriority)

  if not execHook(options, actionCustom, false):
    return

  return true

proc getOptionsForCommand*(execResult: ExecutionResult,
                           options: Options): Options =
  ## Creates an Options object for the requested command.
  var newOptions = options
  parseCommand(execResult.command, newOptions)
  for arg in execResult.arguments:
    parseArgument(arg, newOptions)
  for flag, vals in execResult.flags:
    for val in vals:
      parseFlag(flag, val, newOptions)
  return newOptions
