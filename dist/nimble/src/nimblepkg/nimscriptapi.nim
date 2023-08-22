# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

## This module is implicitly imported in NimScript .nimble files.

import system except getCommand, setCommand, switch, `--`
import strformat, strutils, tables, sequtils
export tables

when (NimMajor, NimMinor) < (1, 3):
  when not defined(nimscript):
    import os
else:
  import os

var
  packageName* = ""    ## Set this to the package name. It
                       ## is usually not required to do that, nims' filename is
                       ## the default.
  version*: string     ## The package's version.
  author*: string      ## The package's author.
  description*: string ## The package's description.
  license*: string     ## The package's license.
  srcDir*: string      ## The package's source directory.
  binDir*: string      ## The package's binary directory.
  backend*: string     ## The package's backend.

  skipDirs*, skipFiles*, skipExt*, installDirs*, installFiles*,
    installExt*, bin*: seq[string] = @[] ## Nimble metadata.
  requiresData*: seq[string] = @[] ## The package's dependencies.
  taskRequiresData*: Table[string, seq[string]] ## Task dependencies
  foreignDeps*: seq[string] = @[] ## The foreign dependencies. Only
                                  ## exported for 'distros.nim'.

  nimbleTasks: seq[tuple[name, description: string]] = @[]
  beforeHooks: seq[string] = @[]
  afterHooks: seq[string] = @[]
  flags: Table[string, seq[string]]
  namedBin*: Table[string, string]

  command = "e"
  project = ""
  success = false
  retVal = true
  nimblePathsEnv = "__NIMBLE_PATHS"

proc requires*(deps: varargs[string]) =
  ## Call this to set the list of requirements of your Nimble
  ## package.
  for d in deps: requiresData.add(d)

proc taskRequires*(task: string, deps: varargs[string]) =
  ## Call this to set the list of requirements for a certain task
  if task notin taskRequiresData:
    taskRequiresData[task] = @[]
  for d in deps:
    taskRequiresData[task] &= d

proc getParams(): tuple[scriptFile, projectFile, outFile, actionName: string,
                        commandLineParams: seq[string]] =
  # Called by nimscriptwrapper.nim:execNimscript()
  #   nim e --flags /full/path/to/file.nims /full/path/to/file.nimble /full/path/to/file.out action
  for i in 2 .. paramCount():
    let
      param = paramStr(i)
    if param[0] != '-':
      if result.scriptFile.len == 0:
        result.scriptFile = param
      elif result.projectFile.len == 0:
        result.projectFile = param
      elif result.outFile.len == 0:
        result.outFile = param
      elif result.actionName.len == 0:
        result.actionName = param.normalize
      else:
        result.commandLineParams.add param
    else:
      result.commandLineParams.add param

const
  # Command line values are const so that thisDir() works at compile time
  (scriptFile, projectFile, outFile, actionName, commandLineParams*) = getParams()

proc getCommand*(): string =
  return command

proc setCommand*(cmd: string, prj = "") =
  command = cmd
  if prj.len != 0:
    project = prj

proc switch*(key: string, value="") =
  if flags.hasKey(key):
    flags[key].add(value)
  else:
    flags[key] = @[value]

template `--`*(key, val: untyped) =
  switch(astToStr(key), strip astToStr(val))

template `--`*(key: untyped) =
  switch(astToStr(key), "")

template printIfLen(varName) =
  if varName.len != 0:
    result &= astToStr(varName) & ": \"\"\"" & varName & "\"\"\"\n"

template printSeqIfLen(name: string, varName: untyped) =
  if varName.len != 0:
    result &= name & ": \"" & varName.join(", ") & "\"\n"

template printSeqIfLen(varName) =
  printSeqIfLen(astToStr(varName), varName)

proc printPkgInfo(): string =
  if backend.len == 0:
    backend = "c"

  # Forward `namedBin` entries in `bin`
  for k, v in namedBin:
    let idx = bin.find(k)
    if idx == -1:
      bin.add k & "=" & v
    else:
      bin[idx] = k & "=" & v

  result = "[Package]\n"
  if packageName.len != 0:
    result &= "name: \"" & packageName & "\"\n"
  printIfLen version
  printIfLen author
  printIfLen description
  printIfLen license
  printIfLen srcDir
  printIfLen binDir
  printIfLen backend

  printSeqIfLen skipDirs
  printSeqIfLen skipFiles
  printSeqIfLen skipExt
  printSeqIfLen installDirs
  printSeqIfLen installFiles
  printSeqIfLen installExt
  printSeqIfLen bin
  printSeqIfLen "nimbleTasks", nimbleTasks.unzip()[0]
  printSeqIfLen beforeHooks
  printSeqIfLen afterHooks

  if requiresData.len != 0 or taskRequiresData.len != 0:
    result &= "\n[Deps]\n"
    # Write package level dependencies
    if requiresData.len != 0:
      result &= &"requires: \"{requiresData.join(\", \")}\"\n"
    # Write task level dependencies
    for task, requiresData in taskRequiresData.pairs:
      result &= &"{task}Requires: \"{requiresData.join(\", \")}\"\n"


proc onExit*() =
  if actionName.len == 0 or actionName == "help":
    var maxNameLen = 8
    for (name, _) in nimbleTasks:
      maxNameLen = max(maxNameLen, name.len)
    for (name, description) in nimbleTasks:
      echo alignLeft(name, maxNameLen + 2), description

  if "printPkgInfo".normalize == actionName:
    if outFile.len != 0:
      writeFile(outFile, printPkgInfo())
  else:
    var
      output = ""
    output &= "\"success\": " & $success & ", "
    output &= "\"command\": \"" & command & "\", "
    if project.len != 0:
      output &= "\"project\": \"" & project & "\", "
    if flags.len != 0:
      output &= "\"flags\": {"
      for key, val in flags.pairs:
        output &= "\"" & key & "\": ["
        for v in val:
          let v = if v.len > 0 and v[0] == '"': strutils.unescape(v)
                  else: v
          output &= v.escape & ", "
        output = output[0 .. ^3] & "], "
      output = output[0 .. ^3] & "}, "

    output &= "\"retVal\": " & $retVal

    if outFile.len != 0:
      writeFile(outFile, "{" & output & "}")

# TODO: New release of Nim will move this `task` template under a
# `when not defined(nimble)`. This will allow us to override it in the future.
template task*(name: untyped; description: string; body: untyped): untyped =
  ## Defines a task. Hidden tasks are supported via an empty description.
  ## Example:
  ##
  ## .. code-block:: nim
  ##  task build, "default build is via the C backend":
  ##    setCommand "c"
  proc `name Task`*() = body

  nimbleTasks.add (astToStr(name), description)

  if actionName.len == 0 or actionName == "help":
    success = true
  elif actionName == astToStr(name).normalize:
    success = true
    `name Task`()

template before*(action: untyped, body: untyped): untyped =
  ## Defines a block of code which is evaluated before ``action`` is executed.
  proc `action Before`*(): bool =
    result = true
    body

  beforeHooks.add astToStr(action)

  if (astToStr(action) & "Before").normalize == actionName:
    success = true
    retVal = `action Before`()

template after*(action: untyped, body: untyped): untyped =
  ## Defines a block of code which is evaluated after ``action`` is executed.
  proc `action After`*(): bool =
    result = true
    body

  afterHooks.add astToStr(action)

  if (astToStr(action) & "After").normalize == actionName:
    success = true
    retVal = `action After`()

proc getPkgDir*(): string =
  ## Returns the package directory containing the .nimble file currently
  ## being evaluated.
  result = projectFile.rsplit(seps={'/', '\\', ':'}, maxsplit=1)[0]

proc thisDir*(): string = getPkgDir()

proc getPaths*(): seq[string] =
  ## Returns the paths to the dependencies
  return getEnv(nimblePathsEnv).split("|")

proc getPathsClause*(): string =
  ## Returns the paths to the dependencies as consumed by the nim compiler.
  return getPaths().mapIt("--path:" & it.quoteShell).join(" ")
