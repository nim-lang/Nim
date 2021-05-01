#
#
#            Nim's Runtime Library
#        (c) Copyright 2021 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module creates temporary files and directories.
##
## Experimental API, subject to change.

import os, random


const
  maxRetry = 10000
  letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  nimTempPathLength {.intdefine.} = 8


when defined(windows):
  import winlean

  var O_RDWR {.importc: "_O_RDWR", header: "<fcntl.h>".}: cint

  proc c_fdopen(
    filehandle: cint,
    mode: cstring
  ): File {.importc: "_fdopen",header: "<stdio.h>".}

  proc open_osfhandle(osh: Handle, mode: cint): cint {.
    importc: "_open_osfhandle", header: "<io.h>".}

  proc close_osfandle(fd: cint): cint {.
    importc: "_close", header: "<io.h>".}
else:
  import posix

  proc c_fdopen(
    filehandle: cint,
    mode: cstring
  ): File {.importc: "fdopen",header: "<stdio.h>".}


proc safeOpen(filename: string): File =
  ## Open files exclusively.
  # xxx this should be clarified; it doesn't in particular prevent other processes
  # from opening the file, at least currently.
  when defined(windows):
    let dwShareMode = FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE
    let dwCreation = CREATE_NEW
    let dwFlags = FILE_FLAG_BACKUP_SEMANTICS or FILE_ATTRIBUTE_NORMAL
    let handle = createFileW(newWideCString(filename), GENERIC_READ or GENERIC_WRITE, dwShareMode,
                              nil, dwCreation, dwFlags, Handle(0))

    if handle == INVALID_HANDLE_VALUE:
      raiseOSError(osLastError(), filename)

    let fileHandle = open_osfhandle(handle, O_RDWR)
    if fileHandle == -1:
      discard closeHandle(handle)
      raiseOSError(osLastError(), filename)

    result = c_fdopen(fileHandle, "w+")
    if result == nil:
      discard close_osfandle(fileHandle)
      raiseOSError(osLastError(), filename)
  else:
    # xxx we need a `proc toMode(a: FilePermission): Mode`, possibly by
    # exposing fusion/filepermissions.fromFilePermissions to stdlib; then we need
    # to expose a `perm` param so users can customize this (e.g. the temp file may
    # need execute permissions), and figure out how to make the API cross platform.
    let mode = Mode(S_IRUSR or S_IWUSR)
    let flags = posix.O_RDWR or posix.O_CREAT or posix.O_EXCL
    let fileHandle = posix.open(filename, flags, mode)
    if fileHandle == -1:
      raiseOSError(osLastError(), filename)

    result = c_fdopen(fileHandle, "w+")
    if result == nil:
      discard posix.close(fileHandle) # TODO handles failure when closing file
      raiseOSError(osLastError(), filename)

template randomPathName(length: Natural): string =
  var res = newString(length)
  var state = initRand()
  for i in 0 ..< length:
    res[i] = state.sample(letters)
  res

proc getTempDirImpl(dir: string): string {.inline.} =
  result = dir
  if result.len == 0:
    result = getTempDir()

proc genTempPath*(prefix, suffix: string, dir = ""): string =
  ## Generates a path name in `dir`.
  ##
  ## If `dir` is empty, (`getTempDir <os.html#getTempDir>`_) will be used.
  ## The path begins with `prefix` and ends with `suffix`.
  let dir = getTempDirImpl(dir)
  result = dir / (prefix & randomPathName(nimTempPathLength) & suffix)

proc createTempFile*(prefix, suffix: string, dir = ""): tuple[fd: File, path: string] =
  ## Creates a new temporary file in the directory `dir`.
  ## 
  ## This generates a path name using `genTempPath(prefix, suffix, dir)` and
  ## returns a file handle to an open file and the path of that file, possibly after
  ## retrying to ensure it doesn't already exist.
  ## 
  ## If failing to create a temporary file, `IOError` will be raised.
  ##
  ## .. note:: It is the caller's responsibility to remove the file when no longer needed.
  let dir = getTempDirImpl(dir)
  createDir(dir)
  for i in 0 ..< maxRetry:
    result.path = genTempPath(prefix, suffix, dir)
    try:
      result.fd = safeOpen(result.path)
    except OSError:
      continue
    return

  raise newException(IOError, "Failed to create a temporary file under directory " & dir)

proc createTempDir*(prefix, suffix: string, dir = ""): string =
  ## Creates a new temporary directory in the directory `dir`.
  ##
  ## This generates a dir name using `genTempPath(prefix, suffix, dir)`, creates
  ## the directory and returns it, possibly after retrying to ensure it doesn't
  ## already exist.
  ##
  ## If failing to create a temporary directory, `IOError` will be raised.
  ##
  ## .. note:: It is the caller's responsibility to remove the directory when no longer needed.
  let dir = getTempDirImpl(dir)
  createDir(dir)
  for i in 0 ..< maxRetry:
    result = genTempPath(prefix, suffix, dir)
    try:
      if not existsOrCreateDir(result):
        return
    except OSError:
      continue

  raise newException(IOError, "Failed to create a temporary directory under directory " & dir)
