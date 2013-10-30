#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Atomic operations for Nimrod.

when (defined(gcc) or defined(llvm_gcc)) and hasThreadSupport and
    not defined(windows):
  proc sync_add_and_fetch(p: var int, val: int): int {.
    importc: "__sync_add_and_fetch", nodecl.}
  proc sync_sub_and_fetch(p: var int, val: int): int {.
    importc: "__sync_sub_and_fetch", nodecl.}
elif defined(vcc) and hasThreadSupport:
  proc sync_add_and_fetch(p: var int, val: int): int {.
    importc: "NimXadd", nodecl.}
else:
  proc sync_add_and_fetch(p: var int, val: int): int {.inline.} =
    inc(p, val)
    result = p

proc atomicInc(memLoc: var int, x: int = 1): int =
  when hasThreadSupport:
    result = sync_add_and_fetch(memLoc, x)
  else:
    inc(memLoc, x)
    result = memLoc

proc atomicDec(memLoc: var int, x: int = 1): int =
  when hasThreadSupport:
    when defined(sync_sub_and_fetch):
      result = sync_sub_and_fetch(memLoc, x)
    else:
      result = sync_add_and_fetch(memLoc, -x)
  else:
    dec(memLoc, x)
    result = memLoc


# atomic compare and swap (CAS) funcitons to implement lock-free algorithms

when (defined(gcc) or defined(llvm_gcc)) and hasThreadSupport:
  proc compareAndSwap*[T: ptr|ref|pointer](mem: var T, expected: T, newValue: T): bool {.nodecl,
      importc: " __sync_bool_compare_and_swap".}
    ## Returns true if successfully set value at mem to newValue when value
    ## at mem == expected

elif defined(windows) and hasThreadSupport:
    proc InterlockedCompareExchangePointer(mem: ptr pointer,
      newValue: pointer, comparand: pointer) : pointer {.nodecl,
        importc: "InterlockedCompareExchangePointer", header:"windows.h".}


    proc compareAndSwap*[T: ptr|ref|pointer](mem: var T,
      expected: T, newValue: T): bool {.inline.}=
      ## Returns true if successfully set value at mem to newValue when value
      ## at mem == expected
      return InterlockedCompareExchangePointer(addr(mem),
        newValue, expected) == expected

elif not hasThreadSupport:
  proc compareAndSwap*[T: ptr|ref|pointer](mem: var T,
    expected: T, newValue: T): bool {.inline.} =
      ## Returns true if successfully set value at mem to newValue when value
      ## at mem == expected
      var oldval = mem
      if oldval == expected:
        mem = newValue
        return true
      return false


