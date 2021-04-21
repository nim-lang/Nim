#
#
#            Nim's Runtime Library
#        (c) Copyright 2021 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module creates temporary files and directories.

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
    let flags = posix.O_RDWR or posix.O_CREAT or posix.O_EXCL

    let fileHandle = posix.open(filename, flags)
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

proc createTempFile*(prefix, suffix: string, dir = ""): tuple[fd: File, path: string] =
  ## `createTempFile` creates a new temporary file in the directory `dir`.
  ## 
  ## If `dir` is the empty string, the default directory for temporary files
  ## (`getTempDir <os.html#getTempDir>`_) will be used.
  ## The temporary file name begins with `prefix` and ends with `suffix`.
  ## `createTempFile` returns a file handle to an open file and the path of that file.
  ## 
  ## If failing to create a temporary file, `IOError` will be raised.
  ##
  ## .. note:: It is the caller's responsibility to remove the file when no longer needed.
  ##
  var dir = dir
  if dir.len == 0:
    dir = getTempDir()

  createDir(dir)

  for i in 0 ..< maxRetry:
    result.path = dir / (prefix & randomPathName(nimTempPathLength) & suffix)
    try:
      result.fd = safeOpen(result.path)
    except OSError:
      continue
    return

  raise newException(IOError, "Failed to create a temporary file under directory " & dir)

proc createTempDir*(prefix, suffix: string, dir = ""): string =
  ## `createTempDir` creates a new temporary directory in the directory `dir`.
  ##
  ## If `dir` is the empty string, the default directory for temporary files
  ## (`getTempDir <os.html#getTempDir>`_) will be used.
  ## The temporary directory name begins with `prefix` and ends with `suffix`.
  ## `createTempDir` returns the path of that temporary firectory.
  ##
  ## If failing to create a temporary directory, `IOError` will be raised.
  ##
  ## .. note:: It is the caller's responsibility to remove the directory when no longer needed.
  ##
  var dir = dir
  if dir.len == 0:
    dir = getTempDir()

  createDir(dir)

  for i in 0 ..< maxRetry:
    result = dir / (prefix & randomPathName(nimTempPathLength) & suffix)
    try:
      if not existsOrCreateDir(result):
        return
    except OSError:
      continue

  raise newException(IOError, "Failed to create a temporary directory under directory " & dir)
