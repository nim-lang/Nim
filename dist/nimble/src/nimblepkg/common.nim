# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.
#
# Various miscellaneous common types reside here, to avoid problems with
# recursive imports

import sugar, macros, hashes, strutils, sets
export sugar.dump

type
  NimbleError* = object of CatchableError
    hint*: string

  BuildFailed* = object of NimbleError

  ## Same as quit(QuitSuccess) or quit(QuitFailure), but allows cleanup.
  ## Inheriting from `Defect` is workaround to avoid accidental catching of
  ## `NimbleQuit` by `CatchableError` handlers.
  NimbleQuit* = object of Defect
    exitCode*: int

  ProcessOutput* = tuple[output: string, exitCode: int]

const
  nimbleVersion* = "0.14.2"
  nimblePackagesDirName* = "pkgs2"
  nimblePackagesLinksDirName* ="links"
  nimbleBinariesDirName* = "bin"

proc newNimbleError*[ErrorType](msg: string, hint = "",
                                details: ref CatchableError = nil):
    ref ErrorType =
  result = newException(ErrorType, msg, details)
  result.hint = hint

proc nimbleError*(msg: string, hint = "", details: ref CatchableError = nil):
    ref NimbleError =
  newNimbleError[NimbleError](msg, hint, details)

proc buildFailed*(msg: string, details: ref CatchableError = nil):
    ref BuildFailed =
  newNimbleError[BuildFailed](msg)

proc nimbleQuit*(exitCode = QuitSuccess): ref NimbleQuit =
  result = newException(NimbleQuit, "")
  result.exitCode = exitCode

template newClone*[T: not ref](obj: T): ref T =
  ## Creates a garbage collected heap copy of not a reference object.
  {.warning[ProveInit]: off.}
  let result = obj.typeOf.new
  {.warning[ProveInit]: on.}
  result[] = obj
  result

proc dup*[T](obj: T): T = obj

proc `$`*(p: ptr | ref): string = cast[int](p).toHex
  ## Converts the pointer `p` to its hex string representation.

proc hash*(p: ptr | ref): int = cast[int](p).hash
  ## Calculates the has value of the pointer `p`.

template cd*(dir: string, body: untyped) =
  ## Sets the current dir to ``dir``, executes ``body`` and restores the
  ## previous working dir.
  let lastDir = getCurrentDir()
  setCurrentDir(dir)
  block:
    defer: setCurrentDir(lastDir)
    body

template createNewDir*(dir: string) =
  removeDir dir
  createDir dir

template cdNewDir*(dir: string, body: untyped) =
  createNewDir dir
  cd dir:
    body

proc getLinkFileDir*(pkgName: string): string =
  pkgName & "-#head"

proc getLinkFileName*(pkgName: string): string =
  pkgName & ".nimble-link"
