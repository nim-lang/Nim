## All of these library headers and source can be found in the github repo
## https://github.com/switchbrew/libnx.

const virtMemHeader = "<switch/kernel/virtmem.h>"
const svcHeader = "<switch/kernel/svc.h>"
const mallocHeader = "<malloc.h>"

## Aligns a block of memory with request `size` to `bytes` size. For
## example, a request of memalign(0x1000, 0x1001) == 0x2000 bytes allocated
proc memalign*(bytes: csize, size: csize): pointer {.importc: "memalign",
    header: mallocHeader.}

# Should be required, but not needed now because of how
# svcUnmapMemory frees all memory
#proc free*(address: pointer) {.importc: "free",
#    header: mallocHeader.}

## Maps a memaligned block of memory from `src_addr` to `dst_addr`. The
## Nintendo Switch requires this call in order to make use of memory, otherwise
## an invalid memory access occurs.
proc svcMapMemory*(dst_addr: pointer; src_addr: pointer; size: uint64): uint32 {.
    importc: "svcMapMemory", header: svcHeader.}

## Unmaps (frees) all memory from both `dst_addr` and `src_addr`. **Must** be called
## whenever svcMapMemory is used. The Switch will expect all memory to be allocated
## before gfxExit() calls (<switch/gfx/gfx.h>)
proc svcUnmapMemory*(dst_addr: pointer; src_addr: pointer; size: uint64): uint32 {.
    importc: "svcUnmapMemory", header: svcHeader.}

proc virtmemReserveMap*(size: csize): pointer {.importc: "virtmemReserveMap",
    header: virtMemHeader.}

# Should be required, but not needed now because of how
# svcUnmapMemory frees all memory
#proc virtmemFreeMap*(address: pointer; size: csize) {.importc: "virtmemFreeMap",
#    header: virtMemHeader.}
