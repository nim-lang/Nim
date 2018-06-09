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

const
  buildOS* {.magic: "BuildOS".}: string = ""
    ## The OS this build is running on. Can be different from ``system.hostOS``
    ## for cross compilations.

  buildCPU* {.magic: "BuildCPU".}: string = ""
    ## The CPU this build is running on. Can be different from ``system.hostCPU``
    ## for cross compilations.

template builtin = discard

# We know the effects better than the compiler:
{.push hint[XDeclaredButNotUsed]: off.}

proc listDirs*(dir: string): seq[string] =
  ## Lists all the subdirectories (non-recursively) in the directory `dir`.
  builtin
proc listFiles*(dir: string): seq[string] =
  ## Lists all the files (non-recursively) in the directory `dir`.
  builtin

proc removeDir(dir: string){.
  tags: [ReadIOEffect, WriteIOEffect], raises: [OSError].} = builtin
proc removeFile(dir: string) {.
  tags: [ReadIOEffect, WriteIOEffect], raises: [OSError].} = builtin
proc moveFile(src, dest: string) {.
  tags: [ReadIOEffect, WriteIOEffect], raises: [OSError].} = builtin
proc moveDir(src, dest: string) {.
  tags: [ReadIOEffect, WriteIOEffect], raises: [OSError].} = builtin
proc copyFile(src, dest: string) {.
  tags: [ReadIOEffect, WriteIOEffect], raises: [OSError].} = builtin
proc copyDir(src, dest: string) {.
  tags: [ReadIOEffect, WriteIOEffect], raises: [OSError].} = builtin
proc createDir(dir: string) {.tags: [WriteIOEffect], raises: [OSError].} =
  builtin
proc getOsError: string = builtin
proc setCurrentDir(dir: string) = builtin
proc getCurrentDir*(): string =
  ## Retrieves the current working directory.
  builtin
proc rawExec(cmd: string): int {.tags: [ExecIOEffect], raises: [OSError].} =
  builtin

proc warningImpl(arg, orig: string) = discard
proc hintImpl(arg, orig: string) = discard

proc paramStr*(i: int): string =
  ## Retrieves the ``i``'th command line parameter.
  builtin

proc paramCount*(): int =
  ## Retrieves the number of command line parameters.
  builtin

proc switch*(key: string, val="") =
  ## Sets a Nim compiler command line switch, for
  ## example ``switch("checks", "on")``.
  builtin

proc warning*(name: string; val: bool) =
  ## Disables or enables a specific warning.
  let v = if val: "on" else: "off"
  warningImpl(name & "]:" & v, "warning[" & name & "]:" & v)

proc hint*(name: string; val: bool) =
  ## Disables or enables a specific hint.
  let v = if val: "on" else: "off"
  hintImpl(name & "]:" & v, "hint[" & name & "]:" & v)

proc patchFile*(package, filename, replacement: string) =
  ## Overrides the location of a given file belonging to the
  ## passed package.
  ## If the ``replacement`` is not an absolute path, the path
  ## is interpreted to be local to the Nimscript file that contains
  ## the call to ``patchFile``, Nim's ``--path`` is not used at all
  ## to resolve the filename!
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##   patchFile("stdlib", "asyncdispatch", "patches/replacement")
  discard

proc getCommand*(): string =
  ## Gets the Nim command that the compiler has been invoked with, for example
  ## "c", "js", "build", "help".
  builtin

proc setCommand*(cmd: string; project="") =
  ## Sets the Nim command that should be continued with after this Nimscript
  ## has finished.
  builtin

proc cmpIgnoreStyle(a, b: string): int = builtin
proc cmpIgnoreCase(a, b: string): int = builtin

proc cmpic*(a, b: string): int =
  ## Compares `a` and `b` ignoring case.
  cmpIgnoreCase(a, b)

proc getEnv*(key: string; default = ""): string {.tags: [ReadIOEffect].} =
  ## Retrieves the environment variable of name `key`.
  builtin

proc existsEnv*(key: string): bool {.tags: [ReadIOEffect].} =
  ## Checks for the existence of an environment variable named `key`.
  builtin

proc putEnv*(key, val: string) {.tags: [WriteIOEffect].} =
  ## Sets the value of the environment variable named key to val.
  builtin

proc fileExists*(filename: string): bool {.tags: [ReadIOEffect].} =
  ## Checks if the file exists.
  builtin

proc dirExists*(dir: string): bool {.
  tags: [ReadIOEffect].} =
  ## Checks if the directory `dir` exists.
  builtin

proc existsFile*(filename: string): bool =
  ## An alias for ``fileExists``.
  fileExists(filename)

proc existsDir*(dir: string): bool =
  ## An alias for ``dirExists``.
  dirExists(dir)

proc selfExe*(): string =
  ## Returns the currently running nim or nimble executable.
  builtin

proc toExe*(filename: string): string =
  ## On Windows adds ".exe" to `filename`, else returns `filename` unmodified.
  (when defined(windows): filename & ".exe" else: filename)

proc toDll*(filename: string): string =
  ## On Windows adds ".dll" to `filename`, on Posix produces "lib$filename.so".
  (when defined(windows): filename & ".dll" else: "lib" & filename & ".so")

proc strip(s: string): string =
  var i = 0
  while s[i] in {' ', '\c', '\L'}: inc i
  result = s.substr(i)

template `--`*(key, val: untyped) =
  ## A shortcut for ``switch(astToStr(key), astToStr(val))``.
  switch(astToStr(key), strip astToStr(val))

template `--`*(key: untyped) =
  ## A shortcut for ``switch(astToStr(key)``.
  switch(astToStr(key), "")

type
  ScriptMode* {.pure.} = enum ## Controls the behaviour of the script.
    Silent,                   ## Be silent.
    Verbose,                  ## Be verbose.
    Whatif                    ## Do not run commands, instead just echo what
                              ## would have been done.

var
  mode*: ScriptMode ## Set this to influence how mkDir, rmDir, rmFile etc.
                    ## behave

template checkOsError =
  let err = getOsError()
  if err.len > 0: raise newException(OSError, err)

template log(msg: string, body: untyped) =
  if mode in {ScriptMode.Verbose, ScriptMode.Whatif}:
    echo "[NimScript] ", msg
  if mode != ScriptMode.WhatIf:
    body

proc rmDir*(dir: string) {.raises: [OSError].} =
  ## Removes the directory `dir`.
  log "rmDir: " & dir:
    removeDir dir
    checkOsError()

proc rmFile*(file: string) {.raises: [OSError].} =
  ## Removes the `file`.
  log "rmFile: " & file:
    removeFile file
    checkOsError()

proc mkDir*(dir: string) {.raises: [OSError].} =
  ## Creates the directory `dir` including all necessary subdirectories. If
  ## the directory already exists, no error is raised.
  log "mkDir: " & dir:
    createDir dir
    checkOsError()

proc mvFile*(`from`, to: string) {.raises: [OSError].} =
  ## Moves the file `from` to `to`.
  log "mvFile: " & `from` & ", " & to:
    moveFile `from`, to
    checkOsError()

proc mvDir*(`from`, to: string) {.raises: [OSError].} =
  ## Moves the dir `from` to `to`.
  log "mvDir: " & `from` & ", " & to:
    moveDir `from`, to
    checkOsError()

proc cpFile*(`from`, to: string) {.raises: [OSError].} =
  ## Copies the file `from` to `to`.
  log "cpFile: " & `from` & ", " & to:
    copyFile `from`, to
    checkOsError()

proc cpDir*(`from`, to: string) {.raises: [OSError].} =
  ## Copies the dir `from` to `to`.
  log "cpDir: " & `from` & ", " & to:
    copyDir `from`, to
    checkOsError()

proc exec*(command: string) =
  ## Executes an external process.
  log "exec: " & command:
    if rawExec(command) != 0:
      raise newException(OSError, "FAILED: " & command)
    checkOsError()

proc exec*(command: string, input: string, cache = "") {.
  raises: [OSError], tags: [ExecIOEffect].} =
  ## Executes an external process.
  log "exec: " & command:
    echo staticExec(command, input, cache)

proc selfExec*(command: string) =
  ## Executes an external command with the current nim/nimble executable.
  ## ``Command`` must not contain the "nim " part.
  let c = selfExe() & " " & command
  log "exec: " & c:
    if rawExec(c) != 0:
      raise newException(OSError, "FAILED: " & c)
    checkOsError()

proc put*(key, value: string) =
  ## Sets a configuration 'key' like 'gcc.options.always' to its value.
  builtin

proc get*(key: string): string =
  ## Retrieves a configuration 'key' like 'gcc.options.always'.
  builtin

proc exists*(key: string): bool =
  ## Checks for the existence of a configuration 'key'
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
  ## <http://nim-lang.org/docs/os.html#setCurrentDir,string>`_ . Use the `withDir()
  ## <#withDir>`_ template if you want to perform a temporary change only.
  setCurrentDir(dir)
  checkOsError()

proc findExe*(bin: string): string =
  ## Searches for bin in the current working directory and then in directories
  ## listed in the PATH environment variable. Returns "" if the exe cannot be
  ## found.
  builtin

template withDir*(dir: string; body: untyped): untyped =
  ## Changes the current directory temporarily.
  ##
  ## If you need a permanent change, use the `cd() <#cd>`_ proc. Usage example:
  ##
  ## .. code-block:: nim
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
  ## Example:
  ##
  ## .. code-block:: nim
  ##  task build, "default build is via the C backend":
  ##    setCommand "c"
  proc `name Task`*() = body

  let cmd = getCommand()
  if cmd.len == 0 or cmd ==? "help":
    setCommand "help"
    writeTask(astToStr(name), description)
  elif cmd ==? astToStr(name):
    setCommand "nop"
    `name Task`()

proc cppDefine*(define: string) =
  ## tell Nim that ``define`` is a C preprocessor ``#define`` and so always
  ## needs to be mangled.
  builtin

when not defined(nimble):
  # nimble has its own implementation for these things.
  var
    packageName* = ""    ## Nimble support: Set this to the package name. It
                         ## is usually not required to do that, nims' filename is
                         ## the default.
    version*: string     ## Nimble support: The package's version.
    author*: string      ## Nimble support: The package's author.
    description*: string ## Nimble support: The package's description.
    license*: string     ## Nimble support: The package's license.
    srcDir*: string      ## Nimble support: The package's source directory.
    binDir*: string      ## Nimble support: The package's binary directory.
    backend*: string     ## Nimble support: The package's backend.

    skipDirs*, skipFiles*, skipExt*, installDirs*, installFiles*,
      installExt*, bin*: seq[string] = @[] ## Nimble metadata.
    requiresData*: seq[string] = @[] ## Exposes the list of requirements for read
                                     ## and write accesses.

  proc requires*(deps: varargs[string]) =
    ## Nimble support: Call this to set the list of requirements of your Nimble
    ## package.
    for d in deps: requiresData.add(d)

{.pop.}
