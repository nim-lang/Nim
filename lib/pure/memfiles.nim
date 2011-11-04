#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides support for `memory mapped files`:idx:
## (Posix's `mmap`:idx:) on the different operating systems.

when defined(windows):
  import windows
elif defined(posix):
  import posix
else:
  {.error: "the memfiles module is not supported yet on your operating system!".}

## mem
## a pointer to the memory mapped file `f`. The pointer can be
## used directly to change the contents of the file, if `f` was opened
## with write access.

## size
## size of the memory mapped file `f`.

when defined(windows):
  type Tsize = int64
else:
  type Tsize = int

type
  TMemFile* = object {.pure.} ## represents a memory mapped file
    mem*: pointer # XXX: The compiler won't let me add comments on the next line
    size*: Tsize

    when defined(windows):
      fHandle: int
      mapHandle: int 
    else:
      handle: cint

proc open*(
  f           : var TMemFile,
  filename    : string,
  mode        : TFileMode = fmRead,
  mappedSize  : int       = -1,
  offset      : Tsize     = 0,
  newFileSize : Tsize     = -1 ): bool =
  ## open a memory mapped file `f`. Returns true for success.

  # The file can be resized only when write mode is used
  assert newFileSize == -1 or mode != fmRead
  var readonly = mode == fmRead

  template rollback =
    f.mem = nil
    f.size = 0

  when defined(windows):
    template fail(msg: expr) =
      rollback()
      if f.fHandle != 0: discard CloseHandle(f.fHandle)
      if f.mapHandle != 0: discard CloseHandle(f.mapHandle)
      # return false
      raise newException(EIO, msg)
      
    f.fHandle = CreateFileA(
      filename,
      if readonly: GENERIC_READ else: GENERIC_ALL,
      FILE_SHARE_READ,
      nil,
      if newFileSize != -1: CREATE_ALWAYS else: OPEN_EXISTING,
      if readonly: FILE_ATTRIBUTE_READONLY else: FILE_ATTRIBUTE_TEMPORARY,
      0)

    if f.fHandle == INVALID_HANDLE_VALUE:
      fail "error opening file"

    if newFileSize != -1:
      var 
        sizeHigh = int32(newFileSize shr 32)
        sizeLow  = int32(newFileSize and 0xffffffff)

      var status = SetFilePointer(f.fHandle, sizeLow, addr(sizeHigh), FILE_BEGIN)
      if (status == INVALID_SET_FILE_POINTER and GetLastError() != NO_ERROR) or
         (SetEndOfFile(f.fHandle) == 0):
        fail "error setting file size"

    f.mapHandle = CreateFileMapping(
      f.fHandle, nil,
      if readonly: PAGE_READONLY else: PAGE_READWRITE,
      0, 0, nil)

    if f.mapHandle == 0:
      fail "error creating mapping"

    f.mem = MapViewOfFileEx(
      f.mapHandle,
      if readonly: FILE_MAP_READ else: FILE_MAP_WRITE,
      int32(offset shr 32),
      int32(offset and 0xffffffff),
      if mappedSize == -1: 0 else: mappedSize,
      nil)

    if f.mem == nil:
      fail "error mapping view"

    var hi, low: int32
    low = GetFileSize(f.fHandle, addr(hi))
    if low == INVALID_FILE_SIZE:
      fail "error getting file size"
    else:
      var fileSize = (int64(hi) shr 32) or low
      f.size = if mappedSize != -1: min(fileSize, mappedSize) else: fileSize

    result = true

  else:
    template fail(msg: expr) =
      rollback()
      if f.handle != 0:
        discard close(f.handle)
      # return false
      raise newException(system.EIO, msg)
  
    var flags = if readonly: O_RDONLY else: O_RDWR

    if newFileSize != -1:
      flags = flags or O_CREAT or O_TRUNC

    f.handle = open(filename, flags)
    if f.handle == -1:
      # XXX: errno is supposed to be set here
      # Is there an exception that wraps it?
      fail "error opening file"

    if newFileSize != -1:
      if ftruncate(f.handle, newFileSize) == -1:
        fail "error setting file size"

    if mappedSize != -1:
      f.size = mappedSize
    else:
      var stat: Tstat
      if fstat(f.handle, stat) != -1:
        # XXX: Hmm, this could be unsafe
        # Why is mmap taking int anyway?
        f.size = int(stat.st_size)
      else:
        fail "error getting file size"

    f.mem = mmap(
      nil,
      f.size,
      if readonly: PROT_READ else: PROT_READ or PROT_WRITE,
      if readonly: MAP_PRIVATE else: MAP_SHARED,
      f.handle,
      offset)

    if f.mem == cast[pointer](MAP_FAILED):
      fail "file mapping failed"

    result = true

proc close*(f: var TMemFile) =
  ## closes the memory mapped file `f`. All changes are written back to the
  ## file system, if `f` was opened with write access.
  
  var error = false

  when defined(windows):
    if f.fHandle != INVALID_HANDLE_VALUE:
      error = UnmapViewOfFile(f.mem) == 0
      error = (CloseHandle(f.mapHandle) == 0) or error
      error = (CloseHandle(f.fHandle) == 0) or error
  else:
    if f.handle != 0:
      error = munmap(f.mem, f.size) != 0
      error = (close(f.handle) != 0) or error

  f.size = 0
  f.mem = nil

  when defined(windows):
    f.fHandle = 0
    f.mapHandle = 0
  else:
    f.handle = 0
  
  if error:
    raise newException(system.EIO, "error closing file")

