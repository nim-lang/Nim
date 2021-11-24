=======================
Nim's Memory Management
=======================

.. default-role:: code
.. include:: rstcommon.rst

:Author: Andreas Rumpf
:Version: |nimversion|

..


  "The road to hell is paved with good intentions."


Introduction
============

A memory-management algorithm optimal for every use-case cannot exist.
Nim provides multiple paradigms for needs ranging from large multi-threaded
applications, to games, hard-realtime systems and small microcontrollers.

This document describes how the management strategies work;
How to tune the garbage collectors for your needs, like (soft) `realtime systems`:idx:,
and how the memory management strategies other than garbage collectors work.


Multi-paradigm Memory Management Strategies
===========================================

.. default-role:: option

To choose the memory management strategy use the `--mm:` switch.

**The recommended switch is `--mm:orc`.**


ARC/ORC
-------

`--mm:arc` is roughly comparable to C++'s memory management with `shared_ptr`. However,
the reference counting operations (= "RC ops") do not use atomic instructions and do not have to --
instead entire subgraphs are *moved* between threads. The Nim compiler also aggressively
optimizes away RC ops and exploits `move semantics <destructors.html#move-semantics>`_. The
default `async`:idx: implementation needs `--mm:orc` and leaks memory with `--mm:arc`!

`--mm:orc` adds a cycle collector based on "trial deletion" on top of `--mm:arc`. It is
guaranteed that `acyclic`:idx: types are never processed by the cycle collector; this
means `--mm:orc` remains to be useful in hard realtime settings. However, if you fear the
cycle collector or you found `--mm:orc`'s code size implications unacceptable
(ORC produces slightly larger code sizes) feel free to use `--mm:arc` instead.

Both ARC and ORC offer deterministic performance for `hard realtime`:idx: systems, but
ARC can be easier to reason about for people coming from Ada/C++/C.

Nim performs a fair share of optimizations for ARC/ORC; you can inspect what it did
to your time critical function via `--expandArc:functionName`.


Other MM modes
--------------

.. note:: The other memory management strategies are effectively morbund.

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
