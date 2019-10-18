==========================
Nim's Garbage Collector
==========================

:Author: Andreas Rumpf
:Version: |nimversion|

..


  "The road to hell is paved with good intentions."


Introduction
============

This document describes how the GC works and how to tune it for
(soft) `realtime systems`:idx:.

The basic algorithm is *Deferred Reference Counting* with cycle detection.
References on the stack are not counted for better performance (and easier C
code generation). Cycle detection is currently done by a simple mark&sweep
GC that has to scan the full (thread local heap). ``--gc:v2`` replaces this
with an incremental mark and sweep. That it is not production ready yet,
however.


The GC is only triggered in a memory allocation operation. It is not triggered
by some timer and does not run in a background thread.

To force a full collection call ``GC_fullCollect``. Note that it is generally
better to let the GC do its work and not enforce a full collection.


Cycle collector
===============

The cycle collector can be en-/disabled independently from the other parts of
the GC with ``GC_enableMarkAndSweep`` and ``GC_disableMarkAndSweep``.


Realtime support
================

To enable realtime support, the symbol `useRealtimeGC`:idx: needs to be
defined via ``--define:useRealtimeGC`` (you can put this into your config
file as well). With this switch the GC supports the following operations:

.. code-block:: nim
  proc GC_setMaxPause*(maxPauseInUs: int)
  proc GC_step*(us: int, strongAdvice = false, stackSize = -1)

The unit of the parameters ``maxPauseInUs`` and ``us`` is microseconds.

These two procs are the two modus operandi of the realtime GC:

(1) GC_SetMaxPause Mode

    You can call ``GC_SetMaxPause`` at program startup and then each triggered
    GC run tries to not take longer than ``maxPause`` time. However, it is
    possible (and common) that the work is nevertheless not evenly distributed
    as each call to ``new`` can trigger the GC and thus take  ``maxPause``
    time.

(2) GC_step Mode

    This allows the GC to perform some work for up to ``us`` time. This is
    useful to call in a main loop to ensure the GC can do its work. To
    bind all GC activity to a ``GC_step`` call, deactivate the GC with
    ``GC_disable`` at program startup. If ``strongAdvice`` is set to ``true``,
    GC will be forced to perform collection cycle. Otherwise, GC may decide not
    to do anything, if there is not much garbage to collect.
    You may also specify the current stack size via ``stackSize`` parameter.
    It can improve performance, when you know that there are no unique Nim
    references below certain point on the stack. Make sure the size you specify
    is greater than the potential worst case size.

These procs provide a "best effort" realtime guarantee; in particular the
cycle collector is not aware of deadlines yet. Deactivate it to get more
predictable realtime behaviour. Tests show that a 2ms max pause
time will be met in almost all cases on modern CPUs (with the cycle collector
disabled).


Time measurement
----------------

The GC's way of measuring time uses (see ``lib/system/timers.nim`` for the
implementation):

1) ``QueryPerformanceCounter`` and ``QueryPerformanceFrequency`` on Windows.
2) ``mach_absolute_time`` on Mac OS X.
3) ``gettimeofday`` on Posix systems.

As such it supports a resolution of nanoseconds internally; however the API
uses microseconds for convenience.


Define the symbol ``reportMissedDeadlines`` to make the GC output whenever it
missed a deadline. The reporting will be enhanced and supported by the API in
later versions of the collector.


Tweaking the GC
---------------

The collector checks whether there is still time left for its work after
every ``workPackage``'th iteration. This is currently set to 100 which means
that up to 100 objects are traversed and freed before it checks again. Thus
``workPackage`` affects the timing granularity and may need to be tweaked in
highly specialized environments or for older hardware.


Keeping track of memory
-----------------------

If you need to pass around memory allocated by Nim to C, you can use the
procs ``GC_ref`` and ``GC_unref`` to mark objects as referenced to avoid them
being freed by the GC. Other useful procs from `system <system.html>`_ you can
use to keep track of memory are:

* ``getTotalMem()`` Returns the amount of total memory managed by the GC.
* ``getOccupiedMem()`` Bytes reserved by the GC and used by objects.
* ``getFreeMem()`` Bytes reserved by the GC and not in use.

These numbers are usually only for the running thread, not for the whole heap,
with the exception of ``--gc:boehm`` and ``--gc:go``.

In addition to ``GC_ref`` and ``GC_unref`` you can avoid the GC by manually
allocating memory with procs like ``alloc``, ``allocShared``, or
``allocCStringArray``. The GC won't try to free them, you need to call their
respective *dealloc* pairs when you are done with them or they will leak.


Heap dump
=========

The heap dump feature is still in its infancy, but it already proved
useful for us, so it might be useful for you. To get a heap dump, compile
with ``-d:nimTypeNames`` and call ``dumpNumberOfInstances`` at a strategic place in your program.
This produces a list of used types in your program and for every type
the total amount of object instances for this type as well as the total
amount of bytes these instances take up. This list is currently unsorted!
You need to use external shell script hacking to sort it.

The numbers count the number of objects in all GC heaps, they refer to
all running threads, not only to the current thread. (The current thread
would be the thread that calls ``dumpNumberOfInstances``.) This might
change in later versions.


Garbage collector options
-------------------------

You can choose which garbage collector to use when compiling source code,
you can pass ``--gc:`` on the compile command with the choosed garbage collector.

- ``--gc:refc`` Deferred `reference counting <https://en.wikipedia.org/wiki/Reference_counting>`_ with cycle detection, `thread local heap <https://en.wikipedia.org/wiki/Heap_(programming)>`_, default.
- ``--gc:markAndSweep`` `Mark-And-Sweep <https://en.wikipedia.org/wiki/Tracing_garbage_collection#Copying_vs._mark-and-sweep_vs._mark-and-don't-sweep>`_ based garbage collector, `thread local heap <https://en.wikipedia.org/wiki/Heap_(programming)>`_.
- ``--gc:boehm`` `Boehm <https://en.wikipedia.org/wiki/Boehm_garbage_collector>`_ based garbage collector, `stop-the-world <https://en.wikipedia.org/wiki/Tracing_garbage_collection#Stop-the-world_vs._incremental_vs._concurrent>`_, `shared heap <https://en.wikipedia.org/wiki/Heap_(programming)>`_.
- ``--gc:go`` Go lang like garbage collector, `stop-the-world <https://en.wikipedia.org/wiki/Tracing_garbage_collection#Stop-the-world_vs._incremental_vs._concurrent>`_, `shared heap <https://en.wikipedia.org/wiki/Heap_(programming)>`_.
- ``--gc:regions`` `Stack <https://en.wikipedia.org/wiki/Memory_management#Stack_allocation>`_ based garbage collector.
- ``--gc:none`` No garbage collector.

The same Nim code can be compiled to use any of the garbage collectors;
the Nim syntax generally will not change from one garbage collector to another.
No garbage collector is used for `JavaScript and NodeJS
<backends.html#backends-the-javascript-target>`_ compilation targets.
`NimScript <nims.html>`_ target uses Nim VM garbage collector.

If you are new to Nim and just starting, the default garbage collector is balanced to fit most common use cases.
