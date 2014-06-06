#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Atomic operations for Nimrod.
{.push stackTrace:off.}

const someGcc = defined(gcc) or defined(llvm_gcc) or defined(clang)

when someGcc and hasThreadSupport:
  type 
    AtomMemModel* = enum
      ATOMIC_RELAXED,  ## No barriers or synchronization. 
      ATOMIC_CONSUME,  ## Data dependency only for both barrier and
                       ## synchronization with another thread.
      ATOMIC_ACQUIRE,  ## Barrier to hoisting of code and synchronizes with
                       ## release (or stronger) 
                       ## semantic stores from another thread.
      ATOMIC_RELEASE,  ## Barrier to sinking of code and synchronizes with
                       ## acquire (or stronger) 
                       ## semantic loads from another thread. 
      ATOMIC_ACQ_REL,  ## Full barrier in both directions and synchronizes
                       ## with acquire loads 
                       ## and release stores in another thread.
      ATOMIC_SEQ_CST   ## Full barrier in both directions and synchronizes
                       ## with acquire loads 
                       ## and release stores in all threads.

    TAtomType* = TNumber|pointer|ptr|char
      ## Type Class representing valid types for use with atomic procs

  proc atomicLoadN*[T: TAtomType](p: ptr T, mem: AtomMemModel): T {.
    importc: "__atomic_load_n", nodecl.}
    ## This proc implements an atomic load operation. It returns the contents at p.
    ## ATOMIC_RELAXED, ATOMIC_SEQ_CST, ATOMIC_ACQUIRE, ATOMIC_CONSUME.

  proc atomicLoad*[T: TAtomType](p, ret: ptr T, mem: AtomMemModel) {.
    importc: "__atomic_load", nodecl.}  
    ## This is the generic version of an atomic load. It returns the contents at p in ret.

  proc atomicStoreN*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel) {.
    importc: "__atomic_store_n", nodecl.} 
    ## This proc implements an atomic store operation. It writes val at p.
    ## ATOMIC_RELAXED, ATOMIC_SEQ_CST, and ATOMIC_RELEASE.

  proc atomicStore*[T: TAtomType](p, val: ptr T, mem: AtomMemModel) {.
    importc: "__atomic_store", nodecl.}
    ## This is the generic version of an atomic store. It stores the value of val at p

  proc atomicExchangeN*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_exchange_n", nodecl.}
    ## This proc implements an atomic exchange operation. It writes val at p, 
    ## and returns the previous contents at p.
    ## ATOMIC_RELAXED, ATOMIC_SEQ_CST, ATOMIC_ACQUIRE, ATOMIC_RELEASE, ATOMIC_ACQ_REL

  proc atomicExchange*[T: TAtomType](p, val, ret: ptr T, mem: AtomMemModel) {.
    importc: "__atomic_exchange", nodecl.}
    ## This is the generic version of an atomic exchange. It stores the contents at val at p. 
    ## The original value at p is copied into ret.

  proc atomicCompareExchangeN*[T: TAtomType](p, expected: ptr T, desired: T,
    weak: bool, success_memmodel: AtomMemModel, failure_memmodel: AtomMemModel): bool {.
    importc: "__atomic_compare_exchange_n ", nodecl.} 
    ## This proc implements an atomic compare and exchange operation. This compares the
    ## contents at p with the contents at expected and if equal, writes desired at p. 
    ## If they are not equal, the current contents at p is written into expected. 
    ## Weak is true for weak compare_exchange, and false for the strong variation. 
    ## Many targets only offer the strong variation and ignore the parameter. 
    ## When in doubt, use the strong variation.
    ## True is returned if desired is written at p and the execution is considered 
    ## to conform to the memory model specified by success_memmodel. There are no 
    ## restrictions on what memory model can be used here. False is returned otherwise, 
    ## and the execution is considered to conform to failure_memmodel. This memory model 
    ## cannot be __ATOMIC_RELEASE nor __ATOMIC_ACQ_REL. It also cannot be a stronger model 
    ## than that specified by success_memmodel.

  proc atomicCompareExchange*[T: TAtomType](p, expected, desired: ptr T,
    weak: bool, success_memmodel: AtomMemModel, failure_memmodel: AtomMemModel): bool {.
    importc: "__atomic_compare_exchange_n ", nodecl.}  
    ## This proc implements the generic version of atomic_compare_exchange. 
    ## The proc is virtually identical to atomic_compare_exchange_n, except the desired 
    ## value is also a pointer. 

  ## Perform the operation return the new value, all memory models are valid 
  proc atomicAddFetch*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_add_fetch", nodecl.}
  proc atomicSubFetch*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_sub_fetch", nodecl.}
  proc atomicOrFetch*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_or_fetch ", nodecl.}
  proc atomicAndFetch*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_and_fetch", nodecl.}
  proc atomicXorFetch*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.   
    importc: "__atomic_xor_fetch", nodecl.}
  proc atomicNandFetch*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.   
    importc: "__atomic_nand_fetch ", nodecl.} 

  ## Perform the operation return the old value, all memory models are valid 
  proc atomicFetchAdd*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_fetch_add", nodecl.}
  proc atomicFetchSub*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.  
    importc: "__atomic_fetch_sub", nodecl.}
  proc atomicFetchOr*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.  
    importc: "__atomic_fetch_or", nodecl.}
  proc atomicFetchAnd*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.   
    importc: "__atomic_fetch_and", nodecl.}
  proc atomicFetchXor*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.  
    importc: "__atomic_fetch_xor", nodecl.}
  proc atomicFetchNand*[T: TAtomType](p: ptr T, val: T, mem: AtomMemModel): T {.  
    importc: "__atomic_fetch_nand", nodecl.} 

  proc atomicTestAndSet*(p: pointer, mem: AtomMemModel): bool {.  
    importc: "__atomic_test_and_set", nodecl.} 
    ## This built-in function performs an atomic test-and-set operation on the byte at p. 
    ## The byte is set to some implementation defined nonzero “set” value and the return
    ## value is true if and only if the previous contents were “set”.
    ## All memory models are valid.

  proc atomicClear*(p: pointer, mem: AtomMemModel) {.  
    importc: "__atomic_clear", nodecl.}
    ## This built-in function performs an atomic clear operation at p. 
    ## After the operation, at p contains 0.
    ## ATOMIC_RELAXED, ATOMIC_SEQ_CST, ATOMIC_RELEASE

  proc atomicThreadFence*(mem: AtomMemModel) {.  
    importc: "__atomic_thread_fence", nodecl.}
    ## This built-in function acts as a synchronization fence between threads based 
    ## on the specified memory model. All memory orders are valid.

  proc atomicSignalFence*(mem: AtomMemModel) {.  
    importc: "__atomic_signal_fence", nodecl.}
    ## This built-in function acts as a synchronization fence between a thread and 
    ## signal handlers based in the same thread. All memory orders are valid.

  proc atomicAlwaysLockFree*(size: int, p: pointer): bool {.  
    importc: "__atomic_always_lock_free", nodecl.}
    ## This built-in function returns true if objects of size bytes always generate 
    ## lock free atomic instructions for the target architecture. size must resolve 
    ## to a compile-time constant and the result also resolves to a compile-time constant.
    ## ptr is an optional pointer to the object that may be used to determine alignment. 
    ## A value of 0 indicates typical alignment should be used. The compiler may also 
    ## ignore this parameter.

  proc atomicIsLockFree*(size: int, p: pointer): bool {.  
    importc: "__atomic_is_lock_free", nodecl.}
    ## This built-in function returns true if objects of size bytes always generate 
    ## lock free atomic instructions for the target architecture. If it is not known 
    ## to be lock free a call is made to a runtime routine named __atomic_is_lock_free.
    ## ptr is an optional pointer to the object that may be used to determine alignment. 
    ## A value of 0 indicates typical alignment should be used. The compiler may also 
    ## ignore this parameter.

  template fence*() = atomicThreadFence(ATOMIC_SEQ_CST)
elif defined(vcc) and hasThreadSupport:
  proc addAndFetch*(p: ptr int, val: int): int {.
    importc: "NimXadd", nodecl.}

else:
  proc addAndFetch*(p: ptr int, val: int): int {.inline.} =
    inc(p[], val)
    result = p[]

proc atomicInc*(memLoc: var int, x: int = 1): int =
  when defined(gcc) and hasThreadSupport:
    result = atomic_add_fetch(memLoc.addr, x, ATOMIC_RELAXED)
  else:
    inc(memLoc, x)
    result = memLoc
  
proc atomicDec*(memLoc: var int, x: int = 1): int =
  when defined(gcc) and hasThreadSupport:
    when defined(atomic_sub_fetch):
      result = atomic_sub_fetch(memLoc.addr, x, ATOMIC_RELAXED)
    else:
      result = atomic_add_fetch(memLoc.addr, -x, ATOMIC_RELAXED)
  else:
    dec(memLoc, x)
    result = memLoc

when defined(windows) and not someGcc:
  proc interlockedCompareExchange(p: pointer; exchange, comparand: int32): int32
    {.importc: "InterlockedCompareExchange", header: "<windows.h>", cdecl.}

  proc cas*[T: bool|int|ptr](p: ptr T; oldValue, newValue: T): bool =
    interlockedCompareExchange(p, newValue.int32, oldValue.int32) != 0
  # XXX fix for 64 bit build
else:
  # this is valid for GCC and Intel C++
  proc cas*[T: bool|int|ptr](p: ptr T; oldValue, newValue: T): bool
    {.importc: "__sync_bool_compare_and_swap", nodecl.}
  # XXX is this valid for 'int'?


when (defined(x86) or defined(amd64)) and (defined(gcc) or defined(llvm_gcc)):
  proc cpuRelax {.inline.} =
    {.emit: """asm volatile("pause" ::: "memory");""".}
elif (defined(x86) or defined(amd64)) and defined(vcc):
  proc cpuRelax {.importc: "YieldProcessor", header: "<windows.h>".}
elif defined(intelc):
  proc cpuRelax {.importc: "_mm_pause", header: "xmmintrin.h".}
elif false:
  from os import sleep

  proc cpuRelax {.inline.} = os.sleep(1)

when not defined(fence) and hasThreadSupport:
  # XXX fixme
  proc fence*() {.inline.} =
    var dummy: bool
    discard cas(addr dummy, false, true)

{.pop.}
