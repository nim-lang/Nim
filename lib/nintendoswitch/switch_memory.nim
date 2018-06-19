const virtMemHeader = "<switch/kernel/virtmem.h>"
const svcHeader = "<switch/kernel/virtmem.h>"
const mallocHeader = "<malloc.h>"

type
  Result* = uint32

proc memalign*(bytes: csize, size: csize): pointer {.importc: "memalign",
    header: mallocHeader.}

proc free*(address: pointer) {.importc: "free",
    header: mallocHeader.}

proc svcMapMemory*(dst_addr: pointer; src_addr: pointer; size: uint64): Result {.
    importc: "svcMapMemory", header: svcHeader.}

proc svcUnmapMemory*(dst_addr: pointer; src_addr: pointer; size: uint64): Result {.
    importc: "svcUnmapMemory", header: svcHeader.}

proc virtmemReserveMap*(size: csize): pointer {.importc: "virtmemReserveMap",
    header: virtMemHeader.}

proc virtmemFreeMap*(address: pointer; size: csize) {.importc: "virtmemFreeMap",
    header: virtMemHeader.}
