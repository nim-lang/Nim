type
  SYSTEM_INFO* {.final, pure.} = object
    u1: uint32
    dwPageSize: uint32
    lpMinimumApplicationAddress: pointer
    lpMaximumApplicationAddress: pointer
    dwActiveProcessorMask: ptr uint32
    dwNumberOfProcessors*: uint32
    dwProcessorType: uint32
    dwAllocationGranularity*: uint32
    wProcessorLevel: uint16
    wProcessorRevision: uint16

proc GetSystemInfo*(lpSystemInfo: ptr SYSTEM_INFO) {.stdcall,
    dynlib: "kernel32", importc: "GetSystemInfo".}
