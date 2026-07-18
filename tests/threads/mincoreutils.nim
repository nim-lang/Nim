when defined(posix):
  # Linux libcs and Android bionic use unsigned char*. Darwin, the BSDs that
  # expose mincore, AIX, and Solaris use char* for the residency vector.
  when defined(linux) or defined(android):
    type MincoreResidency = uint8
  else:
    type MincoreResidency = char

  proc getpagesize(): cint {.importc, header: "<unistd.h>".}
  proc mincore(p: pointer, length: csize_t,
               residency: ptr MincoreResidency): cint {.
    importc, header: "<sys/mman.h>".}

  proc isResident*(p: pointer): bool =
    let pageSize = uint(getpagesize())
    let page = cast[pointer](cast[uint](p) - cast[uint](p) mod pageSize)
    var residency: MincoreResidency
    result = mincore(page, csize_t(pageSize), addr residency) == 0 and
      (ord(residency) and 1) != 0
