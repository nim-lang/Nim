type
  SystemInfo* = object
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

proc getSystemInfo*(lpSystemInfo: ptr SystemInfo) {.stdcall,
    dynlib: "kernel32", importc: "GetSystemInfo".}
