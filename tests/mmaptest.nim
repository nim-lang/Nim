# Small test program to test for mmap() weirdnesses

import system/ansi_c
import posix

proc osAllocPages(size: int): pointer {.inline.} =
  result = mmap(nil, size, PROT_READ or PROT_WRITE,
                         MAP_PRIVATE or MAP_ANONYMOUS, -1, 0)
  if result == nil or result == cast[pointer](-1):
    quit 1
  cfprintf(c_stdout, "allocated pages %p..%p\n", result,
                     cast[int](result) + size)

proc osDeallocPages(p: pointer, size: int) {.inline} =
  cfprintf(c_stdout, "freed pages %p..%p\n", p, cast[int](p) + size)
  discard munmap(p, size-1)

proc `+!!`(p: pointer, size: int): pointer {.inline.} =
  result = cast[pointer](cast[int](p) + size)

const
  PageShift = when defined(nimPage256) or defined(cpu16): 8
              elif defined(nimPage512): 9
              elif defined(nimPage1k): 10
              else: 12 # \ # my tests showed no improvements for using larger page sizes.

  PageSize = 1 shl PageShift

var p = osAllocPages(3 * PageSize)

osDeallocPages(p, PageSize)
# If this fails the OS has freed the whole block starting at 'p':
echo(cast[ptr int](p +!! (PageSize*2))[])

osDeallocPages(p +!! PageSize*2, PageSize)
osDeallocPages(p +!! PageSize, PageSize)
