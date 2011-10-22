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
## XXX Currently it is implemented with Nimrod's
## basic IO facilities and does not use any platform specific code!
## Oh and currently only ``fmRead`` is supported...

type
  TMemFile* = object {.pure.} ## represents a memory mapped file
    file: TFile
    buffer: pointer
    fileLen: int
  
proc open*(f: var TMemFile, filename: string, mode: TFileMode = fmRead): bool =
  ## open a memory mapped file `f`. Returns true for success.
  assert mode == fmRead
  result = open(f.file, filename, mode)

  var len = getFileSize(f.file)
  if len < high(int):
    f.fileLen = int(len)
    f.buffer = alloc(f.fileLen)
    if readBuffer(f.file, f.buffer, f.fileLen) != f.fileLen:
      raise newException(EIO, "error while reading from file")
  else:
    raise newException(EIO, "file too big to fit in memory")

proc close*(f: var TMemFile) =
  ## closes the memory mapped file `f`. All changes are written back to the
  ## file system, if `f` was opened with write access.
  dealloc(f.buffer)
  close(f.file)

proc mem*(f: var TMemFile): pointer {.inline.} =
  ## retrives a pointer to the memory mapped file `f`. The pointer can be
  ## used directly to change the contents of the file, if `f` was opened
  ## with write access.
  result = f.buffer

proc size*(f: var TMemFile): int {.inline.} =
  ## retrives the size of the memory mapped file `f`.
  result = f.fileLen

