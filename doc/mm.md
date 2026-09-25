=======================
Nim's Memory Management
=======================

.. default-role:: code
.. include:: rstcommon.rst

:Author: Andreas Rumpf
:Version: |nimversion|

..


> "The road to hell is paved with good intentions."


Multi-paradigm Memory Management Strategies
===========================================

.. default-role:: option

Nim offers multiple different memory management strategies.
To choose the memory management strategy use the `--mm:` switch.

 .. hint:: **The recommended switch for newly written Nim code is `--mm:orc`.**


ARC/ORC
-------

ORC is the default memory management strategy. It is a memory
management mode primarily based on reference counting. Reference cycles are
handled by a cycle collection mechanism based on "trial deletion".
Since algorithms based on "tracing" are not used, the runtime behavior is oblivious to the involved heap and stack sizes.

The reference counting operations (= "RC ops") do not use atomic instructions and do not have to --
instead entire subgraphs are *moved* between threads. The Nim compiler also aggressively
optimizes away RC ops and exploits [move semantics](destructors.html#move-semantics).

Nim performs a fair share of optimizations for ARC/ORC; you can inspect what it did
to your time critical function via `--expandArc:functionName`. Likewise, you can inspect the whole module via `--expandArc:fileName`.

`--mm:arc` uses the same mechanism as `--mm:orc`, but it leaves out the cycle collector.
Both ARC and ORC offer deterministic performance for `hard realtime`:idx: systems, but
ARC can be easier to reason about for people coming from Ada/C++/C -- roughly speaking
the memory for a variable is freed when it goes "out of scope".

We generally advise you to use the `acyclic` annotation in order to optimize away the
cycle collector's overhead
but `--mm:orc` also produces more machine code than `--mm:arc`, so if you're on a target
where code size matters and you know that your code does not produce cycles, you can
use `--mm:arc`. Notice that the default `async`:idx: implementation produces cycles
and leaks memory with `--mm:arc`, in other words, for `async` you need to use `--mm:orc`
or `--mm:yrc`.


Atomic ARC/YRC
--------------

ARC/ORC are not threadsafe if `ref` or other automatically managed types are
accessed across thread boundaries.
Moving isolated subgraphs between threads is supported for ARC/ORC and the language has support
for that in the form of `isolate`. The modes `mm:atomicArc` and `mm:yrc` do offer this thread safety -- at the cost of atomic instructions. Whether that cost is acceptable depends on your program, it hard to give general guidelines. On a modern CPU the potential speedups in the form of increased multi-threading capabilities should outweigh the costs of atomic instructions by far. On an embedded device the atomics would probably only hurt though.

`mm:atomicArc` is a threadsafe variant of ARC: All the optimizations in the form of move semantics etc are still applied. `mm:yrc` is the threadsafe variant of ORC.

YRC is a novel concurrent cycle collection algorithm -- these are beasts to verify
and to get correct so there are dragons lurking here, use at your own risk.


Other MM modes
--------------

.. note:: The `refc` GC is incremental, thread-local and not "stop-the-world".

--mm:refc    It's a deferred reference counting based garbage collector
  with a simple Mark&Sweep backup GC in order to collect cycles.
  Heaps are thread-local. [This document](refc.html) contains further information.
--mm:markAndSweep  Simple Mark-And-Sweep based garbage collector.
  Heaps are thread-local.
--mm:boehm    Boehm based garbage collector, it offers a shared heap.
--mm:go    Go's garbage collector, useful for interoperability with Go.
  Offers a shared heap. Note that `mm:go` has seen little real world use. Use at your own risk.

--mm:none    No memory management strategy nor a garbage collector. Allocated memory is
  simply never freed. You should use `--mm:arc` instead.

Here is a comparison of the different memory management modes:

================== ======== ================= ============== ====== =================== ===================
Memory Management  Heap     Reference Cycles  Stop-The-World Atomic Valgrind compatible Command line switch
================== ======== ================= ============== ====== =================== ===================
YRC                Shared   Cycle Collector   No             Yes    Yes                 `--mm:yrc`
ORC                Shared   Cycle Collector   No             No     Yes                 `--mm:orc`
ARC                Shared   Leak              No             No     Yes                 `--mm:arc`
Atomic ARC         Shared   Leak              No             Yes    Yes                 `--mm:atomicArc`
RefC               Local    Cycle Collector   No             No     No                  `--mm:refc`
Mark & Sweep       Local    Cycle Collector   No             No     No                  `--mm:markAndSweep`
Boehm              Shared   Cycle Collector   Yes            No     No                  `--mm:boehm`
Go                 Shared   Cycle Collector   Yes            No     No                  `--mm:go`
None               Manual   Manual            Manual         Manual Manual              `--mm:none`
================== ======== ================= ============== ====== =================== ===================

.. default-role:: code
.. include:: rstcommon.rst

JavaScript's garbage collector is used for the [JavaScript and NodeJS](
backends.html#backends-the-javascript-target) compilation targets.
The [NimScript](nims.html) target uses the memory management strategy built into
the Nim compiler.
