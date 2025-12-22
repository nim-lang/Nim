#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Jörg Wollenschläger
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Types and operations for atomic operations and lockless algorithms.
##
## Unstable API.
##
## Lock-free vs Spinlock
## ---------------------
## Lock-free eligibility depends on type size, architecture, and memory manager.
## Types that don't qualify fall back to a spinlock.
##
## **Size requirements:**
## - 1, 2, 4 bytes: lock-free (requires natural alignment)
## - 8 bytes: requires `hasLockFree8` (see below)
## - 16 bytes: requires `hasLockFree16` (see below)
## - Other sizes: uses spinlock
##
## **Memory manager requirements:**
## - With destructor-based MMs (`--mm:arc`, `--mm:orc`, `--mm:atomicArc`):
##   `supportsCopyMem(T)` must be true (excludes `ref`, `string`, `seq`)
## - With non-destructor MMs (`--mm:refc`, `--mm:markAndSweep`, `--mm:none`):
##   managed types of a correct size can use lock-free atomics
##
## Architecture Support
## --------------------
## **8-byte atomics** (`hasLockFree8`):
## - All 64-bit architectures
## - x86-32 (CMPXCHG8B, Pentium and later)
## - ARM32 (LDREXD/STREXD, ARMv6K+; not ARMv7-M)
## - NOT supported: MIPS32, SPARC32, PowerPC32, RISC-V 32
##
## **16-byte atomics** (`hasLockFree16`):
## - x86-64 (CMPXCHG16B, standard since ~2006)
## - ARM64 (LDXP/STXP; full 128-bit atomicity requires ARMv8.4+)
## - Use `-d:nimNoLockFree16` to disable for old x86-64 CPUs without CMPXCHG16B
##
## Use `T.isLockFree` to check at compile-time whether a type uses lock-free
## operations. By default, non-lock-free types cause a compile error. To allow
## spinlock fallback, compile with `-d:nimAllowAtomicSpinlock`.
##
## C++ Backend
## -----------
## By default, C++ backend uses C11 atomic primitives. To use C++ `std::atomic`,
## compile with `-d:nimUseCppAtomics`.
##
## Safety with Managed Types
## -------------------------
## **Important:** Lock-free atomics on managed types (`ref`, `string`, `seq`)
## means the *swap operation* is lock-free, NOT that concurrent access is safe.
##
## Naively using `Atomic[ref T]` leads to memory corruption:
## - **Use-after-free:** Thread A loads pointer, Thread B frees object, Thread A dereferences
## - **ABA problem:** Pointer reused for new object between load and CAS
##
## **Memory manager determines what's possible:**
##
## | Memory Manager     | Lock-free refs? | Notes |
## |--------------------|-----------------|-------|
## | `--mm:refc`        | No              | Thread-local heaps; refs can't cross threads |
## | `--mm:markAndSweep`| No              | Thread-local heaps; refs can't cross threads |
## | `--mm:arc/orc`     | No              | Non-atomic refcount; use locks or `--mm:atomicArc` |
## | `--mm:atomicArc`   | Yes             | Use `GC_ref`/`GC_unref`; prevent ABA and use-after-free |
## | `--mm:boehm`       | Yes             | `GC_ref`/`GC_unref` are no-ops; prevent ABA and use-after-free |
## | `--mm:go`          | Yes             | `GC_ref`/`GC_unref` are no-ops; prevent ABA and use-after-free |
## | `--mm:none`        | Yes             | You manually manage all memory |
##

import std/typetraits

template isManaged(T: typedesc): bool =
  ## Returns `true` if `T` contains managed memory that prevents lock-free atomics.
  ## With non-destructor MMs (refc, markAndSweep, none), managed types like
  ## `ref`, `string`, `seq` are pointer-sized and can be atomically swapped.
  ## With destructor-based MMs (arc, orc, atomicArc), `supportsCopyMem` determines this.
  when defined(gcdestructors):
    not supportsCopyMem(T)
  else:
    false  # Non-destructor MMs: managed types are pointer-sized

const
  hasLockFree8* = sizeof(pointer) >= 8 or  # All 64-bit architectures
                  defined(i386) or          # x86-32 has CMPXCHG8B
                  defined(arm)              # ARM32 has LDREXD/STREXD (ARMv6k+)
    ## Whether 8-byte atomics are lock-free on this architecture.
    ##
    ## **True for:**
    ## - All 64-bit CPUs
    ## - x86-32 (CMPXCHG8B)
    ## - ARM32 (LDREXD)
    ##
    ## **False for:** MIPS32, SPARC32, PowerPC32, RISC-V 32

  hasLockFree16* = not defined(nimNoLockFree16) and
                   (defined(amd64) or  # x86-64 has CMPXCHG16B (standard since ~2006)
                    defined(arm64))    # ARM64 has LDXP/STXP
    ## Whether 16-byte atomics are lock-free on this architecture.
    ##
    ## **True for:**
    ## - x86-64 (CMPXCHG16B)
    ## - ARM64 (LDXP/STXP)
    ##
    ## Use `-d:nimNoLockFree16` to disable for old x86-64 CPUs without CMPXCHG16B.

template isLockFree*(T: typedesc): bool =
  ## Returns `true` if `Atomic[T]` uses lock-free hardware atomics,
  ## `false` if it falls back to a spinlock.
  ##
  ## Lock-free requires:
  ## - `sizeof(T)` must be 1, 2, 4, 8, or 16 bytes
  ## - 8-byte requires `hasLockFree8`
  ## - 16-byte requires `hasLockFree16`
  ## - `supportsCopyMem(T)` (no managed memory) for destructor-based MMs (arc/orc/atomicArc)
  ## - For non-destructor MMs (refc/none/etc), managed types are pointer-sized and qualify
  (sizeof(T) == 1 or sizeof(T) == 2 or sizeof(T) == 4 or
   (sizeof(T) == 8 and hasLockFree8) or
   (sizeof(T) == 16 and hasLockFree16)) and not isManaged(T)

template enforceLockFreeCheck(T: typedesc) =
  ## Internal template to emit compile-time error when type cannot use lock-free
  ## atomics, unless `-d:nimAllowAtomicSpinlock` is defined to allow fallback.
  when not defined(nimAllowAtomicSpinlock):
    when not (sizeof(T) == 1 or sizeof(T) == 2 or sizeof(T) == 4 or
              (sizeof(T) == 8 and hasLockFree8) or
              (sizeof(T) == 16 and hasLockFree16)):
      {.error: "Atomic[" & $T & "] cannot use lock-free atomics: sizeof(" & $T & ") = " &
               $sizeof(T) & " is not a valid atomic size. " &
               "Use -d:nimAllowAtomicSpinlock to allow spinlock fallback.".}
    elif isManaged(T):
      {.error: "Atomic[" & $T & "] cannot use lock-free atomics: type contains managed memory " &
               "and cannot be safely copied with this memory manager. " &
               "Use -d:nimAllowAtomicSpinlock to allow spinlock fallback.".}

runnableExamples:
  # Check lock-free status at compile time
  assert isLockFree(int)
  assert isLockFree(bool)

  type Point = object
    x, y: int32
  assert isLockFree(Point) == (sizeof(Point) <= sizeof(pointer))

  # Large types use spinlock fallback
  type BigArray = array[100, int]
  assert not isLockFree(BigArray)

runnableExamples:
  # Atomic
  var loc: Atomic[int]
  loc.store(4)
  assert loc.load == 4
  loc.store(2)
  assert loc.load(moRelaxed) == 2
  loc.store(9)
  assert loc.load(moAcquire) == 9
  loc.store(0, moRelease)
  assert loc.load == 0

  assert loc.exchange(7) == 0
  assert loc.load == 7

  var expected = 7
  assert loc.compareExchange(expected, 5, moRelaxed, moRelaxed)
  assert expected == 7
  assert loc.load == 5

  assert not loc.compareExchange(expected, 12, moRelaxed, moRelaxed)
  assert expected == 5
  assert loc.load == 5

  assert loc.fetchAdd(1) == 5
  assert loc.fetchAdd(2) == 6
  assert loc.fetchSub(3) == 8

  loc.atomicInc(1)
  assert loc.load == 6

  # AtomicFlag
  var flag: AtomicFlag

  assert not flag.testAndSet
  assert flag.testAndSet
  flag.clear(moRelaxed)
  assert not flag.testAndSet

when (defined(cpp) and defined(nimUseCppAtomics)) or defined(nimdoc):
  # For the C++ backend, types and operations map directly to C++11 atomics.

  # On Linux with GCC/Clang, 16-byte atomic operations may not be inlined
  # and require libatomic even when using C++ std::atomic.
  when defined(linux) and hasLockFree16:
    {.passL: "-latomic".}

  {.push, header: "<atomic>".}

  type
    MemoryOrder* {.importcpp: "std::memory_order".} = enum
      ## Specifies how non-atomic operations can be reordered around atomic
      ## operations.

      moRelaxed
        ## No ordering constraints. Only the atomicity and ordering against
        ## other atomic operations is guaranteed.

      moConsume
        ## This ordering is currently discouraged as it's semantics are
        ## being revised. Acquire operations should be preferred.

      moAcquire
        ## When applied to a load operation, no reads or writes in the
        ## current thread can be reordered before this operation.

      moRelease
        ## When applied to a store operation, no reads or writes in the
        ## current thread can be reorderd after this operation.

      moAcquireRelease
        ## When applied to a read-modify-write operation, this behaves like
        ## both an acquire and a release operation.

      moSequentiallyConsistent
        ## Behaves like Acquire when applied to load, like Release when
        ## applied to a store and like AcquireRelease when applied to a
        ## read-modify-write operation.
        ## Also guarantees that all threads observe the same total ordering
        ## with other moSequentiallyConsistent operations.

  type
    Atomic*[T] {.importcpp: "std::atomic", completeStruct.} = object
      ## An atomic object with underlying type `T`.
      raw: T

    AtomicFlag* {.importcpp: "std::atomic_flag", size: 1.} = object
      ## An atomic boolean state.

  # Access operations

  proc load*[T](location: var Atomic[T]; order: MemoryOrder = moSequentiallyConsistent): T {.importcpp: "#.load(@)".}
    ## Atomically obtains the value of the atomic object.

  proc store*[T](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.importcpp: "#.store(@)".}
    ## Atomically replaces the value of the atomic object with the `desired`
    ## value.

  proc exchange*[T](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.importcpp: "#.exchange(@)".}
    ## Atomically replaces the value of the atomic object with the `desired`
    ## value and returns the old value.

  proc compareExchange*[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.importcpp: "#.compare_exchange_strong(@)".}
    ## Atomically compares the value of the atomic object with the `expected`
    ## value and performs exchange with the `desired` one if equal or load if
    ## not. Returns true if the exchange was successful.

  proc compareExchange*[T](location: var Atomic[T]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.importcpp: "#.compare_exchange_strong(@)".}
    ## Same as above, but allows for different memory orders for success and
    ## failure.

  proc compareExchangeWeak*[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.importcpp: "#.compare_exchange_weak(@)".}
    ## Same as above, but is allowed to fail spuriously.

  proc compareExchangeWeak*[T](location: var Atomic[T]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.importcpp: "#.compare_exchange_weak(@)".}
    ## Same as above, but allows for different memory orders for success and
    ## failure.

  # Numerical operations

  proc fetchAdd*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importcpp: "#.fetch_add(@)".}
    ## Atomically adds a `value` to the atomic integer and returns the
    ## original value.

  proc fetchSub*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importcpp: "#.fetch_sub(@)".}
    ## Atomically subtracts a `value` to the atomic integer and returns the
    ## original value.

  proc fetchAnd*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importcpp: "#.fetch_and(@)".}
    ## Atomically replaces the atomic integer with it's bitwise AND
    ## with the specified `value` and returns the original value.

  proc fetchOr*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importcpp: "#.fetch_or(@)".}
    ## Atomically replaces the atomic integer with it's bitwise OR
    ## with the specified `value` and returns the original value.

  proc fetchXor*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importcpp: "#.fetch_xor(@)".}
    ## Atomically replaces the atomic integer with it's bitwise XOR
    ## with the specified `value` and returns the original value.

  # Flag operations

  proc testAndSet*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent): bool {.importcpp: "#.test_and_set(@)".}
    ## Atomically sets the atomic flag to true and returns the original value.

  proc clear*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent) {.importcpp: "#.clear(@)".}
    ## Atomically sets the value of the atomic flag to false.

  proc fence*(order: MemoryOrder) {.importcpp: "std::atomic_thread_fence(@)".}
    ## Ensures memory ordering without using atomic operations.

  proc signalFence*(order: MemoryOrder) {.importcpp: "std::atomic_signal_fence(@)".}
    ## Prevents reordering of accesses by the compiler as would fence, but
    ## inserts no CPU instructions for memory ordering.

  {.pop.}

else:
  # For the C backend, atomics map to C11 built-ins on GCC and Clang for
  # lock-free types. Other types are implemented using spin locks.

  # Since MSVC does not implement C11, we fall back to MS intrinsics
  # where available.

  type
    # 128-bit integer type for 16-byte atomics
    Int128 {.importc: "__int128", nodecl.} = object
      lo, hi: int64

  template nonAtomicType*(T: typedesc): untyped =
    ## Maps types to integers of the same size for atomic storage.
    when sizeof(T) == 1: int8
    elif sizeof(T) == 2: int16
    elif sizeof(T) == 4: int32
    elif sizeof(T) == 8: int64
    elif sizeof(T) == 16: Int128
    else:
      {.error: "nonAtomicType only supports types of size 1, 2, 4, 8, or 16 bytes".}

  when defined(vcc):

    # TODO: Lock-free types should be volatile and use VC's special volatile
    # semantics for store and loads.

    type
      MemoryOrder* = enum
        moRelaxed
        moConsume
        moAcquire
        moRelease
        moAcquireRelease
        moSequentiallyConsistent

      AtomicFlag* = distinct int8

      Atomic*[T] = object
        when T.isLockFree:
          value: T.nonAtomicType
        else:
          nonAtomicValue: T
          guard: AtomicFlag

    {.push header: "<intrin.h>".}

    # MSVC intrinsics
    proc interlockedExchange(location: pointer; desired: int8): int8 {.importc: "_InterlockedExchange8".}
    proc interlockedExchange(location: pointer; desired: int16): int16 {.importc: "_InterlockedExchange16".}
    proc interlockedExchange(location: pointer; desired: int32): int32 {.importc: "_InterlockedExchange".}
    proc interlockedExchange(location: pointer; desired: int64): int64 {.importc: "_InterlockedExchange64".}

    proc interlockedCompareExchange(location: pointer; desired, expected: int8): int8 {.importc: "_InterlockedCompareExchange8".}
    proc interlockedCompareExchange(location: pointer; desired, expected: int16): int16 {.importc: "_InterlockedCompareExchange16".}
    proc interlockedCompareExchange(location: pointer; desired, expected: int32): int32 {.importc: "_InterlockedCompareExchange".}
    proc interlockedCompareExchange(location: pointer; desired, expected: int64): int64 {.importc: "_InterlockedCompareExchange64".}

    # 128-bit compare-exchange for 16-byte atomics (amd64/arm64)
    # Returns 1 if exchange succeeded, 0 otherwise
    # Destination is the 128-bit value to modify
    # ExchangeHigh:ExchangeLow is the new value
    # ComparandResult points to the expected value (updated on failure)
    proc interlockedCompareExchange128(destination: pointer; exchangeHigh, exchangeLow: int64;
                                        comparandResult: pointer): uint8 {.importc: "_InterlockedCompareExchange128".}

    proc interlockedAnd(location: pointer; value: int8): int8 {.importc: "_InterlockedAnd8".}
    proc interlockedAnd(location: pointer; value: int16): int16 {.importc: "_InterlockedAnd16".}
    proc interlockedAnd(location: pointer; value: int32): int32 {.importc: "_InterlockedAnd".}
    proc interlockedAnd(location: pointer; value: int64): int64 {.importc: "_InterlockedAnd64".}

    proc interlockedOr(location: pointer; value: int8): int8 {.importc: "_InterlockedOr8".}
    proc interlockedOr(location: pointer; value: int16): int16 {.importc: "_InterlockedOr16".}
    proc interlockedOr(location: pointer; value: int32): int32 {.importc: "_InterlockedOr".}
    proc interlockedOr(location: pointer; value: int64): int64 {.importc: "_InterlockedOr64".}

    proc interlockedXor(location: pointer; value: int8): int8 {.importc: "_InterlockedXor8".}
    proc interlockedXor(location: pointer; value: int16): int16 {.importc: "_InterlockedXor16".}
    proc interlockedXor(location: pointer; value: int32): int32 {.importc: "_InterlockedXor".}
    proc interlockedXor(location: pointer; value: int64): int64 {.importc: "_InterlockedXor64".}

    proc fence(order: MemoryOrder): int64 {.importc: "_ReadWriteBarrier()".}
    proc signalFence(order: MemoryOrder): int64 {.importc: "_ReadWriteBarrier()".}

    {.pop.}

    proc testAndSet*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent): bool =
      interlockedOr(addr(location), 1'i8) == 1'i8
    proc clear*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent) =
      discard interlockedAnd(addr(location), 0'i8)

    template withLockVcc[T](location: var Atomic[T]; order: MemoryOrder; body: untyped): untyped =
      while interlockedOr(addr(location.guard), 1'i8) == 1'i8: discard
      try:
        body
      finally:
        discard interlockedAnd(addr(location.guard), 0'i8)

    proc load*[T](location: var Atomic[T]; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      enforceLockFreeCheck(T)
      when T.isLockFree:
        cast[T](interlockedOr(addr(location.value), (nonAtomicType(T))0))
      else:
        withLockVcc(location, order):
          result = location.nonAtomicValue

    proc store*[T](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
      enforceLockFreeCheck(T)
      when T.isLockFree:
        discard interlockedExchange(addr(location.value), cast[nonAtomicType(T)](desired))
      else:
        withLockVcc(location, order):
          location.nonAtomicValue = desired

    proc exchange*[T](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      enforceLockFreeCheck(T)
      when T.isLockFree:
        cast[T](interlockedExchange(addr(location.value), cast[int64](desired)))
      else:
        withLockVcc(location, order):
          result = location.nonAtomicValue
          location.nonAtomicValue = desired

    proc compareExchange*[T](location: var Atomic[T]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
      enforceLockFreeCheck(T)
      when T.isLockFree:
        cast[T](interlockedCompareExchange(addr(location.value), cast[nonAtomicType(T)](desired), cast[nonAtomicType(T)](expected))) == expected
      else:
        withLockVcc(location, success):
          if location.nonAtomicValue != expected:
            expected = location.nonAtomicValue
            return false
          expected = desired
          swap(location.nonAtomicValue, expected)
          return true

    proc compareExchange*[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      compareExchange(location, expected, desired, order, order)

    proc compareExchangeWeak*[T](location: var Atomic[T]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
      compareExchange(location, expected, desired, success, failure)

    proc compareExchangeWeak*[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      compareExchangeWeak(location, expected, desired, order, order)

    proc fetchAdd*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      var currentValue = location.load()
      while not compareExchangeWeak(location, currentValue, currentValue + value): discard
    proc fetchSub*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      fetchAdd(location, -value, order)
    proc fetchAnd*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedAnd(addr(location.value), cast[nonAtomicType(T)](value)))
    proc fetchOr*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedOr(addr(location.value), cast[nonAtomicType(T)](value)))
    proc fetchXor*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedXor(addr(location.value), cast[nonAtomicType(T)](value)))

  else:
    # On Linux with GCC/Clang, 16-byte atomic operations (__atomic_load_16,
    # __atomic_store_16, etc.) may not be inlined and require libatomic.
    # See: https://github.com/STEllAR-GROUP/hpx/issues/3342
    when defined(linux) and hasLockFree16:
      {.passL: "-latomic".}

    when defined(cpp):
      {.push, header: "<atomic>".}
      template maybeWrapStd(x: string): string =
        "std::" & x
    else:
      {.push, header: "<stdatomic.h>".}
      template maybeWrapStd(x: string): string =
        x

    type
      MemoryOrder* {.importc: "memory_order".maybeWrapStd.} = enum
        moRelaxed
        moConsume
        moAcquire
        moRelease
        moAcquireRelease
        moSequentiallyConsistent

    when defined(cpp):
      type
        # Atomic*[T] {.importcpp: "_Atomic('0)".} = object

        AtomicInt8 {.importc: "std::atomic<NI8>".} = int8
        AtomicInt16 {.importc: "std::atomic<NI16>".} = int16
        AtomicInt32 {.importc: "std::atomic<NI32>".} = int32
        AtomicInt64 {.importc: "std::atomic<NI64>".} = int64
        AtomicInt128 {.importc: "std::atomic<__int128>".} = Int128
    else:
      type
        # Atomic*[T] {.importcpp: "_Atomic('0)".} = object

        AtomicInt8 {.importc: "_Atomic NI8".} = int8
        AtomicInt16 {.importc: "_Atomic NI16".} = int16
        AtomicInt32 {.importc: "_Atomic NI32".} = int32
        AtomicInt64 {.importc: "_Atomic NI64".} = int64
        AtomicInt128 {.importc: "_Atomic __int128".} = Int128

    type
      AtomicFlag* {.importc: "atomic_flag".maybeWrapStd, size: 1.} = object

      Atomic*[T] = object
        when T.isLockFree:
          # Maps the size of a lock-free type to its internal atomic type
          when sizeof(T) == 1: value: AtomicInt8
          elif sizeof(T) == 2: value: AtomicInt16
          elif sizeof(T) == 4: value: AtomicInt32
          elif sizeof(T) == 8: value: AtomicInt64
          elif sizeof(T) == 16: value: AtomicInt128
        else:
          nonAtomicValue: T
          guard: AtomicFlag

    #proc init*[T](location: var Atomic[T]; value: T): T {.importcpp: "atomic_init(@)".}
    proc atomic_load_explicit[T, A](location: ptr A; order: MemoryOrder): T {.importc: "atomic_load_explicit".maybeWrapStd.}
    proc atomic_store_explicit[T, A](location: ptr A; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.importc: "atomic_store_explicit".maybeWrapStd.}
    proc atomic_exchange_explicit[T, A](location: ptr A; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc: "atomic_exchange_explicit".maybeWrapStd.}
    proc atomic_compare_exchange_strong_explicit[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc: "atomic_compare_exchange_strong_explicit".maybeWrapStd.}
    proc atomic_compare_exchange_weak_explicit[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc: "atomic_compare_exchange_weak_explicit".maybeWrapStd.}

    # Numerical operations
    proc atomic_fetch_add_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc: "atomic_fetch_add_explicit".maybeWrapStd.}
    proc atomic_fetch_sub_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc: "atomic_fetch_sub_explicit".maybeWrapStd.}
    proc atomic_fetch_and_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc: "atomic_fetch_and_explicit".maybeWrapStd.}
    proc atomic_fetch_or_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc: "atomic_fetch_or_explicit".maybeWrapStd.}
    proc atomic_fetch_xor_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc: "atomic_fetch_xor_explicit".maybeWrapStd.}

    # Flag operations
    # var ATOMIC_FLAG_INIT {.importc, nodecl.}: AtomicFlag
    # proc init*(location: var AtomicFlag) {.inline.} = location = ATOMIC_FLAG_INIT
    proc testAndSet*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent): bool {.importc: "atomic_flag_test_and_set_explicit".maybeWrapStd.}
    proc clear*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent) {.importc: "atomic_flag_clear_explicit".maybeWrapStd.}

    proc fence*(order: MemoryOrder) {.importc: "atomic_thread_fence".maybeWrapStd.}
    proc signalFence*(order: MemoryOrder) {.importc: "atomic_signal_fence".maybeWrapStd.}

    {.pop.}

    template withLock[T](location: var Atomic[T]; order: MemoryOrder; body: untyped): untyped =
      ## Helper template to execute `body` with the spinlock acquired.
      while testAndSet(location.guard, moAcquire): discard
      try:
        body
      finally:
        clear(location.guard, moRelease)

    proc load*[T](location: var Atomic[T]; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      enforceLockFreeCheck(T)
      when T.isLockFree:
        cast[T](atomic_load_explicit[nonAtomicType(T), typeof(location.value)](addr(location.value), order))
      else:
        withLock(location, order):
          result = location.nonAtomicValue

    proc store*[T](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
      enforceLockFreeCheck(T)
      when T.isLockFree:
        atomic_store_explicit(addr(location.value), cast[nonAtomicType(T)](desired), order)
      else:
        withLock(location, order):
          location.nonAtomicValue = desired

    proc exchange*[T](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      enforceLockFreeCheck(T)
      when T.isLockFree:
        cast[T](atomic_exchange_explicit(addr(location.value), cast[nonAtomicType(T)](desired), order))
      else:
        withLock(location, order):
          result = location.nonAtomicValue
          location.nonAtomicValue = desired

    proc compareExchange*[T](location: var Atomic[T]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
      enforceLockFreeCheck(T)
      when T.isLockFree:
        atomic_compare_exchange_strong_explicit(addr(location.value), cast[ptr nonAtomicType(T)](addr(expected)), cast[nonAtomicType(T)](desired), success, failure)
      else:
        withLock(location, success):
          if location.nonAtomicValue != expected:
            expected = location.nonAtomicValue
            return false
          expected = desired
          swap(location.nonAtomicValue, expected)
          return true

    proc compareExchange*[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      compareExchange(location, expected, desired, order, order)

    proc compareExchangeWeak*[T](location: var Atomic[T]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
      enforceLockFreeCheck(T)
      when T.isLockFree:
        atomic_compare_exchange_weak_explicit(addr(location.value), cast[ptr nonAtomicType(T)](addr(expected)), cast[nonAtomicType(T)](desired), success, failure)
      else:
        compareExchange(location, expected, desired, success, failure)

    proc compareExchangeWeak*[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      compareExchangeWeak(location, expected, desired, order, order)

    # Numerical operations
    proc fetchAdd*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_add_explicit(addr(location.value), cast[nonAtomicType(T)](value), order))
    proc fetchSub*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_sub_explicit(addr(location.value), cast[nonAtomicType(T)](value), order))
    proc fetchAnd*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_and_explicit(addr(location.value), cast[nonAtomicType(T)](value), order))
    proc fetchOr*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_or_explicit(addr(location.value), cast[nonAtomicType(T)](value), order))
    proc fetchXor*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_xor_explicit(addr(location.value), cast[nonAtomicType(T)](value), order))

proc atomicInc*[T: SomeInteger](location: var Atomic[T]; value: T = 1) {.inline.} =
  ## Atomically increments the atomic integer by some `value`.
  discard location.fetchAdd(value)

proc atomicDec*[T: SomeInteger](location: var Atomic[T]; value: T = 1) {.inline.} =
  ## Atomically decrements the atomic integer by some `value`.
  discard location.fetchSub(value)

proc `+=`*[T: SomeInteger](location: var Atomic[T]; value: T) {.inline.} =
  ## Atomically increments the atomic integer by some `value`.
  discard location.fetchAdd(value)

proc `-=`*[T: SomeInteger](location: var Atomic[T]; value: T) {.inline.} =
  ## Atomically decrements the atomic integer by some `value`.
  discard location.fetchSub(value)
