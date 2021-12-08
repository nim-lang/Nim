#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Atomic operations for Nim.
{.push stackTrace:off, profiler:off.}

const someGcc = defined(gcc) or defined(llvm_gcc) or defined(clang)
const someVcc = defined(vcc) or defined(clang_cl)

type
  AtomType* = SomeNumber|pointer|ptr|char|bool
    ## Type Class representing valid types for use with atomic procs

when someGcc and hasThreadSupport:
  type AtomMemModel* = distinct cint

  var ATOMIC_RELAXED* {.importc: "__ATOMIC_RELAXED", nodecl.}: AtomMemModel
    ## No barriers or synchronization.
  var ATOMIC_CONSUME* {.importc: "__ATOMIC_CONSUME", nodecl.}: AtomMemModel
    ## Data dependency only for both barrier and
    ## synchronization with another thread.
  var ATOMIC_ACQUIRE* {.importc: "__ATOMIC_ACQUIRE", nodecl.}: AtomMemModel
    ## Barrier to hoisting of code and synchronizes with
    ## release (or stronger)
    ## semantic stores from another thread.
  var ATOMIC_RELEASE* {.importc: "__ATOMIC_RELEASE", nodecl.}: AtomMemModel
    ## Barrier to sinking of code and synchronizes with
    ## acquire (or stronger)
    ## semantic loads from another thread.
  var ATOMIC_ACQ_REL* {.importc: "__ATOMIC_ACQ_REL", nodecl.}: AtomMemModel
    ## Full barrier in both directions and synchronizes
    ## with acquire loads
    ## and release stores in another thread.
  var ATOMIC_SEQ_CST* {.importc: "__ATOMIC_SEQ_CST", nodecl.}: AtomMemModel
    ## Full barrier in both directions and synchronizes
    ## with acquire loads
    ## and release stores in all threads.

  proc atomicLoadN*[T: AtomType](p: ptr T, mem: AtomMemModel): T {.
    importc: "__atomic_load_n", nodecl.}
    ## This proc implements an atomic load operation. It returns the contents at p.
    ## ATOMIC_RELAXED, ATOMIC_SEQ_CST, ATOMIC_ACQUIRE, ATOMIC_CONSUME.

  proc atomicLoad*[T: AtomType](p, ret: ptr T, mem: AtomMemModel) {.
    importc: "__atomic_load", nodecl.}
    ## This is the generic version of an atomic load. It returns the contents at p in ret.

  proc atomicStoreN*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel) {.
    importc: "__atomic_store_n", nodecl.}
    ## This proc implements an atomic store operation. It writes val at p.
    ## ATOMIC_RELAXED, ATOMIC_SEQ_CST, and ATOMIC_RELEASE.

  proc atomicStore*[T: AtomType](p, val: ptr T, mem: AtomMemModel) {.
    importc: "__atomic_store", nodecl.}
    ## This is the generic version of an atomic store. It stores the value of val at p

  proc atomicExchangeN*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_exchange_n", nodecl.}
    ## This proc implements an atomic exchange operation. It writes val at p,
    ## and returns the previous contents at p.
    ## ATOMIC_RELAXED, ATOMIC_SEQ_CST, ATOMIC_ACQUIRE, ATOMIC_RELEASE, ATOMIC_ACQ_REL

  proc atomicExchange*[T: AtomType](p, val, ret: ptr T, mem: AtomMemModel) {.
    importc: "__atomic_exchange", nodecl.}
    ## This is the generic version of an atomic exchange. It stores the contents at val at p.
    ## The original value at p is copied into ret.

  proc atomicCompareExchangeN*[T: AtomType](p, expected: ptr T, desired: T,
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

  proc atomicCompareExchange*[T: AtomType](p, expected, desired: ptr T,
    weak: bool, success_memmodel: AtomMemModel, failure_memmodel: AtomMemModel): bool {.
    importc: "__atomic_compare_exchange", nodecl.}
    ## This proc implements the generic version of atomic_compare_exchange.
    ## The proc is virtually identical to atomic_compare_exchange_n, except the desired
    ## value is also a pointer.

  ## Perform the operation return the new value, all memory models are valid
  proc atomicAddFetch*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_add_fetch", nodecl.}
  proc atomicSubFetch*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_sub_fetch", nodecl.}
  proc atomicOrFetch*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_or_fetch ", nodecl.}
  proc atomicAndFetch*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_and_fetch", nodecl.}
  proc atomicXorFetch*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_xor_fetch", nodecl.}
  proc atomicNandFetch*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_nand_fetch ", nodecl.}

  ## Perform the operation return the old value, all memory models are valid
  proc atomicFetchAdd*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_fetch_add", nodecl.}
  proc atomicFetchSub*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_fetch_sub", nodecl.}
  proc atomicFetchOr*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_fetch_or", nodecl.}
  proc atomicFetchAnd*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_fetch_and", nodecl.}
  proc atomicFetchXor*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_fetch_xor", nodecl.}
  proc atomicFetchNand*[T: AtomType](p: ptr T, val: T, mem: AtomMemModel): T {.
    importc: "__atomic_fetch_nand", nodecl.}

  proc atomicTestAndSet*(p: pointer, mem: AtomMemModel): bool {.
    importc: "__atomic_test_and_set", nodecl.}
    ## This built-in function performs an atomic test-and-set operation on the byte at p.
    ## The byte is set to some implementation defined nonzero "set" value and the return
    ## value is true if and only if the previous contents were "set".
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
elif someVcc and hasThreadSupport:
  type AtomMemModel* = distinct cint

  const
    ATOMIC_RELAXED = 0.AtomMemModel
    ATOMIC_CONSUME = 1.AtomMemModel
    ATOMIC_ACQUIRE = 2.AtomMemModel
    ATOMIC_RELEASE = 3.AtomMemModel
    ATOMIC_ACQ_REL = 4.AtomMemModel
    ATOMIC_SEQ_CST = 5.AtomMemModel

  proc `==`(x1, x2: AtomMemModel): bool {.borrow.}

  proc readBarrier() {.importc: "_ReadBarrier",  header: "<intrin.h>".}
  proc writeBarrier() {.importc: "_WriteBarrier",  header: "<intrin.h>".}
  proc fence*() {.importc: "_ReadWriteBarrier", header: "<intrin.h>".}

  template barrier(mem: AtomMemModel) =
    when mem == ATOMIC_RELAXED: discard
    elif mem == ATOMIC_CONSUME: readBarrier()
    elif mem == ATOMIC_ACQUIRE: writeBarrier()
    elif mem == ATOMIC_RELEASE: fence()
    elif mem == ATOMIC_ACQ_REL: fence()
    elif mem == ATOMIC_SEQ_CST: fence()

  proc atomicLoadN*[T: AtomType](p: ptr T, mem: static[AtomMemModel]): T =
    result = p[]
    barrier(mem)

  when defined(cpp):
    when sizeof(int) == 8:
      proc addAndFetch*(p: ptr int, val: int): int {.
        importcpp: "_InterlockedExchangeAdd64(static_cast<NI volatile *>(#), #)",
        header: "<intrin.h>".}
    else:
      proc addAndFetch*(p: ptr int, val: int): int {.
        importcpp: "_InterlockedExchangeAdd(reinterpret_cast<long volatile *>(#), static_cast<long>(#))",
        header: "<intrin.h>".}
  else:
    when sizeof(int) == 8:
      proc addAndFetch*(p: ptr int, val: int): int {.
        importc: "_InterlockedExchangeAdd64", header: "<intrin.h>".}
    else:
      proc addAndFetch*(p: ptr int, val: int): int {.
        importc: "_InterlockedExchangeAdd", header: "<intrin.h>".}

else:
  proc addAndFetch*(p: ptr int, val: int): int {.inline.} =
    inc(p[], val)
    result = p[]

proc atomicInc*(memLoc: var int, x: int = 1): int =
  when someGcc and hasThreadSupport:
    result = atomicAddFetch(memLoc.addr, x, ATOMIC_SEQ_CST)
  elif someVcc and hasThreadSupport:
    result = addAndFetch(memLoc.addr, x)
    inc(result, x)
  else:
    inc(memLoc, x)
    result = memLoc

proc atomicDec*(memLoc: var int, x: int = 1): int =
  when someGcc and hasThreadSupport:
    when declared(atomicSubFetch):
      result = atomicSubFetch(memLoc.addr, x, ATOMIC_SEQ_CST)
    else:
      result = atomicAddFetch(memLoc.addr, -x, ATOMIC_SEQ_CST)
  elif someVcc and hasThreadSupport:
    result = addAndFetch(memLoc.addr, -x)
    dec(result, x)
  else:
    dec(memLoc, x)
    result = memLoc

when someVcc:
  when defined(cpp):
    proc interlockedCompareExchange64(p: pointer; exchange, comparand: int64): int64
      {.importcpp: "_InterlockedCompareExchange64(static_cast<NI64 volatile *>(#), #, #)", header: "<intrin.h>".}
    proc interlockedCompareExchange32(p: pointer; exchange, comparand: int32): int32
      {.importcpp: "_InterlockedCompareExchange(static_cast<NI volatile *>(#), #, #)", header: "<intrin.h>".}
    proc interlockedCompareExchange8(p: pointer; exchange, comparand: byte): byte
      {.importcpp: "_InterlockedCompareExchange8(static_cast<char volatile *>(#), #, #)", header: "<intrin.h>".}
  else:
    proc interlockedCompareExchange64(p: pointer; exchange, comparand: int64): int64
      {.importc: "_InterlockedCompareExchange64", header: "<intrin.h>".}
    proc interlockedCompareExchange32(p: pointer; exchange, comparand: int32): int32
      {.importc: "_InterlockedCompareExchange", header: "<intrin.h>".}
    proc interlockedCompareExchange8(p: pointer; exchange, comparand: byte): byte
      {.importc: "_InterlockedCompareExchange8", header: "<intrin.h>".}

  proc cas*[T: bool|int|ptr](p: ptr T; oldValue, newValue: T): bool =
    when sizeof(T) == 8:
      interlockedCompareExchange64(p, cast[int64](newValue), cast[int64](oldValue)) ==
        cast[int64](oldValue)
    elif sizeof(T) == 4:
      interlockedCompareExchange32(p, cast[int32](newValue), cast[int32](oldValue)) ==
        cast[int32](oldValue)
    elif sizeof(T) == 1:
      interlockedCompareExchange8(p, cast[byte](newValue), cast[byte](oldValue)) ==
        cast[byte](oldValue)
    else:
      {.error: "invalid CAS instruction".}

elif defined(tcc):
  when defined(amd64):
    {.emit:"""
static int __tcc_cas(int *ptr, int oldVal, int newVal)
{
    unsigned char ret;
    __asm__ __volatile__ (
            "  lock\n"
            "  cmpxchgq %2,%1\n"
            "  sete %0\n"
            : "=q" (ret), "=m" (*ptr)
            : "r" (newVal), "m" (*ptr), "a" (oldVal)
            : "memory");

    return ret;
}
""".}
  else:
    #assert sizeof(int) == 4
    {.emit:"""
static int __tcc_cas(int *ptr, int oldVal, int newVal)
{
    unsigned char ret;
    __asm__ __volatile__ (
            "  lock\n"
            "  cmpxchgl %2,%1\n"
            "  sete %0\n"
            : "=q" (ret), "=m" (*ptr)
            : "r" (newVal), "m" (*ptr), "a" (oldVal)
            : "memory");

    return ret;
}
""".}

  proc tcc_cas(p: ptr int; oldValue, newValue: int): bool
    {.importc: "__tcc_cas", nodecl.}
  proc cas*[T: bool|int|ptr](p: ptr T; oldValue, newValue: T): bool =
    tcc_cas(cast[ptr int](p), cast[int](oldValue), cast[int](newValue))
elif declared(atomicCompareExchangeN):
  proc cas*[T: bool|int|ptr](p: ptr T; oldValue, newValue: T): bool =
    atomicCompareExchangeN(p, oldValue.unsafeAddr, newValue, false, ATOMIC_SEQ_CST, ATOMIC_SEQ_CST)
else:
  # this is valid for GCC and Intel C++
  proc cas*[T: bool|int|ptr](p: ptr T; oldValue, newValue: T): bool
    {.importc: "__sync_bool_compare_and_swap", nodecl.}
  # XXX is this valid for 'int'?


when (defined(x86) or defined(amd64)) and someVcc:
  proc cpuRelax* {.importc: "YieldProcessor", header: "<windows.h>".}
elif (defined(x86) or defined(amd64)) and (someGcc or defined(bcc)):
  proc cpuRelax* {.inline.} =
    {.emit: """asm volatile("pause" ::: "memory");""".}
elif someGcc or defined(tcc):
  proc cpuRelax* {.inline.} =
    {.emit: """asm volatile("" ::: "memory");""".}
elif defined(icl):
  proc cpuRelax* {.importc: "_mm_pause", header: "xmmintrin.h".}
elif false:
  from os import sleep

  proc cpuRelax* {.inline.} = os.sleep(1)

when not declared(fence) and hasThreadSupport:
  # XXX fixme
  proc fence*() {.inline.} =
    var dummy: bool
    discard cas(addr dummy, false, true)

{.pop.}
