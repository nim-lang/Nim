# Small test program to test for mmap() weirdnesses

include "lib/system/ansi_c"

const
  PageSize = 4096
  PROT_READ  = 1             # page can be read
  PROT_WRITE = 2             # page can be written
  MAP_PRIVATE = 2            # Changes are private

when defined(macosx) or defined(bsd):
  const MAP_ANONYMOUS = 0x1000
elif defined(solaris):
  const MAP_ANONYMOUS = 0x100
else:
  var
    MAP_ANONYMOUS {.importc: "MAP_ANONYMOUS", header: "<sys/mman.h>".}: cint

proc mmap(adr: pointer, len: int, prot, flags, fildes: cint,
          off: int): pointer {.header: "<sys/mman.h>".}

proc munmap(adr: pointer, len: int) {.header: "<sys/mman.h>".}

proc osAllocPages(size: int): pointer {.inline.} =
  result = mmap(nil, size, PROT_READ or PROT_WRITE,
                         MAP_PRIVATE or MAP_ANONYMOUS, -1, 0)
  if result == nil or result == cast[pointer](-1):
    quit 1
  cfprintf(c_stdout, "allocated pages %p..%p\n", result,
                     cast[int](result) + size)

proc osDeallocPages(p: pointer, size: int) {.inline} =
  cfprintf(c_stdout, "freed pages %p..%p\n", p, cast[int](p) + size)
  munmap(p, size-1)

proc `+!!`(p: pointer, size: int): pointer {.inline.} =
  result = cast[pointer](cast[int](p) + size)

var p = osAllocPages(3 * PageSize)

osDeallocPages(p, PageSize)
# If this fails the OS has freed the whole block starting at 'p':
echo(cast[ptr int](p +!! (pageSize*2))[])

osDeallocPages(p +!! PageSize*2, PageSize)
osDeallocPages(p +!! PageSize, PageSize)


