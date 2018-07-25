#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Native Genode Virtual File-System layer.

when not defined(genode):
  {.error: "Genode only module".}

when not defined(vfs):
  {.error: "Genode VFS requires -d:vfs option.".}

import asyncfutures, locks
include genode/env

import ./constructible

type
  FileSize* = culonglong

  VfsHandleObj {.
    importcpp: "Vfs::Vfs_handle", header: "vfs/vfs_handle.h", final, pure.} = object

  VfsHandle* = ptr VfsHandleObj
    ## VFS handles are pointers to file-system specific
    ## objects with a common Vfs_handle base class.

  QueueState = enum qIdle, qRead, qSync
    ## Handle states.

  VfsContext* = ref VfsContextObj
  VfsCallback* = proc (ctx: VfsContext) {.closure, gcsafe.}
  VfsContextObj {.pure, final.} = object
    x, y, z: int
      ## TODO: padding to allow the object to be cast as a
      ## Genode::List<>::Element and inserting into a list.
      ## I am a bad person that should feel bad about this.
    handle*: VfsHandle
    handler*: VfsCallback
    future*: FutureBase
      ## Future for defering exceptions
      ## during I/O signal handling.
    queue: QueueState
      ## Queuing state of the handle.

proc close*(ctx: VfsContext) {.tags: [IOEffect].} =
  ## Close a VFS handle context
  proc close(h: VfsHandle) {.importcpp.}
  close ctx.handle
  reset ctx.handle

proc seek*(ctx: VfsContext): FileSize =
  ## Return seek offset in bytes.
  proc seek(h: VfsHandle): FileSize {.importcpp.}
  assert(ctx.queue == qIdle, "cannot seek VFS context while an operation is queued")
  ctx.handle.seek

proc seek*(ctx: VfsContext; n: FileSize) =
  ## Set seek offset in bytes.
  proc seek(ctx: VfsHandle; n: FileSize) {.importcpp.}
  ctx.handle.seek(n)

proc advanceSeek*(ctx: VfsContext; incr: FileSize) =
  ## Advance seek offset by 'incr' bytes.
  proc advance_seek(h: VfsHandle; incr: FileSize) {.importcpp.}
  ctx.handle.advance_seek(incr)

proc readQueued*(ctx: VfsContext): bool = ctx.queue == qRead
  ## Check if the context is ready for `completeRead`.
proc syncQueued*(ctx: VfsContext): bool = ctx.queue == qSync
  ## Check if the context is ready for `completeSync`.

proc onIOResponse*(ctx: VfsContext; cb: VfsCallback, fut: FutureBase) =
  ## Add a callback to handle an I/O response for the
  ## given context. The future is for defering exceptions
  ## during I/O signal handling.
  assert(not ctx.handle.isNil)
  assert(ctx.handler.isNil,
    "cannot register multiple I/O response handlers on a single VFS context")
  ctx.handler = cb
  ctx.future = fut

type FileIoService {.
  importcpp: "Vfs::File_io_service", header: "vfs/file_io_service.h".} = object
  ## File I/O subset of file-system interface.

proc fs(h: VfsHandle): FileIoService {.importcpp.}
  ## Access the file I/O backend of a handle.

type
  VfsEnvImpl {.
    importcpp: "Nim::VfsEnv", header: "genode_cpp/vfs.h", final, pure.} = object
  VfsEnvObj = Constructible[VfsEnvImpl]
  VfsEnv = ref object
    cpp: VfsEnvObj

proc construct(ve: VfsEnvObj, ge: GenodeEnvPtr) {.importcpp.}

var
  gVfslock*: Lock
  gVfsEnv {.guard: gVfsLock.} = new VfsEnv
construct(gVfsEnv.cpp, runtimeEnv)

proc notifyReadReady*(ctx: VfsContext): bool =
  ## Explicitly indicate interest in read-ready notifications for a context.
  assert(not ctx.handle.isNil)
  proc notify_read_ready(fs: FileIoService; h: VfsHandle): bool {.
    importcpp, tags: [IOEffect].}
  withLock gVfsLock:
    result = ctx.handle.fs.notify_read_ready(ctx.handle)

proc readReady*(ctx: VfsContext): bool =
  ## Return true if the handle can be meaningfully read.
  assert(not ctx.handle.isNil)
  proc read_ready(fs: FileIoService; h: VfsHandle): bool {.
    importcpp, tags: [IOEffect].}
  withLock gVfsLock:
    result = ctx.handle.fs.read_ready(ctx.handle)

proc queueRead*(ctx: VfsContext; size: FileSize) =
  ## Return false if handle read queue is full.
  assert(not ctx.handle.isNil)
  proc queue_read(fs: FileIoService; h: VfsHandle; size: FileSize): bool {.
    importcpp, tags: [IOEffect].}
  assert(ctx.queue == qIdle, "VFS context is already queued")
  withLock gVfsLock:
    if ctx.handle.fs.queue_read(ctx.handle, size):
      ctx.queue = qRead

proc completeRead*(ctx: VfsContext; buf: pointer; size: FileSize): FileSize =
  ## Complete a queued read into a buffer.
  assert(not ctx.handle.isNil)
  assert(ctx.queue == qRead)
  type ReadResult {.importcpp: "Vfs::File_io_service::Read_result", pure.} = enum
    READ_ERR_AGAIN, READ_ERR_WOULD_BLOCK, READ_ERR_INVALID,
    READ_ERR_IO, READ_ERR_INTERRUPT, READ_QUEUED,
    READ_OK
  proc complete_read(
      fs: FileIoService; h: VfsHandle;
      buf: pointer; len: FileSize; outLen: var FileSize): ReadResult {.
    importcpp, tags: [ReadIOEffect].}
  var
    err: ReadResult
  withLock gVfsLock:
    err = ctx.handle.fs.completeRead(ctx.handle, buf, size, result)
  case err
  of READ_QUEUED: discard
  of READ_OK:
    ctx.queue = qIdle
  else:
    ctx.queue = qIdle
    raise newException(IOError, $err)


proc write*(ctx: VfsContext; buf: pointer; len: Natural): FileSize =
  ## Write data to a handle. Writes return immediately, use `completeSync`
  ## to check for errors.
  assert(not ctx.handle.isNil)
  type Result {.importcpp: "Vfs::File_io_service::Write_result", pure.} = enum
    WRITE_ERR_AGAIN, WRITE_ERR_WOULD_BLOCK, WRITE_ERR_INVALID
    WRITE_ERR_IO, WRITE_ERR_INTERRUPT, WRITE_OK
  proc write(
      fs: FileIoService; h: VfsHandle;
      buf: pointer; len: FileSize; outLen: var FileSize): Result {.
    importcpp, tags: [WriteIOEffect].}
  var err: Result
  withLock gVfsLock:
    err = ctx.handle.fs.write(ctx.handle, buf, len, result)
  case err
  of WRITE_OK: discard
  else:
    raise newException(IOError, $err)

proc queueSync*(ctx: VfsContext; len: Natural) =
  ## Return true if a sync can be queued at the handle context.
  assert(not ctx.handle.isNil)
  proc queue_sync(fs: FileIoService; h: VfsHandle): bool {.
    importcpp, tags: [IOEffect].}
  assert(ctx.queue == qIdle, "VFS context is already queued")
  withLock gVfsLock:
    if ctx.handle.fs.queue_sync(ctx.handle):
      ctx.queue = qSync

proc completeSync*(ctx: VfsContext): bool =
  ## Return true if a sync can be completed.
  assert(not ctx.handle.isNil)
  assert(ctx.queue == qSync)
  type Result {.importcpp: "Vfs::File_io_service::Sync_result", pure.} = enum
    SYNC_QUEUED, SYNC_ERR_INVALID, SYNC_OK
  proc complete_sync(fs: FileIoService; h: VfsHandle): Result {.
    importcpp, tags: [IOEffect].}
  var err: Result
  withLock gVfsLock:
    err = ctx.handle.fs.complete_sync(ctx.handle)
  case err
  of SYNC_OK:
    ctx.queue = qIdle
    result = true
  of SYNC_QUEUED: discard
  else:
    ctx.queue = qIdle
    raise newException(IOError, $err)

proc truncate*(ctx: VfsContext; len: Natural) {.tags: [WriteIOEffect].} =
  ## Truncate or expand a file. Handle must be idle.
  assert(ctx.queue == qIdle)
  type Result {.importcpp: "Vfs::File_io_service::Ftruncate_result", pure.} = enum
    FTRUNCATE_ERR_NO_PERM, FTRUNCATE_ERR_INTERRUPT,
    FTRUNCATE_ERR_NO_SPACE, FTRUNCATE_OK 
  proc ftruncate(fs: FileIoService; h: VfsHandle; len: FileSize): Result {.importcpp.}
  var err: Result
  withLock gVfsLock:
    err = ctx.handle.fs.ftruncate(ctx.handle, len.FileSize)
  if err != FTRUNCATE_OK:
    raise newException(IOError, $err)

proc openFileContext*(path: string; fm: FileMode): VfsContext =
  ## Open a VFS handle context.
  type
    Result {.importcpp: "Vfs::Directory_service::Open_result", pure.} = enum
      OPEN_ERR_UNACCESSIBLE, OPEN_ERR_NO_PERM, OPEN_ERR_EXISTS
      OPEN_ERR_NAME_TOO_LONG, OPEN_ERR_NO_SPACE,
      OPEN_ERR_OUT_OF_RAM, OPEN_ERR_OUT_OF_CAPS,
      OPEN_OK
  proc openFile(
      ve: VfsEnvObj; path: cstring; mode: cuint;
      handle: var VfsHandle; arg: pointer): Result {.
    importcpp: "#->openFile(#, #, &#, #)", tags: [IOEffect].}

  var ctx = VfsContext(queue: qIdle)
  proc op(mode: cuint): Result =
    ## Helper to retry open.
    withLock gVfsLock:
      result = gVfsEnv.cpp.openFile(path, mode, ctx.handle, cast[pointer](ctx))

  const
    RDONLY = 0
    WRONLY = 1
    RDWR = 2
    CREATE = 0x0800

  var err: Result
  block:
    case fm
    of fmRead:
      err = op(RDONLY)
    of fmWrite:
      err = op(WRONLY)
      if err == OPEN_ERR_UNACCESSIBLE:
        err = op(WRONLY or CREATE)
      else: discard
    of fmReadWrite:
      err = op(RDWR)
      if err == OPEN_ERR_UNACCESSIBLE:
        err = op(RDWR or CREATE)
    of fmReadWriteExisting:
      err = op(RDWR)
    of fmAppend:
      err = op(WRONLY)
  if err != OPEN_OK:
    raise newException(IOError, $err)
  assert(not ctx.handle.isNil)
  if fm in {fmWrite, fmReadWrite}:
    ctx.truncate(0)
  if fm in {fmRead, fmReadWrite, fmReadWriteExisting}:
    discard ctx.notifyReadReady()
  ctx
