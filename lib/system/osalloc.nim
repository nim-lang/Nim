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


when defined(emscripten) and not defined(StandaloneHeapSize):
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

elif defined(genode) and not defined(StandaloneHeapSize):
  include genode/alloc # osAllocPages, osTryAllocPages, osDeallocPages

elif defined(nintendoswitch) and not defined(StandaloneHeapSize):

  import nintendoswitch/switch_memory

  type
    PSwitchBlock = ptr NSwitchBlock
    ## This will hold the heap pointer data in a separate
    ## block of memory that is PageSize bytes above
    ## the requested memory. It's the only good way
    ## to pass around data with heap allocations
    NSwitchBlock {.pure, inheritable.} = object
      realSize: int
      heap: pointer           # pointer to main heap alloc
      heapMirror: pointer     # pointer to virtmem mapped heap

  proc alignSize(size: int): int {.inline.} =
    ## Align a size integer to be in multiples of PageSize
    ## The nintendo switch will not allocate memory that is not
    ## aligned to 0x1000 bytes and will just crash.
    (size + (PageSize - 1)) and not (PageSize - 1)

  proc deallocate(heapMirror: pointer, heap: pointer, size: int) =
    # Unmap the allocated memory
    discard svcUnmapMemory(heapMirror, heap, size.uint64)
    # These should be called (theoretically), but referencing them crashes the switch.
    # The above call seems to free all heap memory, so these are not needed.
    # virtmemFreeMap(nswitchBlock.heapMirror, nswitchBlock.realSize.csize)
    # free(nswitchBlock.heap)

  proc freeMem(p: pointer) =
    # Retrieve the switch block data from the pointer we set before
    # The data is located just sizeof(NSwitchBlock) bytes below
    # the top of the pointer to the heap
    let
      nswitchDescrPos = cast[ByteAddress](p) -% sizeof(NSwitchBlock)
      nswitchBlock = cast[PSwitchBlock](nswitchDescrPos)

    deallocate(
      nswitchBlock.heapMirror, nswitchBlock.heap, nswitchBlock.realSize
    )

  proc storeHeapData(address, heapMirror, heap: pointer, size: int) {.inline.} =
    ## Store data in the heap for deallocation purposes later

    # the position of our heap pointer data. Since we allocated PageSize extra
    # bytes, we should have a buffer on top of the requested size of at least
    # PageSize bytes, which is much larger than sizeof(NSwitchBlock). So we
    # decrement the address by sizeof(NSwitchBlock) and use that address
    # to store our pointer data
    let nswitchBlockPos = cast[ByteAddress](address) -% sizeof(NSwitchBlock)

    # We need to store this in a pointer obj (PSwitchBlock) so that the data sticks
    # at the address we've chosen. If NSwitchBlock is used here, the data will
    # be all 0 when we try to retrieve it later.
    var nswitchBlock = cast[PSwitchBlock](nswitchBlockPos)
    nswitchBlock.realSize = size
    nswitchBlock.heap = heap
    nswitchBlock.heapMirror = heapMirror

  proc getOriginalHeapPosition(address: pointer, difference: int): pointer {.inline.} =
    ## This function sets the heap back to the originally requested
    ## size
    let
      pos = cast[int](address)
      newPos = cast[ByteAddress](pos) +% difference

    return cast[pointer](newPos)

  template allocPages(size: int, outOfMemoryStmt: untyped): untyped =
    # This is to ensure we get a block of memory the requested
    # size, as well as space to store our structure
    let realSize = alignSize(size + sizeof(NSwitchBlock))

    let heap = memalign(PageSize, realSize)

    if heap.isNil:
      outOfMemoryStmt

    let heapMirror = virtmemReserveMap(realSize.csize)
    result = heapMirror

    let rc = svcMapMemory(heapMirror, heap, realSize.uint64)
    # Any return code not equal 0 means an error in libnx
    if rc.uint32 != 0:
      deallocate(heapMirror, heap, realSize)
      outOfMemoryStmt

    # set result to be the original size requirement
    result = getOriginalHeapPosition(result, realSize - size)

    storeHeapData(result, heapMirror, heap, realSize)

  proc osAllocPages(size: int): pointer {.inline.} =
    allocPages(size):
      raiseOutOfMem()

  proc osTryAllocPages(size: int): pointer =
    allocPages(size):
      return nil

  proc osDeallocPages(p: pointer, size: int) =
    # Note that in order for the Switch not to crash, a call to
    # deallocHeap(runFinalizers = true, allowGcAfterwards = false)
    # must be run before gfxExit(). The Switch requires all memory
    # to be deallocated before the graphics application has exited.
    #
    # gfxExit() can be found in <switch/gfx/gfx.h> in the github
    # repo https://github.com/switchbrew/libnx
    when reallyOsDealloc:
      freeMem(p)

elif defined(posix) and not defined(StandaloneHeapSize):
  const
    PROT_READ  = 1             # page can be read
    PROT_WRITE = 2             # page can be written

  when defined(netbsd) or defined(openbsd):
      # OpenBSD security for setjmp/longjmp coroutines
      var MAP_STACK {.importc: "MAP_STACK", header: "<sys/mman.h>".}: cint
  else:
    const MAP_STACK = 0             # avoid sideeffects
    
  when defined(macosx) or defined(freebsd):
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
  elif defined(haiku):
    const MAP_ANONYMOUS = 0x08
    const MAP_PRIVATE = 0x02
  else:  # posix including netbsd or openbsd
    var
      MAP_ANONYMOUS {.importc: "MAP_ANONYMOUS", header: "<sys/mman.h>".}: cint
      MAP_PRIVATE {.importc: "MAP_PRIVATE", header: "<sys/mman.h>".}: cint

  proc mmap(adr: pointer, len: csize_t, prot, flags, fildes: cint,
            off: int): pointer {.header: "<sys/mman.h>".}

  proc munmap(adr: pointer, len: csize_t): cint {.header: "<sys/mman.h>".}

  proc osAllocPages(size: int): pointer {.inline.} =
    result = mmap(nil, cast[csize_t](size), PROT_READ or PROT_WRITE,
                             MAP_ANONYMOUS or MAP_PRIVATE or MAP_STACK, -1, 0)
    if result == nil or result == cast[pointer](-1):
      raiseOutOfMem()

  proc osTryAllocPages(size: int): pointer {.inline.} =
    result = mmap(nil, cast[csize_t](size), PROT_READ or PROT_WRITE,
                             MAP_ANONYMOUS or MAP_PRIVATE or MAP_STACK, -1, 0)
    if result == cast[pointer](-1): result = nil

  proc osDeallocPages(p: pointer, size: int) {.inline.} =
    when reallyOsDealloc: discard munmap(p, cast[csize_t](size))

elif defined(windows) and not defined(StandaloneHeapSize):
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

elif hostOS == "standalone" or defined(StandaloneHeapSize):
  const StandaloneHeapSize {.intdefine.}: int = 1024 * PageSize
  var
    theHeap: array[StandaloneHeapSize div sizeof(float64), float64] # 'float64' for alignment
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
