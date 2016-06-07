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
code generation). The GC **never** scans the whole heap but it may scan the
delta-subgraph of the heap that changed since its last run.


The GC is only triggered in a memory allocation operation. It is not triggered
by some timer and does not run in a background thread.

To force a full collection call ``GC_fullCollect``. Note that it is generally
better to let the GC do its work and not enforce a full collection.


Cycle collector
===============

The cycle collector can be en-/disabled independently from the other parts of
the GC with ``GC_enableMarkAndSweep`` and ``GC_disableMarkAndSweep``. The
compiler analyses the types for their possibility to build cycles, but often
it is necessary to help this analysis with the ``acyclic`` pragma (see
`acyclic <manual.html#acyclic-pragma>`_ for further information).

You can also use the ``acyclic`` pragma for data that is cyclic in reality and
then break up the cycles explicitly with ``GC_addCycleRoot``. This can be a
very valuable optimization; the Nim compiler itself relies on this
optimization trick to improve performance. Note that ``GC_addCycleRoot`` is
a quick operation; the root is only registered for the next run of the
cycle collector.


Realtime support
================

To enable realtime support, the symbol `useRealtimeGC`:idx: needs to be
defined via ``--define:useRealtimeGC`` (you can put this into your config
file as well). With this switch the GC supports the following operations:

.. code-block:: nim
  proc GC_setMaxPause*(MaxPauseInUs: int)
  proc GC_step*(us: int, strongAdvice = false, stackSize = -1)

The unit of the parameters ``MaxPauseInUs`` and ``us`` is microseconds.

These two procs are the two modus operandi of the realtime GC:

(1) GC_SetMaxPause Mode

    You can call ``GC_SetMaxPause`` at program startup and then each triggered
    GC run tries to not take longer than ``MaxPause`` time. However, it is
    possible (and common) that the work is nevertheless not evenly distributed
    as each call to ``new`` can trigger the GC and thus take  ``MaxPause``
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
time will be met in almost all cases on modern CPUs unless the cycle collector
is triggered.


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

* getTotalMem(): returns the amount of total memory managed by the GC.
* getOccupiedMem(): bytes reserved by the GC and used by objects.
* getFreeMem(): bytes reserved by the GC and not in use.

In addition to ``GC_ref`` and ``GC_unref`` you can avoid the GC by manually
allocating memory with procs like ``alloc``, ``allocShared``, or
``allocCStringArray``. The GC won't try to free them, you need to call their
respective *dealloc* pairs when you are done with them or they will leak.
