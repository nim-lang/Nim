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
## By default, C++ uses C11 atomic primitives. To use C++ `std::atomic`,
## `-d:nimUseCppAtomics` can be defined.
##
## The memory order of an atomic operation is a `MemoryOrder`, which is
## `static[MemoryOrderKind]`, so it has to be a constant expression: the C and
## C++ compilers pick the order when they expand the atomic operation and an
## order that is not constant there silently degrades to `seq_cst` (GCC) or to a
## switch over the order (Clang). A wrapper around an atomic operation should
## declare its own parameter as `MemoryOrder` too, then the constant is
## forwarded through it:
##
##   ```nim
##   proc load(futex: var Futex; order: MemoryOrder): uint32 {.inline.} =
##     futex.value.load(order)
##   ```
##
## `MemoryOrderKind` is the enum itself. Use it where a concrete type is
## required, for a variable, an object field or a `seq` of orders, and write the
## `case` over the order yourself if it really has to be computed at run time.

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

  {.push, header: "<atomic>".}

  type
    MemoryOrderKind* {.importcpp: "std::memory_order".} = enum
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

    MemoryOrder* = static[MemoryOrderKind]
      ## The memory order of an atomic operation, always a constant expression.
      ## `MemoryOrderKind` is the enum itself, for the places that need a
      ## concrete type.

    FailureOrder* = static[MemoryOrderKind]
      ## The memory order for the failure case of a compare-exchange. A type
      ## class may only be used once per signature, so the two orders need two
      ## names.

  type
    Atomic*[T] {.importcpp: "std::atomic", completeStruct.} = object
      ## An atomic object with underlying type `T`.
      raw: T

    AtomicFlag* {.importcpp: "std::atomic_flag", size: 1.} = object
      ## An atomic boolean state.

  proc cppLoad[T](location: var Atomic[T]; order: MemoryOrderKind): T {.importcpp: "#.load(@)".}
  proc cppStore[T](location: var Atomic[T]; desired: T; order: MemoryOrderKind) {.importcpp: "#.store(@)".}
  proc cppExchange[T](location: var Atomic[T]; desired: T; order: MemoryOrderKind): T {.importcpp: "#.exchange(@)".}
  proc cppCompareExchange[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrderKind): bool {.importcpp: "#.compare_exchange_strong(@)".}
  proc cppCompareExchange[T](location: var Atomic[T]; expected: var T; desired: T; success, failure: MemoryOrderKind): bool {.importcpp: "#.compare_exchange_strong(@)".}
  proc cppCompareExchangeWeak[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrderKind): bool {.importcpp: "#.compare_exchange_weak(@)".}
  proc cppCompareExchangeWeak[T](location: var Atomic[T]; expected: var T; desired: T; success, failure: MemoryOrderKind): bool {.importcpp: "#.compare_exchange_weak(@)".}
  proc cppFetchAdd[T](location: var Atomic[T]; value: T; order: MemoryOrderKind): T {.importcpp: "#.fetch_add(@)".}
  proc cppFetchSub[T](location: var Atomic[T]; value: T; order: MemoryOrderKind): T {.importcpp: "#.fetch_sub(@)".}
  proc cppFetchAnd[T](location: var Atomic[T]; value: T; order: MemoryOrderKind): T {.importcpp: "#.fetch_and(@)".}
  proc cppFetchOr[T](location: var Atomic[T]; value: T; order: MemoryOrderKind): T {.importcpp: "#.fetch_or(@)".}
  proc cppFetchXor[T](location: var Atomic[T]; value: T; order: MemoryOrderKind): T {.importcpp: "#.fetch_xor(@)".}
  proc cppTestAndSet(location: var AtomicFlag; order: MemoryOrderKind): bool {.importcpp: "#.test_and_set(@)".}
  proc cppClear(location: var AtomicFlag; order: MemoryOrderKind) {.importcpp: "#.clear(@)".}
  proc cppFence(order: MemoryOrderKind) {.importcpp: "std::atomic_thread_fence(@)".}
  proc cppSignalFence(order: MemoryOrderKind) {.importcpp: "std::atomic_signal_fence(@)".}

  {.pop.}

  # The memory order is a constant expression everywhere: C++ compilers pick it
  # when they expand the atomic operation and an order that is not a constant
  # expression there degrades to `seq_cst` or to a switch over the order.

  # Access operations

  proc load*[T](location: var Atomic[T]; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    ## Atomically obtains the value of the atomic object.
    cppLoad(location, order)

  proc store*[T](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
    ## Atomically replaces the value of the atomic object with the `desired`
    ## value.
    cppStore(location, desired, order)

  proc exchange*[T](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    ## Atomically replaces the value of the atomic object with the `desired`
    ## value and returns the old value.
    cppExchange(location, desired, order)

  proc compareExchange*[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
    ## Atomically compares the value of the atomic object with the `expected`
    ## value and performs exchange with the `desired` one if equal or load if
    ## not. Returns true if the exchange was successful.
    cppCompareExchange(location, expected, desired, order)

  proc compareExchange*[T](location: var Atomic[T]; expected: var T; desired: T; success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
    ## Same as above, but allows for different memory orders for success and
    ## failure.
    cppCompareExchange(location, expected, desired, success, failure)

  proc compareExchangeWeak*[T](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
    ## Same as above, but is allowed to fail spuriously.
    cppCompareExchangeWeak(location, expected, desired, order)

  proc compareExchangeWeak*[T](location: var Atomic[T]; expected: var T; desired: T; success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
    ## Same as above, but allows for different memory orders for success and
    ## failure.
    cppCompareExchangeWeak(location, expected, desired, success, failure)

  # Numerical operations

  proc fetchAdd*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    ## Atomically adds a `value` to the atomic integer and returns the
    ## original value.
    cppFetchAdd(location, value, order)

  proc fetchSub*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    ## Atomically subtracts a `value` to the atomic integer and returns the
    ## original value.
    cppFetchSub(location, value, order)

  proc fetchAnd*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    ## Atomically replaces the atomic integer with it's bitwise AND
    ## with the specified `value` and returns the original value.
    cppFetchAnd(location, value, order)

  proc fetchOr*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    ## Atomically replaces the atomic integer with it's bitwise OR
    ## with the specified `value` and returns the original value.
    cppFetchOr(location, value, order)

  proc fetchXor*[T: SomeInteger](location: var Atomic[T]; value: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    ## Atomically replaces the atomic integer with it's bitwise XOR
    ## with the specified `value` and returns the original value.
    cppFetchXor(location, value, order)

  # Flag operations

  proc testAndSet*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
    ## Atomically sets the atomic flag to true and returns the original value.
    cppTestAndSet(location, order)

  proc clear*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
    ## Atomically sets the value of the atomic flag to false.
    cppClear(location, order)

  proc fence*(order: MemoryOrder) {.inline.} =
    ## Ensures memory ordering without using atomic operations.
    cppFence(order)

  proc signalFence*(order: MemoryOrder) {.inline.} =
    ## Prevents reordering of accesses by the compiler as would fence, but
    ## inserts no CPU instructions for memory ordering.
    cppSignalFence(order)


else:
  # For the C backend, atomics map to C11 built-ins on GCC and Clang for
  # trivial Nim types. Other types are implemented using spin locks.
  # This could be overcome by supporting advanced importc-patterns.

  # Since MSVC does not implement C11, we fall back to MS intrinsics
  # where available.

  type
    Trivial = SomeNumber | bool | enum | ptr | pointer
      # A type that is known to be atomic and whose size is known at
      # compile time to be 8 bytes or less

  template nonAtomicType*(T: typedesc[Trivial]): untyped =
    # Maps types to integers of the same size
    when sizeof(T) == 1: int8
    elif sizeof(T) == 2: int16
    elif sizeof(T) == 4: int32
    elif sizeof(T) == 8: int64

  when defined(vcc):

    # TODO: Trivial types should be volatile and use VC's special volatile
    # semantics for store and loads.

    type
      MemoryOrderKind* = enum
        moRelaxed
        moConsume
        moAcquire
        moRelease
        moAcquireRelease
        moSequentiallyConsistent

      MemoryOrder* = static[MemoryOrderKind]
        ## The memory order of an atomic operation, always a constant expression.
        ## `MemoryOrderKind` is the enum itself, for the places that need a
        ## concrete type.

      FailureOrder* = static[MemoryOrderKind]
        ## The memory order for the failure case of a compare-exchange. A type
        ## class may only be used once per signature, so the two orders need two
        ## names.

      Atomic*[T] = object
        when T is Trivial:
          value: T.nonAtomicType
        else:
          nonAtomicValue: T
          guard: AtomicFlag

      AtomicFlag* = distinct int8

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

    proc fence(order: MemoryOrderKind): int64 {.importc: "_ReadWriteBarrier()".}
    proc signalFence(order: MemoryOrderKind): int64 {.importc: "_ReadWriteBarrier()".}

    {.pop.}

    proc testAndSet*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent): bool =
      interlockedOr(addr(location), 1'i8) == 1'i8
    proc clear*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent) =
      discard interlockedAnd(addr(location), 0'i8)

    proc load*[T: Trivial](location: var Atomic[T]; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedOr(addr(location.value), (nonAtomicType(T))0))
    proc store*[T: Trivial](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
      discard interlockedExchange(addr(location.value), cast[nonAtomicType(T)](desired))

    proc exchange*[T: Trivial](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](interlockedExchange(addr(location.value), cast[int64](desired)))
    proc compareExchange*[T: Trivial](location: var Atomic[T]; expected: var T; desired: T; success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
      cast[T](interlockedCompareExchange(addr(location.value), cast[nonAtomicType(T)](desired), cast[nonAtomicType(T)](expected))) == expected
    proc compareExchangeWeak*[T: Trivial](location: var Atomic[T]; expected: var T; desired: T; success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
      compareExchange(location, expected, desired, success, failure)

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
    when defined(cpp):
      {.push, header: "<atomic>".}
      template maybeWrapStd(x: string): string =
        "std::" & x
    else:
      {.push, header: "<stdatomic.h>".}
      template maybeWrapStd(x: string): string =
        x

    type
      MemoryOrderKind* {.importc: "memory_order".maybeWrapStd.} = enum
        moRelaxed
        moConsume
        moAcquire
        moRelease
        moAcquireRelease
        moSequentiallyConsistent

      MemoryOrder* = static[MemoryOrderKind]
        ## The memory order of an atomic operation, always a constant expression.
        ## `MemoryOrderKind` is the enum itself, for the places that need a
        ## concrete type.

      FailureOrder* = static[MemoryOrderKind]
        ## The memory order for the failure case of a compare-exchange. A type
        ## class may only be used once per signature, so the two orders need two
        ## names.

    when defined(cpp):
      type
        # Atomic*[T] {.importcpp: "_Atomic('0)".} = object

        AtomicInt8 {.importc: "std::atomic<NI8>".} = int8
        AtomicInt16 {.importc: "std::atomic<NI16>".} = int16
        AtomicInt32 {.importc: "std::atomic<NI32>".} = int32
        AtomicInt64 {.importc: "std::atomic<NI64>".} = int64
    else:
      type
        # Atomic*[T] {.importcpp: "_Atomic('0)".} = object

        AtomicInt8 {.importc: "_Atomic NI8".} = int8
        AtomicInt16 {.importc: "_Atomic NI16".} = int16
        AtomicInt32 {.importc: "_Atomic NI32".} = int32
        AtomicInt64 {.importc: "_Atomic NI64".} = int64

    type
      AtomicFlag* {.importc: "atomic_flag".maybeWrapStd, size: 1.} = object

      Atomic*[T] = object
        when T is Trivial:
          # Maps the size of a trivial type to it's internal atomic type
          when sizeof(T) == 1: value: AtomicInt8
          elif sizeof(T) == 2: value: AtomicInt16
          elif sizeof(T) == 4: value: AtomicInt32
          elif sizeof(T) == 8: value: AtomicInt64
        else:
          nonAtomicValue: T
          guard: AtomicFlag

    #proc init*[T](location: var Atomic[T]; value: T): T {.importcpp: "atomic_init(@)".}
    proc atomic_load_explicit[T, A](location: ptr A; order: MemoryOrderKind): T {.importc: "atomic_load_explicit".maybeWrapStd.}
    proc atomic_store_explicit[T, A](location: ptr A; desired: T; order: MemoryOrderKind = moSequentiallyConsistent) {.importc: "atomic_store_explicit".maybeWrapStd.}
    proc atomic_exchange_explicit[T, A](location: ptr A; desired: T; order: MemoryOrderKind = moSequentiallyConsistent): T {.importc: "atomic_exchange_explicit".maybeWrapStd.}
    proc atomic_compare_exchange_strong_explicit[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrderKind): bool {.importc: "atomic_compare_exchange_strong_explicit".maybeWrapStd.}
    proc atomic_compare_exchange_weak_explicit[T, A](location: ptr A; expected: ptr T; desired: T; success, failure: MemoryOrderKind): bool {.importc: "atomic_compare_exchange_weak_explicit".maybeWrapStd.}

    # Numerical operations
    proc atomic_fetch_add_explicit[T, A](location: ptr A; value: T; order: MemoryOrderKind = moSequentiallyConsistent): T {.importc: "atomic_fetch_add_explicit".maybeWrapStd.}
    proc atomic_fetch_sub_explicit[T, A](location: ptr A; value: T; order: MemoryOrderKind = moSequentiallyConsistent): T {.importc: "atomic_fetch_sub_explicit".maybeWrapStd.}
    proc atomic_fetch_and_explicit[T, A](location: ptr A; value: T; order: MemoryOrderKind = moSequentiallyConsistent): T {.importc: "atomic_fetch_and_explicit".maybeWrapStd.}
    proc atomic_fetch_or_explicit[T, A](location: ptr A; value: T; order: MemoryOrderKind = moSequentiallyConsistent): T {.importc: "atomic_fetch_or_explicit".maybeWrapStd.}
    proc atomic_fetch_xor_explicit[T, A](location: ptr A; value: T; order: MemoryOrderKind = moSequentiallyConsistent): T {.importc: "atomic_fetch_xor_explicit".maybeWrapStd.}

    # Flag operations
    # var ATOMIC_FLAG_INIT {.importc, nodecl.}: AtomicFlag
    # proc init*(location: var AtomicFlag) {.inline.} = location = ATOMIC_FLAG_INIT
    proc atomic_flag_test_and_set_explicit(location: var AtomicFlag; order: MemoryOrderKind): bool {.importc: "atomic_flag_test_and_set_explicit".maybeWrapStd.}
    proc atomic_flag_clear_explicit(location: var AtomicFlag; order: MemoryOrderKind) {.importc: "atomic_flag_clear_explicit".maybeWrapStd.}

    proc atomic_thread_fence(order: MemoryOrderKind) {.importc: "atomic_thread_fence".maybeWrapStd.}
    proc atomic_signal_fence(order: MemoryOrderKind) {.importc: "atomic_signal_fence".maybeWrapStd.}

    {.pop.}

    # The memory order is a constant expression everywhere: C compilers pick it
    # when they expand the atomic builtin and an order that is not a constant
    # expression there degrades to `seq_cst` (GCC) or to a switch over the
    # order (Clang).

    proc testAndSet*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
      atomic_flag_test_and_set_explicit(location, order)
    proc clear*(location: var AtomicFlag; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
      atomic_flag_clear_explicit(location, order)

    proc fence*(order: MemoryOrder) {.inline.} =
      atomic_thread_fence(order)
    proc signalFence*(order: MemoryOrder) {.inline.} =
      atomic_signal_fence(order)

    proc load*[T: Trivial](location: var Atomic[T]; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_load_explicit[nonAtomicType(T), typeof(location.value)](addr(location.value), order))
    proc store*[T: Trivial](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
      atomic_store_explicit(addr(location.value), cast[nonAtomicType(T)](desired), order)
    proc exchange*[T: Trivial](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
      cast[T](atomic_exchange_explicit(addr(location.value), cast[nonAtomicType(T)](desired), order))
    proc compareExchange*[T: Trivial](location: var Atomic[T]; expected: var T; desired: T; success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
      atomic_compare_exchange_strong_explicit(addr(location.value), cast[ptr nonAtomicType(T)](addr(expected)), cast[nonAtomicType(T)](desired), success, failure)

    proc compareExchangeWeak*[T: Trivial](location: var Atomic[T]; expected: var T; desired: T; success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
      atomic_compare_exchange_weak_explicit(addr(location.value), cast[ptr nonAtomicType(T)](addr(expected)), cast[nonAtomicType(T)](desired), success, failure)

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

  func compareExchangeFailureOrder(order: MemoryOrderKind): MemoryOrderKind {.inline.} =
    case order
    of moRelease:
      moRelaxed
    of moAcquireRelease:
      moAcquire
    else:
      order

  proc compareExchange*[T: Trivial](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
    compareExchange(location, expected, desired, order, static(compareExchangeFailureOrder(order)))

  proc compareExchangeWeak*[T: Trivial](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
    compareExchangeWeak(location, expected, desired, order, static(compareExchangeFailureOrder(order)))

  template withLock[T: not Trivial](location: var Atomic[T]; order: MemoryOrderKind; body: untyped): untyped =
    while testAndSet(location.guard, moAcquire): discard
    try:
      body
    finally:
      clear(location.guard, moRelease)

  proc load*[T: not Trivial](location: var Atomic[T]; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    withLock(location, order):
      result = location.nonAtomicValue

  proc store*[T: not Trivial](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent) {.inline.} =
    withLock(location, order):
      location.nonAtomicValue = desired

  proc exchange*[T: not Trivial](location: var Atomic[T]; desired: T; order: MemoryOrder = moSequentiallyConsistent): T {.inline.} =
    withLock(location, order):
      result = location.nonAtomicValue
      location.nonAtomicValue = desired

  proc compareExchange*[T: not Trivial](location: var Atomic[T]; expected: var T; desired: T; success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
    withLock(location, success):
      if location.nonAtomicValue != expected:
        expected = location.nonAtomicValue
        return false
      expected = desired
      swap(location.nonAtomicValue, expected)
      return true

  proc compareExchangeWeak*[T: not Trivial](location: var Atomic[T]; expected: var T; desired: T; success: MemoryOrder; failure: FailureOrder): bool {.inline.} =
    compareExchange(location, expected, desired, success, failure)

  proc compareExchange*[T: not Trivial](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
    compareExchange(location, expected, desired, order, static(compareExchangeFailureOrder(order)))

  proc compareExchangeWeak*[T: not Trivial](location: var Atomic[T]; expected: var T; desired: T; order: MemoryOrder = moSequentiallyConsistent): bool {.inline.} =
    compareExchangeWeak(location, expected, desired, order, static(compareExchangeFailureOrder(order)))

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
