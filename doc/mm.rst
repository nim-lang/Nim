=======================
Nim's Memory Management
=======================

.. default-role:: code
.. include:: rstcommon.rst

:Author: Andreas Rumpf
:Version: |nimversion|

..


  "The road to hell is paved with good intentions."


Multi-paradigm Memory Management Strategies
===========================================

.. default-role:: option

Nim offers multiple different memory management strategies.
To choose the memory management strategy use the `--mm:` switch.

**The recommended switch for newly written Nim code is `--mm:orc`.**


ARC/ORC
-------

`--mm:orc` is a memory management mode primarily based on reference counting. Cycles
in the object graph are handled by a "cycle collector" which is based on "trial deletion".
Since algorithms based on "tracing" are not used, the runtime behavior is oblivious to
the involved heap sizes.

The reference counting operations (= "RC ops") do not use atomic instructions and do not have to --
instead entire subgraphs are *moved* between threads. The Nim compiler also aggressively
optimizes away RC ops and exploits `move semantics <destructors.html#move-semantics>`_.

Nim performs a fair share of optimizations for ARC/ORC; you can inspect what it did
to your time critical function via `--expandArc:functionName`.

`--mm:arc` uses the same mechanism as `--mm:orc`, but it leaves out the cycle collector.
Both ARC and ORC offer deterministic performance for `hard realtime`:idx: systems, but
ARC can be easier to reason about for people coming from Ada/C++/C -- roughly speaking
the memory for a variable is freed when it goes "out of scope".

We generally advise you to use the `acyclic` annotation in order to optimize away the
cycle collector's overhead
but `--mm:orc` also produces more machine code than `--mm:arc`, so if you're on a target
where code size matters and you know that your code does not produce cycles, you can
use `--mm:arc`. Notice that the default `async`:idx: implementation produces cycles
and leaks memory with `--mm:arc`, in other words, for `async` you need to use `--mm:orc`.



Other MM modes
--------------

.. note:: The default `refc` GC is incremental, thread-local and not "stop-the-world".

--mm:refc    This is the default memory management strategy. It's a
  deferred reference counting based garbage collector
  with a simple Mark&Sweep backup GC in order to collect cycles. Heaps are thread-local.
  `This document <refc.html>`_ contains further information.
--mm:markAndSweep  Simple Mark-And-Sweep based garbage collector.
  Heaps are thread-local.
--mm:boehm    Boehm based garbage collector, it offers a shared heap.
--mm:go    Go's garbage collector, useful for interoperability with Go.
  Offers a shared heap.

--mm:none    No memory management strategy nor a garbage collector. Allocated memory is
  simply never freed. You should use `--mm:arc` instead.

Here is a comparison of the different memory management modes:

================== ======== ================= ============== ===================
Memory Management  Heap     Reference Cycles  Stop-The-World Command line switch
================== ======== ================= ============== ===================
ORC                Shared   Cycle Collector   No             `--mm:orc`
ARC                Shared   Leak              No             `--mm:arc`
RefC               Local    Cycle Collector   No             `--mm:refc`
Mark & Sweep       Local    Cycle Collector   No             `--mm:markAndSweep`
Boehm              Shared   Cycle Collector   Yes            `--mm:boehm`
Go                 Shared   Cycle Collector   Yes            `--mm:go`
None               Manual   Manual            Manual         `--mm:none`
================== ======== ================= ============== ===================

.. default-role:: code
.. include:: rstcommon.rst

JavaScript's garbage collector is used for the `JavaScript and NodeJS
<backends.html#backends-the-javascript-target>`_ compilation targets.
The `NimScript <nims.html>`_ target uses the memory management strategy built into
the Nim compiler.
