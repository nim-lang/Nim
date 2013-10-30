#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Nimrod Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Authors: Zahary Karadjov, Andreas Rumpf
##
## This module provides support for `memory mapped files`:idx:
## (Posix's `mmap`:idx:) on the different operating systems.

when defined(windows):
  import winlean
elif defined(posix):
  import posix
else:
  {.error: "the memfiles module is not supported on your operating system!".}

import os

type
  TMemFile* = object {.pure.} ## represents a memory mapped file
    mem*: pointer    ## a pointer to the memory mapped file. The pointer
                     ## can be used directly to change the contents of the
                     ## file, if it was opened with write access.
    size*: int       ## size of the memory mapped file

    when defined(windows):
      fHandle: int
      mapHandle: int
    else:
      handle: cint

proc open*(filename: string, mode: TFileMode = fmRead,
           mappedSize = -1, offset = 0, newFileSize = -1): TMemFile =
  ## opens a memory mapped file. If this fails, ``EOS`` is raised.
  ## `newFileSize` can only be set if the file is not opened with ``fmRead``
  ## access. `mappedSize` and `offset` can be used to map only a slice of
  ## the file.

  # The file can be resized only when write mode is used:
  assert newFileSize == -1 or mode != fmRead
  var readonly = mode == fmRead

  template rollback =
    result.mem = nil
    result.size = 0

  when defined(windows):
    template fail(errCode: TOSErrorCode, msg: expr) =
      rollback()
      if result.fHandle != 0: discard CloseHandle(result.fHandle)
      if result.mapHandle != 0: discard CloseHandle(result.mapHandle)
      OSError(errCode)
      # return false
      #raise newException(EIO, msg)

    template callCreateFile(winApiProc, filename: expr): expr =
      winApiProc(
        filename,
        if readonly: GENERIC_READ else: GENERIC_ALL,
        FILE_SHARE_READ,
        nil,
        if newFileSize != -1: CREATE_ALWAYS else: OPEN_EXISTING,
        if readonly: FILE_ATTRIBUTE_READONLY else: FILE_ATTRIBUTE_TEMPORARY,
        0)

    when useWinUnicode:
      result.fHandle = callCreateFile(CreateFileW, newWideCString(filename))
    else:
      result.fHandle = callCreateFile(CreateFileA, filename)

    if result.fHandle == INVALID_HANDLE_VALUE:
      fail(OSLastError(), "error opening file")

    if newFileSize != -1:
      var
        sizeHigh = int32(newFileSize shr 32)
        sizeLow  = int32(newFileSize and 0xffffffff)

      var status = SetFilePointer(result.fHandle, sizeLow, addr(sizeHigh),
                                  FILE_BEGIN)
      let lastErr = OSLastError()
      if (status == INVALID_SET_FILE_POINTER and lastErr.int32 != NO_ERROR) or
         (SetEndOfFile(result.fHandle) == 0):
        fail(lastErr, "error setting file size")

    # since the strings are always 'nil', we simply always call
    # CreateFileMappingW which should be slightly faster anyway:
    result.mapHandle = CreateFileMappingW(
      result.fHandle, nil,
      if readonly: PAGE_READONLY else: PAGE_READWRITE,
      0, 0, nil)

    if result.mapHandle == 0:
      fail(OSLastError(), "error creating mapping")

    result.mem = MapViewOfFileEx(
      result.mapHandle,
      if readonly: FILE_MAP_READ else: FILE_MAP_WRITE,
      int32(offset shr 32),
      int32(offset and 0xffffffff),
      if mappedSize == -1: 0 else: mappedSize,
      nil)

    if result.mem == nil:
      fail(OSLastError(), "error mapping view")

    var hi, low: int32
    low = GetFileSize(result.fHandle, addr(hi))
    if low == INVALID_FILE_SIZE:
      fail(OSLastError(), "error getting file size")
    else:
      var fileSize = (int64(hi) shr 32) or low
      if mappedSize != -1: result.size = min(fileSize, mappedSize).int
      else: result.size = fileSize.int

  else:
    template fail(errCode: TOSErrorCode, msg: expr) =
      rollback()
      if result.handle != 0: discard close(result.handle)
      OSError(errCode)

    var flags = if readonly: O_RDONLY else: O_RDWR

    if newFileSize != -1:
      flags = flags or O_CREAT or O_TRUNC

    result.handle = open(filename, flags)
    if result.handle == -1:
      # XXX: errno is supposed to be set here
      # Is there an exception that wraps it?
      fail(OSLastError(), "error opening file")

    if newFileSize != -1:
      if ftruncate(result.handle, newFileSize) == -1:
        fail(OSLastError(), "error setting file size")

    if mappedSize != -1:
      result.size = mappedSize
    else:
      var stat: Tstat
      if fstat(result.handle, stat) != -1:
        # XXX: Hmm, this could be unsafe
        # Why is mmap taking int anyway?
        result.size = int(stat.st_size)
      else:
        fail(OSLastError(), "error getting file size")

    result.mem = mmap(
      nil,
      result.size,
      if readonly: PROT_READ else: PROT_READ or PROT_WRITE,
      if readonly: MAP_PRIVATE else: MAP_SHARED,
      result.handle,
      offset)

    if result.mem == cast[pointer](MAP_FAILED):
      fail(OSLastError(), "file mapping failed")

proc close*(f: var TMemFile) =
  ## closes the memory mapped file `f`. All changes are written back to the
  ## file system, if `f` was opened with write access.

  var error = false
  var lastErr: TOSErrorCode

  when defined(windows):
    if f.fHandle != INVALID_HANDLE_VALUE:
      lastErr = OSLastError()
      error = UnmapViewOfFile(f.mem) == 0
      error = (CloseHandle(f.mapHandle) == 0) or error
      error = (CloseHandle(f.fHandle) == 0) or error
  else:
    if f.handle != 0:
      lastErr = OSLastError()
      error = munmap(f.mem, f.size) != 0
      error = (close(f.handle) != 0) or error

  f.size = 0
  f.mem = nil

  when defined(windows):
    f.fHandle = 0
    f.mapHandle = 0
  else:
    f.handle = 0

  if error: OSError(lastErr)

