#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Nimrod Contributors
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


proc mapMem*(m: var TMemFile, mode: FileMode = fmRead,
             mappedSize = -1, offset = 0): pointer =
  var readonly = mode == fmRead
  when defined(windows):
    result = mapViewOfFileEx(
      m.mapHandle,
      if readonly: FILE_MAP_READ else: FILE_MAP_WRITE,
      int32(offset shr 32),
      int32(offset and 0xffffffff),
      if mappedSize == -1: 0 else: mappedSize,
      nil)
    if result == nil:
      osError(osLastError())
  else:
    assert mappedSize > 0
    result = mmap(
      nil,
      mappedSize,
      if readonly: PROT_READ else: PROT_READ or PROT_WRITE,
      if readonly: (MAP_PRIVATE or MAP_POPULATE) else: (MAP_SHARED or MAP_POPULATE),
      m.handle, offset)
    if result == cast[pointer](MAP_FAILED):
      osError(osLastError())


proc unmapMem*(f: var TMemFile, p: pointer, size: int) =
  ## unmaps the memory region ``(p, <p+size)`` of the mapped file `f`.
  ## All changes are written back to the file system, if `f` was opened
  ## with write access. ``size`` must be of exactly the size that was requested
  ## via ``mapMem``.
  when defined(windows):
    if unmapViewOfFile(p) == 0: osError(osLastError())
  else:
    if munmap(p, size) != 0: osError(osLastError())


proc open*(filename: string, mode: FileMode = fmRead,
           mappedSize = -1, offset = 0, newFileSize = -1): TMemFile =
  ## opens a memory mapped file. If this fails, ``EOS`` is raised.
  ## `newFileSize` can only be set if the file does not exist and is opened
  ## with write access (e.g., with fmReadWrite). `mappedSize` and `offset`
  ## can be used to map only a slice of the file. Example:
  ##
  ## .. code-block:: nimrod
  ##   var
  ##     mm, mm_full, mm_half: TMemFile
  ##
  ##   mm = memfiles.open("/tmp/test.mmap", mode = fmWrite, newFileSize = 1024)    # Create a new file
  ##   mm.close()
  ##
  ##   # Read the whole file, would fail if newFileSize was set
  ##   mm_full = memfiles.open("/tmp/test.mmap", mode = fmReadWrite, mappedSize = -1)
  ##
  ##   # Read the first 512 bytes
  ##   mm_half = memfiles.open("/tmp/test.mmap", mode = fmReadWrite, mappedSize = 512)

  # The file can be resized only when write mode is used:
  assert newFileSize == -1 or mode != fmRead
  var readonly = mode == fmRead

  template rollback =
    result.mem = nil
    result.size = 0

  when defined(windows):
    template fail(errCode: TOSErrorCode, msg: expr) =
      rollback()
      if result.fHandle != 0: discard closeHandle(result.fHandle)
      if result.mapHandle != 0: discard closeHandle(result.mapHandle)
      osError(errCode)
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
      result.fHandle = callCreateFile(createFileW, newWideCString(filename))
    else:
      result.fHandle = callCreateFile(createFileA, filename)

    if result.fHandle == INVALID_HANDLE_VALUE:
      fail(osLastError(), "error opening file")

    if newFileSize != -1:
      var 
        sizeHigh = int32(newFileSize shr 32)
        sizeLow  = int32(newFileSize and 0xffffffff)

      var status = setFilePointer(result.fHandle, sizeLow, addr(sizeHigh),
                                  FILE_BEGIN)
      let lastErr = osLastError()
      if (status == INVALID_SET_FILE_POINTER and lastErr.int32 != NO_ERROR) or
         (setEndOfFile(result.fHandle) == 0):
        fail(lastErr, "error setting file size")

    # since the strings are always 'nil', we simply always call
    # CreateFileMappingW which should be slightly faster anyway:
    result.mapHandle = createFileMappingW(
      result.fHandle, nil,
      if readonly: PAGE_READONLY else: PAGE_READWRITE,
      0, 0, nil)

    if result.mapHandle == 0:
      fail(osLastError(), "error creating mapping")

    result.mem = mapViewOfFileEx(
      result.mapHandle,
      if readonly: FILE_MAP_READ else: FILE_MAP_WRITE,
      int32(offset shr 32),
      int32(offset and 0xffffffff),
      if mappedSize == -1: 0 else: mappedSize,
      nil)

    if result.mem == nil:
      fail(osLastError(), "error mapping view")

    var hi, low: int32
    low = getFileSize(result.fHandle, addr(hi))
    if low == INVALID_FILE_SIZE:
      fail(osLastError(), "error getting file size")
    else:
      var fileSize = (int64(hi) shr 32) or low
      if mappedSize != -1: result.size = min(fileSize, mappedSize).int
      else: result.size = fileSize.int

  else:
    template fail(errCode: TOSErrorCode, msg: expr) =
      rollback()
      if result.handle != 0: discard close(result.handle)
      osError(errCode)
  
    var flags = if readonly: O_RDONLY else: O_RDWR

    if newFileSize != -1:
      flags = flags or O_CREAT or O_TRUNC
      var permissions_mode = S_IRUSR or S_IWUSR
      result.handle = open(filename, flags, permissions_mode)
    else:
      result.handle = open(filename, flags)

    if result.handle == -1:
      # XXX: errno is supposed to be set here
      # Is there an exception that wraps it?
      fail(osLastError(), "error opening file")

    if newFileSize != -1:
      if ftruncate(result.handle, newFileSize) == -1:
        fail(osLastError(), "error setting file size")

    if mappedSize != -1:
      result.size = mappedSize
    else:
      var stat: TStat
      if fstat(result.handle, stat) != -1:
        # XXX: Hmm, this could be unsafe
        # Why is mmap taking int anyway?
        result.size = int(stat.st_size)
      else:
        fail(osLastError(), "error getting file size")

    result.mem = mmap(
      nil,
      result.size,
      if readonly: PROT_READ else: PROT_READ or PROT_WRITE,
      if readonly: (MAP_PRIVATE or MAP_POPULATE) else: (MAP_SHARED or MAP_POPULATE),
      result.handle,
      offset)

    if result.mem == cast[pointer](MAP_FAILED):
      fail(osLastError(), "file mapping failed")

proc close*(f: var TMemFile) =
  ## closes the memory mapped file `f`. All changes are written back to the
  ## file system, if `f` was opened with write access.
  
  var error = false
  var lastErr: TOSErrorCode

  when defined(windows):
    if f.fHandle != INVALID_HANDLE_VALUE:
      error = unmapViewOfFile(f.mem) == 0
      lastErr = osLastError()
      error = (closeHandle(f.mapHandle) == 0) or error
      error = (closeHandle(f.fHandle) == 0) or error
  else:
    if f.handle != 0:
      error = munmap(f.mem, f.size) != 0
      lastErr = osLastError()
      error = (close(f.handle) != 0) or error

  f.size = 0
  f.mem = nil

  when defined(windows):
    f.fHandle = 0
    f.mapHandle = 0
  else:
    f.handle = 0
  
  if error: osError(lastErr)

