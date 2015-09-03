#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# Nim's configuration system now uses Nim for scripting. This module provides
# a few things that are required for this to work.

template builtin = discard

proc listDirs*(dir: string): seq[string] = builtin
proc listFiles*(dir: string): seq[string] = builtin

proc removeDir(dir: string) = builtin
proc removeFile(dir: string) = builtin
proc moveFile(src, dest: string) = builtin
proc createDir(dir: string) = builtin
proc getOsError: string = builtin
proc setCurrentDir(dir: string) = builtin
proc getCurrentDir(): string = builtin
proc paramStr*(i: int): string = builtin
proc paramCount*(): int = builtin

proc switch*(key: string, val="") = builtin
proc getCommand*(): string = builtin
proc setCommand*(cmd: string) = builtin
proc cmpIgnoreStyle(a, b: string): int = builtin

proc strip(s: string): string =
  var i = 0
  while s[i] in {' ', '\c', '\L'}: inc i
  result = s.substr(i)

template `--`*(key, val: untyped) = switch(astToStr(key), strip astToStr(val))
template `--`*(key: untyped) = switch(astToStr(key), "")

type
  ScriptMode* {.pure.} = enum
    Silent,
    Verbose,
    Whatif

var
  mode*: ScriptMode ## Set this to influence how mkDir, rmDir, rmFile etc.
                    ## behave

template checkOsError =
  let err = getOsError()
  if err.len > 0: raise newException(OSError, err)

template log(msg: string, body: untyped) =
  if mode == ScriptMode.Verbose or mode == ScriptMode.Whatif:
    echo "[NimScript] ", msg
  if mode != ScriptMode.WhatIf:
    body

proc rmDir*(dir: string) {.raises: [OSError].} =
  log "rmDir: " & dir:
    removeDir dir
    checkOsError()

proc rmFile*(dir: string) {.raises: [OSError].} =
  log "rmFile: " & dir:
    removeFile dir
    checkOsError()

proc mkDir*(dir: string) {.raises: [OSError].} =
  log "mkDir: " & dir:
    createDir dir
    checkOsError()

proc mvFile*(`from`, to: string) {.raises: [OSError].} =
  log "mvFile: " & `from` & ", " & to:
    moveFile `from`, to
    checkOsError()

proc exec*(command: string, input = "", cache = "") =
  ## Executes an external process.
  log "exec: " & command:
    echo staticExec(command, input, cache)

proc put*(key, value: string) =
  ## Sets a configuration 'key' like 'gcc.options.always' to its value.
  builtin

proc get*(key: string): string =
  ## Retrieves a configuration 'key' like 'gcc.options.always'.
  builtin

proc exists*(key: string): bool =
  ## Checks for the existance of a configuration 'key'
  ## like 'gcc.options.always'.
  builtin

proc nimcacheDir*(): string =
  ## Retrieves the location of 'nimcache'.
  builtin

proc thisDir*(): string =
  ## Retrieves the location of the current ``nims`` script file.
  builtin

proc cd*(dir: string) {.raises: [OSError].} =
  ## Changes the current directory.
  ##
  ## The change is permanent for the rest of the execution, since this is just
  ## a shortcut for `os.setCurrentDir()
  ## <http://nim-lang.org/os.html#setCurrentDir,string>`_ . Use the `withDir()
  ## <#withDir>`_ template if you want to perform a temporary change only.
  setCurrentDir(dir)
  checkOsError()

template withDir*(dir: string; body: untyped): untyped =
  ## Changes the current directory temporarily.
  ##
  ## If you need a permanent change, use the `cd() <#cd>`_ proc. Usage example:
  ##
  ## .. code-block:: nimrod
  ##   withDir "foo":
  ##     # inside foo
  ##   #back to last dir
  var curDir = getCurrentDir()
  try:
    cd(dir)
    body
  finally:
    cd(curDir)

template `==?`(a, b: string): bool = cmpIgnoreStyle(a, b) == 0

proc writeTask(name, desc: string) =
  if desc.len > 0:
    var spaces = " "
    for i in 0 ..< 20 - name.len: spaces.add ' '
    echo name, spaces, desc

template task*(name: untyped; description: string; body: untyped): untyped =
  ## Defines a task. Hidden tasks are supported via an empty description.
  proc `name Task`() = body

  let cmd = getCommand()
  if cmd.len == 0 or cmd ==? "help":
    setCommand "help"
    writeTask(astToStr(name), description)
  elif cmd ==? astToStr(name):
    setCommand "nop"
    `name Task`()

var
  packageName* = ""
  version*, author*, description*, license*, srcdir*,
    binDir*, backend*: string

  skipDirs*, skipFiles*, skipExt*, installDirs*, installFiles*,
    installExt*, bin*: seq[string] = @[]
  requiresData*: seq[string] = @[]

proc requires*(deps: varargs[string]) =
  for d in deps: requiresData.add(d)
