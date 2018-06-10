#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

proc roundup(x, v: int): int {.inline.} =
  result = (x + (v-1)) and not (v-1)
  sysAssert(result >= x, "roundup: result < x")
  #return ((-x) and (v-1)) +% x

sysAssert(roundup(14, PageSize) == PageSize, "invalid PageSize")
sysAssert(roundup(15, 8) == 16, "roundup broken")
sysAssert(roundup(65, 8) == 72, "roundup broken 2")

# ------------ platform specific chunk allocation code -----------

# some platforms have really weird unmap behaviour:
# unmap(blockStart, PageSize)
# really frees the whole block. Happens for Linux/PowerPC for example. Amd64
# and x86 are safe though; Windows is special because MEM_RELEASE can only be
# used with a size of 0. We also allow unmapping to be turned off with
# -d:nimAllocNoUnmap:
const doNotUnmap = not (defined(amd64) or defined(i386)) or
                   defined(windows) or defined(nimAllocNoUnmap)


when defined(emscripten):
  const
    PROT_READ  = 1             # page can be read
    PROT_WRITE = 2             # page can be written
    MAP_PRIVATE = 2'i32        # Changes are private

  var MAP_ANONYMOUS {.importc: "MAP_ANONYMOUS", header: "<sys/mman.h>".}: cint
  type
    PEmscriptenMMapBlock = ptr EmscriptenMMapBlock
    EmscriptenMMapBlock {.pure, inheritable.} = object
      realSize: int        # size of previous chunk; for coalescing
      realPointer: pointer     # if < PageSize it is a small chunk

  proc mmap(adr: pointer, len: int, prot, flags, fildes: cint,
            off: int): pointer {.header: "<sys/mman.h>".}

  proc munmap(adr: pointer, len: int) {.header: "<sys/mman.h>".}

  proc osAllocPages(block_size: int): pointer {.inline.} =
    let realSize = block_size + sizeof(EmscriptenMMapBlock) + PageSize + 1
    result = mmap(nil, realSize, PROT_READ or PROT_WRITE,
                             MAP_PRIVATE or MAP_ANONYMOUS, -1, 0)
    if result == nil or result == cast[pointer](-1):
      raiseOutOfMem()

    let realPointer = result
    let pos = cast[int](result)

    # Convert pointer to PageSize correct one.
    var new_pos = cast[ByteAddress](pos) +% (PageSize - (pos %% PageSize))
    if (new_pos-pos) < sizeof(EmscriptenMMapBlock):
      new_pos = new_pos +% PageSize
    result = cast[pointer](new_pos)

    var mmapDescrPos = cast[ByteAddress](result) -% sizeof(EmscriptenMMapBlock)

    var mmapDescr = cast[EmscriptenMMapBlock](mmapDescrPos)
    mmapDescr.realSize = realSize
    mmapDescr.realPointer = realPointer

    #c_fprintf(stdout, "[Alloc] size %d %d realSize:%d realPos:%d\n", block_size, cast[int](result), realSize, cast[int](realPointer))

  proc osTryAllocPages(size: int): pointer = osAllocPages(size)

  proc osDeallocPages(p: pointer, size: int) {.inline.} =
    var mmapDescrPos = cast[ByteAddress](p) -% sizeof(EmscriptenMMapBlock)
    var mmapDescr = cast[EmscriptenMMapBlock](mmapDescrPos)
    munmap(mmapDescr.realPointer, mmapDescr.realSize)

elif defined(genode):
  include genode/alloc # osAllocPages, osTryAllocPages, osDeallocPages

elif defined(posix):
  const
    PROT_READ  = 1             # page can be read
    PROT_WRITE = 2             # page can be written

  when defined(macosx) or defined(bsd):
    const MAP_ANONYMOUS = 0x1000
    const MAP_PRIVATE = 0x02        # Changes are private
  elif defined(solaris):
    const MAP_ANONYMOUS = 0x100
    const MAP_PRIVATE = 0x02        # Changes are private
  elif defined(linux) and defined(amd64):
    # actually, any architecture using asm-generic, but being conservative here,
    # some arches like mips and alpha use different values
    const MAP_ANONYMOUS = 0x20
    const MAP_PRIVATE = 0x02        # Changes are private
  else:
    var
      MAP_ANONYMOUS {.importc: "MAP_ANONYMOUS", header: "<sys/mman.h>".}: cint
      MAP_PRIVATE {.importc: "MAP_PRIVATE", header: "<sys/mman.h>".}: cint

  proc mmap(adr: pointer, len: csize, prot, flags, fildes: cint,
            off: int): pointer {.header: "<sys/mman.h>".}

  proc munmap(adr: pointer, len: csize): cint {.header: "<sys/mman.h>".}

  proc osAllocPages(size: int): pointer {.inline.} =
    result = mmap(nil, size, PROT_READ or PROT_WRITE,
                             MAP_PRIVATE or MAP_ANONYMOUS, -1, 0)
    if result == nil or result == cast[pointer](-1):
      raiseOutOfMem()

  proc osTryAllocPages(size: int): pointer {.inline.} =
    result = mmap(nil, size, PROT_READ or PROT_WRITE,
                             MAP_PRIVATE or MAP_ANONYMOUS, -1, 0)
    if result == cast[pointer](-1): result = nil

  proc osDeallocPages(p: pointer, size: int) {.inline.} =
    when reallyOsDealloc: discard munmap(p, size)

elif defined(windows):
  const
    MEM_RESERVE = 0x2000
    MEM_COMMIT = 0x1000
    MEM_TOP_DOWN = 0x100000
    PAGE_READWRITE = 0x04

    MEM_DECOMMIT = 0x4000
    MEM_RELEASE = 0x8000

  proc virtualAlloc(lpAddress: pointer, dwSize: int, flAllocationType,
                    flProtect: int32): pointer {.
                    header: "<windows.h>", stdcall, importc: "VirtualAlloc".}

  proc virtualFree(lpAddress: pointer, dwSize: int,
                   dwFreeType: int32): cint {.header: "<windows.h>", stdcall,
                   importc: "VirtualFree".}

  proc osAllocPages(size: int): pointer {.inline.} =
    result = virtualAlloc(nil, size, MEM_RESERVE or MEM_COMMIT,
                          PAGE_READWRITE)
    if result == nil: raiseOutOfMem()

  proc osTryAllocPages(size: int): pointer {.inline.} =
    result = virtualAlloc(nil, size, MEM_RESERVE or MEM_COMMIT,
                          PAGE_READWRITE)

  proc osDeallocPages(p: pointer, size: int) {.inline.} =
    # according to Microsoft, 0 is the only correct value for MEM_RELEASE:
    # This means that the OS has some different view over how big the block is
    # that we want to free! So, we cannot reliably release the memory back to
    # Windows :-(. We have to live with MEM_DECOMMIT instead.
    # Well that used to be the case but MEM_DECOMMIT fragments the address
    # space heavily, so we now treat Windows as a strange unmap target.
    when reallyOsDealloc:
      if virtualFree(p, 0, MEM_RELEASE) == 0:
        cprintf "virtualFree failing!"
        quit 1
    #VirtualFree(p, size, MEM_DECOMMIT)

elif hostOS == "standalone":
  const StandaloneHeapSize {.intdefine.}: int = 1024 * PageSize
  var
    theHeap: array[StandaloneHeapSize, float64] # 'float64' for alignment
    bumpPointer = cast[int](addr theHeap)

  proc osAllocPages(size: int): pointer {.inline.} =
    if size+bumpPointer < cast[int](addr theHeap) + sizeof(theHeap):
      result = cast[pointer](bumpPointer)
      inc bumpPointer, size
    else:
      raiseOutOfMem()

  proc osTryAllocPages(size: int): pointer {.inline.} =
    if size+bumpPointer < cast[int](addr theHeap) + sizeof(theHeap):
      result = cast[pointer](bumpPointer)
      inc bumpPointer, size

  proc osDeallocPages(p: pointer, size: int) {.inline.} =
    if bumpPointer-size == cast[int](p):
      dec bumpPointer, size
else:
  {.error: "Port memory manager to your platform".}
