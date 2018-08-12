#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Jörg Wollenschläger
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Types and operations for atomic operations and lockless algorithms.

import macros

when defined(cpp) or defined(nimdoc):
  # For the C++ backend, types and operations map directly to C++11 atomics.

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
        ## Also garantees that all threads observe the same total ordering
        ## with other moSequentiallyConsistent operations.

  type
    Atomic* {.importcpp: "std::atomic".} [T] = object
      ## An atomic object with underlying type `T`.
      ## In the C backend this is a concept rather than a gernic type.

    AtomicFlag* {.importcpp: "std::atomic_flag".} = object
      ## An atomic boolean state.

  template atomic*(T: typedesc): typedesc =
    ## Create an atomic version of type `T`, which provides atomic operations
    ## and memory ordering guarantees.
    Atomic[T]     

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
  # trivial Nim types. Other types are implemented using spin locks.
  # This could be overcome by supporting advanced importc-patterns.

  # Since MSVC does not implement C11, we fall back to MS intrinsics
  # where available.

  type 
    Trivial = SomeNumber | bool | ptr | pointer
      # A type that is known to be atomic and whose size is known at
      # compile time to be 8 bytes or less

  when defined(vcc):
    
    # TODO: Trivial types should be volatile and use VC's special volatile
    # semantics for store and loads.

    type
      MemoryOrder* = enum
        moRelaxed
        moConsume
        moAcquire
        moRelease
        moAcquireRelease
        moSequentiallyConsistent

      AtomicObject[T] = object
        # A non-trivial atomic type, implemented using locking
        value: T
        guard: AtomicFlag

      AtomicFlag* = distinct int8

      Atomic*[T] = concept type A
        A.atomicUnderlyingType is T
        
    template atomicUnderlyingType*[T, S](_: Trivial): typedesc = T
    template atomicUnderlyingType*[T](_: typedesc[AtomicObject[T]]): typedesc = T

    template nonAtomicType(T: typedesc): typedesc =
      # Maps types to integers of the same size
      when sizeof(T) == 1: int8
      elif sizeof(T) == 2: int16
      elif sizeof(T) == 4: int32
      elif sizeof(T) == 8: int64

    template atomic*(T: typedesc): typedesc =
      when T is Trivial: T
      else: AtomicObject[T]

    {.push header: "<intrin.h>".}

    # MSVC intrinsics
    proc interlockedExchange(location: pointer; desired: int8): int8 {.importc: "_InterlockedExchange8".}
    proc interlockedExchange(location: pointer; desired: int16): int16 {.importc: "_InterlockedExchange".}
    proc interlockedExchange(location: pointer; desired: int32): int32 {.importc: "_InterlockedExchange16".}
    proc interlockedExchange(location: pointer; desired: int64): int64 {.importc: "_InterlockedExchange64".}

    proc interlockedCompareExchange(location: pointer; desired, expected: int8): int8 {.importc: "_InterlockedCompareExchange8".}
    proc interlockedCompareExchange(location: pointer; desired, expected: int16): int16 {.importc: "_InterlockedCompareExchange16".}
    proc interlockedCompareExchange(location: pointer; desired, expected: int32): int32 {.importc: "_InterlockedCompareExchange".}
    proc interlockedCompareExchange(location: pointer; desired, expected: int64): int64 {.importc: "_InterlockedCompareExchange64".}

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

    proc load*[T: Trivial](location: var T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedOr(addr(location), (nonAtomicType(T))0))
    proc store*[T: Trivial](location: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
      discard interlockedExchange(addr(location), cast[nonAtomicType(T)](desired))

    proc exchange*[T: Trivial](location: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedExchange(addr(location), cast[int64](desired)))
    proc compareExchange*[T: Trivial](location: var T; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
      cast[T](interlockedCompareExchange(addr(location), cast[nonAtomicType(T)](desired), cast[nonAtomicType(T)](expected))) == expected
    proc compareExchange*[T: Trivial](location: var T; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      compareExchange(location, expected, desired, order, order)
    proc compareExchangeWeak*[T: Trivial](location: var T; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
      compareExchange(location, expected, desired, success, failure)
    proc compareExchangeWeak*[T: Trivial](location: var T; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      compareExchangeWeak(location, expected, desired, order, order)

    proc fetchAdd*[T: SomeInteger](location: var T; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      let currentValue = location.load()
      while not compareExchangeWeak(location, currentValue, currentValue + value): discard
    proc fetchSub*[T: SomeInteger](location: var T; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      fetchAdd(location, -value, order)
    proc fetchAnd*[T: SomeInteger](location: var T; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedAnd(addr(location), cast[nonAtomicType(T)](value)))
    proc fetchOr*[T: SomeInteger](location: var T; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedOr(addr(location), cast[nonAtomicType(T)](value)))
    proc fetchXor*[T: SomeInteger](location: var T; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedXor(addr(location), cast[nonAtomicType(T)](value)))
    
  else:
    {.push, header: "<stdatomic.h>".}

    type
      MemoryOrder* {.importc: "memory_order".} = enum
        moRelaxed
        moConsume
        moAcquire
        moRelease
        moAcquireRelease
        moSequentiallyConsistent

    type
      # Atomic* {.importcpp: "_Atomic('0)".} [T] = object

      AtomicInt8 {.importc: "_Atomic NI8".} = object
      AtomicInt16 {.importc: "_Atomic NI16".} = object
      AtomicInt32 {.importc: "_Atomic NI32".} = object
      AtomicInt64 {.importc: "_Atomic NI64".} = object

      AtomicObject[T] = object
        value: T
        guard: AtomicFlag

      AtomicFlag* {.importc: "atomic_flag".} = object

      AtomicTrivial[T: Trivial; S] = object
        value: S

      Atomic*[T] = concept type A
        A.atomicUnderlyingType is T

    template atomicType(size: int): untyped =
      # Maps the size of a trivial type to it's internal atomic type
      when size == 1: AtomicInt8
      elif size == 2: AtomicInt16
      elif size == 4: AtomicInt32
      elif size == 8: AtomicInt64

    template atomicUnderlyingType*[T, S](_: typedesc[AtomicTrivial[T, S]]): typedesc = T
    template atomicUnderlyingType*[T](_: typedesc[AtomicObject[T]]): typedesc = T

    # Map types to integers of same size
    template nonAtomicType(T: typedesc[AtomicInt8]): typedesc = int8
    template nonAtomicType(T: typedesc[AtomicInt16]): typedesc = int16
    template nonAtomicType(T: typedesc[AtomicInt32]): typedesc = int32
    template nonAtomicType(T: typedesc[AtomicInt64]): typedesc = int64

    template atomic*(T: typedesc): typedesc =
      when T is Trivial: AtomicTrivial[T, atomicType(sizeof(T))]
      else: AtomicObject[T]

    #proc init*[T](location: var Atomic[T]; value: T): T {.importcpp: "atomic_init(@)".}
    proc atomic_load_explicit[T, A](location: ptr A; order: MemoryOrder): T {.importc.}
    proc atomic_store_explicit[T, A](location: ptr A; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.importc.}
    proc atomic_exchange_explicit[T, A](location: ptr A; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
    proc atomic_compare_exchange_strong_explicit[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc.}
    proc atomic_compare_exchange_weak_explicit[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrder): bool {.importc.}
      
    # Numerical operations
    proc atomic_fetch_add_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
    proc atomic_fetch_sub_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
    proc atomic_fetch_and_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
    proc atomic_fetch_or_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
    proc atomic_fetch_xor_explicit[T, A](location: ptr A; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.importc.}
  
    # Flag operations
    # var ATOMIC_FLAG_INIT {.importc, nodecl.}: AtomicFlag
    # proc init*(location: var AtomicFlag) {.inline.} = location = ATOMIC_FLAG_INIT
    proc testAndSet*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent): bool {.importc: "atomic_flag_test_and_set_explicit".}
    proc clear*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent) {.importc: "atomic_flag_clear_explicit".}
  
    proc fence*(order: MemoryOrder) {.importc: "atomic_thread_fence".}
    proc signalFence*(order: MemoryOrder) {.importc: "atomic_signal_fence".}  

    {.pop.}

    proc load*[T, A](location: var AtomicTrivial[T, A]; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_load_explicit[nonAtomicType(A), A](addr(location.value), order))
    proc store*[T, A](location: var AtomicTrivial[T, A]; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
      atomic_store_explicit(addr(location.value), cast[nonAtomicType(A)](desired), order)
    proc exchange*[T, A](location: var AtomicTrivial[T, A]; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_exchange_explicit(addr(location.value), cast[nonAtomicType(A)](desired), order))
    proc compareExchange*[T, A](location: var AtomicTrivial[T, A]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
      atomic_compare_exchange_strong_explicit(addr(location.value), cast[ptr nonAtomicType(A)](addr(expected)), cast[nonAtomicType(A)](desired), success, failure)
    proc compareExchange*[T, A](location: var AtomicTrivial[T, A]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      compareExchange(location, expected, desired, order, order)
    proc compareExchange*[T, A](location: var AtomicObject[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      compareExchange(location, expected, desired, order, order)

    proc compareExchangeWeak*[T, A](location: var AtomicTrivial[T, A]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
      atomic_compare_exchange_weak_explicit(addr(location.value), cast[ptr nonAtomicType(A)](addr(expected)), cast[nonAtomicType(A)](desired), success, failure)
    proc compareExchangeWeak*[T, A](location: var AtomicTrivial[T, A]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      compareExchangeWeak(location, expected, desired, order, order)
  
    # Numerical operations
    proc fetchAdd*[T: SomeInteger, A](location: var AtomicTrivial[T, A]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_add_explicit(addr(location.value), cast[nonAtomicType(A)](value), order))
    proc fetchSub*[T: SomeInteger, A](location: var AtomicTrivial[T, A]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_sub_explicit(addr(location.value), cast[nonAtomicType(A)](value), order))
    proc fetchAnd*[T: SomeInteger, A](location: var AtomicTrivial[T, A]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_and_explicit(addr(location.value), cast[nonAtomicType(A)](value), order))
    proc fetchOr*[T: SomeInteger, A](location: var AtomicTrivial[T, A]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_or_explicit(addr(location.value), cast[nonAtomicType(A)](value), order))
    proc fetchXor*[T: SomeInteger, A](location: var AtomicTrivial[T, A]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_fetch_xor_explicit(addr(location.value), cast[nonAtomicType(A)](value), order))

  template withLock(location: var AtomicObject; order: MemoryOrder; body: untyped): untyped =
    while location.guard.testAndSet(moAcquire): discard
    body
    location.guard.clear(moRelease)

  proc load*[T](location: var AtomicObject[T]; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =      
    withLock(location, order):
      result = location.value

  proc store*[T](location: var AtomicObject[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =      
    withLock(location, order):
      location.value = desired

  proc exchange*[T](location: var AtomicObject[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    withLock(location, order):
      result = location.value
      location.value = desired

  proc compareExchange*[T](location: var AtomicObject[T]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
    withLock(location, success):
      if location.value != expected:
        return false
      swap(location.value, expected)
      return true

  proc compareExchangeWeak*[T](location: var AtomicObject[T]; expected: var T; desired: T; success, failure: MemoryOrder): bool {.inline.} =
    withLock(location, success):
      if location.value != expected:
        return false
      swap(location.value, expected)
      return true

  proc compareExchangeWeak*[T](location: var AtomicObject[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
    compareExchangeWeak(location, expected, desired, order, order)

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
