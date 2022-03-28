Tweaking the refc GC
====================

Cycle collector
---------------

The cycle collector can be en-/disabled independently from the other parts of
the garbage collector with `GC_enableMarkAndSweep` and `GC_disableMarkAndSweep`.


Soft real-time support
----------------------

To enable real-time support, the symbol `useRealtimeGC`:idx: needs to be
defined via `--define:useRealtimeGC`:option: (you can put this into your config
file as well).
With this switch the garbage collector supports the following operations:

.. code-block:: nim
  proc GC_setMaxPause*(maxPauseInUs: int)
  proc GC_step*(us: int, strongAdvice = false, stackSize = -1)

The unit of the parameters `maxPauseInUs` and `us` is microseconds.

These two procs are the two modus operandi of the real-time garbage collector:

(1) GC_SetMaxPause Mode

    You can call `GC_SetMaxPause` at program startup and then each triggered
    garbage collector run tries to not take longer than `maxPause` time. However, it is
    possible (and common) that the work is nevertheless not evenly distributed
    as each call to `new` can trigger the garbage collector and thus take  `maxPause`
    time.

(2) GC_step Mode

    This allows the garbage collector to perform some work for up to `us` time.
    This is useful to call in the main loop to ensure the garbage collector can do its work.
    To bind all garbage collector activity to a `GC_step` call,
    deactivate the garbage collector with `GC_disable` at program startup.
    If `strongAdvice` is set to `true`,
    then the garbage collector will be forced to perform the collection cycle.
    Otherwise, the garbage collector may decide not to do anything,
    if there is not much garbage to collect.
    You may also specify the current stack size via `stackSize` parameter.
    It can improve performance when you know that there are no unique Nim references
    below a certain point on the stack. Make sure the size you specify is greater
    than the potential worst-case size.

    It can improve performance when you know that there are no unique Nim
    references below a certain point on the stack. Make sure the size you specify
    is greater than the potential worst-case size.

These procs provide a "best effort" real-time guarantee; in particular the
cycle collector is not aware of deadlines. Deactivate it to get more
predictable real-time behaviour. Tests show that a 1ms max pause
time will be met in almost all cases on modern CPUs (with the cycle collector
disabled).


Time measurement with garbage collectors
----------------------------------------

The garbage collectors' way of measuring time uses
(see ``lib/system/timers.nim`` for the implementation):

1) `QueryPerformanceCounter` and `QueryPerformanceFrequency` on Windows.
2) `mach_absolute_time` on Mac OS X.
3) `gettimeofday` on Posix systems.

As such it supports a resolution of nanoseconds internally; however, the API
uses microseconds for convenience.

Define the symbol `reportMissedDeadlines` to make the
garbage collector output whenever it missed a deadline.
The reporting will be enhanced and supported by the API in later versions of the collector.


Tweaking the garbage collector
------------------------------

The collector checks whether there is still time left for its work after
every `workPackage`'th iteration. This is currently set to 100 which means
that up to 100 objects are traversed and freed before it checks again. Thus
`workPackage` affects the timing granularity and may need to be tweaked in
highly specialized environments or for older hardware.


Thread coordination
-------------------

When the `NimMain()` function is called Nim initializes the garbage
collector to the current thread, which is usually the main thread of your
application. If your C code later spawns a different thread and calls Nim
code, the garbage collector will fail to work properly and you will crash.

As long as you don't use the threadvar emulation Nim uses native thread
variables, of which you get a fresh version whenever you create a thread. You
can then attach a GC to this thread via

.. code-block:: nim

  system.setupForeignThreadGc()

It is **not** safe to disable the garbage collector and enable it after the
call from your background thread even if the code you are calling is short
lived.

Before the thread exits, you should tear down the thread's GC to prevent memory
leaks by calling

.. code-block:: nim

  system.tearDownForeignThreadGc()



Keeping track of memory
=======================

If you need to pass around memory allocated by Nim to C, you can use the
procs `GC_ref` and `GC_unref` to mark objects as referenced to avoid them
being freed by the garbage collector.
Other useful procs from `system <system.html>`_ you can use to keep track of memory are:

* `getTotalMem()` Returns the amount of total memory managed by the garbage collector.
* `getOccupiedMem()` Bytes reserved by the garbage collector and used by objects.
* `getFreeMem()` Bytes reserved by the garbage collector and not in use.
* `GC_getStatistics()` Garbage collector statistics as a human-readable string.

These numbers are usually only for the running thread, not for the whole heap,
with the exception of `--mm:boehm`:option: and `--mm:go`:option:.

In addition to `GC_ref` and `GC_unref` you can avoid the garbage collector by manually
allocating memory with procs like `alloc`, `alloc0`, `allocShared`, `allocShared0` or `allocCStringArray`.
The garbage collector won't try to free them, you need to call their respective *dealloc* pairs
(`dealloc`, `deallocShared`, `deallocCStringArray`, etc)
when you are done with them or they will leak.


Heap dump
=========

The heap dump feature is still in its infancy, but it already proved
useful for us, so it might be useful for you. To get a heap dump, compile
with `-d:nimTypeNames`:option: and call `dumpNumberOfInstances`
at a strategic place in your program.
This produces a list of the used types in your program and for every type
the total amount of object instances for this type as well as the total
amount of bytes these instances take up.

The numbers count the number of objects in all garbage collector heaps, they refer to
all running threads, not only to the current thread. (The current thread
would be the thread that calls `dumpNumberOfInstances`.) This might
change in later versions.
