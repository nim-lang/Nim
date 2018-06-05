===================================
   Nim Compiler User Guide
===================================

:Author: Andreas Rumpf
:Version: |nimversion|

.. contents::

  "Look at you, hacker. A pathetic creature of meat and bone, panting and
  sweating as you run through my corridors. How can you challenge a perfect,
  immortal machine?"


Introduction
============

This document describes the usage of the *Nim compiler*
on the different supported platforms. It is not a definition of the Nim
programming language (therefore is the `manual <manual.html>`_).

Nim is free software; it is licensed under the
`MIT License <http://www.opensource.org/licenses/mit-license.php>`_.


Compiler Usage
==============

Command line switches
---------------------
Basic command line switches are:

Usage:

.. include:: basicopt.txt

----

Advanced command line switches are:

.. include:: advopt.txt



List of warnings
----------------

Each warning can be activated individually with ``--warning[NAME]:on|off`` or
in a ``push`` pragma.

==========================       ============================================
Name                             Description
==========================       ============================================
CannotOpenFile                   Some file not essential for the compiler's
                                 working could not be opened.
OctalEscape                      The code contains an unsupported octal
                                 sequence.
Deprecated                       The code uses a deprecated symbol.
ConfigDeprecated                 The project makes use of a deprecated config
                                 file.
SmallLshouldNotBeUsed            The letter 'l' should not be used as an
                                 identifier.
EachIdentIsTuple                 The code contains a confusing ``var``
                                 declaration.
ShadowIdent                      A local variable shadows another local
                                 variable of an outer scope.
User                             Some user defined warning.
==========================       ============================================


Verbosity levels
----------------

=====  ============================================
Level  Description
=====  ============================================
0      Minimal output level for the compiler.
1      Displays compilation of all the compiled files, including those imported
       by other modules or through the `compile pragma<#compile-pragma>`_.
       This is the default level.
2      Displays compilation statistics, enumerates the dynamic
       libraries that will be loaded by the final binary and dumps to
       standard output the result of applying `a filter to the source code
       <filters.html>`_ if any filter was used during compilation.
3      In addition to the previous levels dumps a debug stack trace
       for compiler developers.
=====  ============================================


Compile time symbols
--------------------

Through the ``-d:x`` or ``--define:x`` switch you can define compile time
symbols for conditional compilation. The defined switches can be checked in
source code with the `when statement <manual.html#when-statement>`_ and
`defined proc <system.html#defined>`_. The typical use of this switch is to
enable builds in release mode (``-d:release``) where certain safety checks are
omitted for better performance. Another common use is the ``-d:ssl`` switch to
activate `SSL sockets <sockets.html>`_.

Additionally, you may pass a value along with the symbol: ``-d:x=y``
which may be used in conjunction with the `compile time define
pragmas<manual.html#implementation-specific-pragmas-compile-time-define-pragmas>`_
to override symbols during build time.


Configuration files
-------------------

**Note:** The *project file name* is the name of the ``.nim`` file that is
passed as a command line argument to the compiler.


The ``nim`` executable processes configuration files in the following
directories (in this order; later files overwrite previous settings):

1) ``$nim/config/nim.cfg``, ``/etc/nim.cfg`` (UNIX) or ``%NIMROD%/config/nim.cfg`` (Windows). This file can be skipped with the ``--skipCfg`` command line option.
2) ``$HOME/.config/nim.cfg`` (POSIX) or  ``%APPDATA%/nim.cfg`` (Windows). This file can be skipped with the ``--skipUserCfg`` command line option.
3) ``$parentDir/nim.cfg`` where ``$parentDir`` stands for any parent  directory of the project file's path. These files can be skipped with the ``--skipParentCfg`` command line option.
4) ``$projectDir/nim.cfg`` where ``$projectDir`` stands for the project  file's path. This file can be skipped with the ``--skipProjCfg`` command line option.
5) A project can also have a project specific configuration file named ``$project.nim.cfg`` that resides in the same directory as ``$project.nim``. This file can be skipped with the ``--skipProjCfg`` command line option.


Command line settings have priority over configuration file settings.

The default build of a project is a `debug build`:idx:. To compile a
`release build`:idx: define the ``release`` symbol::

  nim c -d:release myproject.nim


Search path handling
--------------------

Nim has the concept of a global search path (PATH) that is queried to
determine where to find imported modules or include files. If multiple files are
found an ambiguity error is produced.

``nim dump`` shows the contents of the PATH.

However before the PATH is used the current directory is checked for the
file's existence. So if PATH contains ``$lib`` and ``$lib/bar`` and the
directory structure looks like this::

  $lib/x.nim
  $lib/bar/x.nim
  foo/x.nim
  foo/main.nim
  other.nim

And ``main`` imports ``x``, ``foo/x`` is imported. If ``other`` imports ``x``
then both ``$lib/x.nim`` and ``$lib/bar/x.nim`` match and so the compiler
should reject it. Currently however this check is not implemented and instead
the first matching file is used.


Generated C code directory
--------------------------
The generated files that Nim produces all go into a subdirectory called
``nimcache`` in your project directory. This makes it easy to delete all
generated files. Files generated in this directory follow a naming logic which
you can read about in the `Nim Backend Integration document
<backends.html#nimcache-naming-logic>`_.

However, the generated C code is not platform independent. C code generated for
Linux does not compile on Windows, for instance. The comment on top of the
C file lists the OS, CPU and CC the file has been compiled for.


Compilation cache
=================

**Warning**: The compilation cache is still highly experimental!

The ``nimcache`` directory may also contain so called `rod`:idx:
or `symbol files`:idx:. These files are pre-compiled modules that are used by
the compiler to perform `incremental compilation`:idx:. This means that only
modules that have changed since the last compilation (or the modules depending
on them etc.) are re-compiled. However, per default no symbol files are
generated; use the ``--symbolFiles:on`` command line switch to activate them.

Unfortunately due to technical reasons the ``--symbolFiles:on`` needs
to *aggregate* some generated C code. This means that the resulting executable
might contain some cruft even with dead code elimination. So
the final release build should be done with ``--symbolFiles:off``.

Due to the aggregation of C code it is also recommended that each project
resides in its own directory so that the generated ``nimcache`` directory
is not shared between different projects.


Compiler Selection
==================

To change the compiler from the default compiler (at the command line)::

  nim c --cc:llvm_gcc --compile_only myfile.nim

This uses the configuration defined in ``config\nim.cfg`` for ``lvm_gcc``.

If nimcache already contains compiled code from a different compiler for the same project,
add the ``-f`` flag to force all files to be recompiled.

The default compiler is defined at the top of ``config\nim.cfg``.  Changing this setting
affects the compiler used by ``koch`` to (re)build Nim.


Cross compilation
=================

To cross compile, use for example::

  nim c --cpu:i386 --os:linux --compileOnly --genScript myproject.nim

Then move the C code and the compile script ``compile_myproject.sh`` to your
Linux i386 machine and run the script.

Another way is to make Nim invoke a cross compiler toolchain::

  nim c --cpu:arm --os:linux myproject.nim

For cross compilation, the compiler invokes a C compiler named
like ``$cpu.$os.$cc`` (for example arm.linux.gcc) and the configuration
system is used to provide meaningful defaults. For example for ``ARM`` your
configuration file should contain something like::

  arm.linux.gcc.path = "/usr/bin"
  arm.linux.gcc.exe = "arm-linux-gcc"
  arm.linux.gcc.linkerexe = "arm-linux-gcc"


DLL generation
==============

Nim supports the generation of DLLs. However, there must be only one
instance of the GC per process/address space. This instance is contained in
``nimrtl.dll``. This means that every generated Nim DLL depends
on ``nimrtl.dll``. To generate the "nimrtl.dll" file, use the command::

  nim c -d:release lib/nimrtl.nim

To link against ``nimrtl.dll`` use the command::

  nim c -d:useNimRtl myprog.nim

**Note**: Currently the creation of ``nimrtl.dll`` with thread support has
never been tested and is unlikely to work!


Additional compilation switches
===============================

The standard library supports a growing number of ``useX`` conditional defines
affecting how some features are implemented. This section tries to give a
complete list.

==================   =========================================================
Define               Effect
==================   =========================================================
``release``          Turns off runtime checks and turns on the optimizer.
``useWinAnsi``       Modules like ``os`` and ``osproc`` use the Ansi versions
                     of the Windows API. The default build uses the Unicode
                     version.
``useFork``          Makes ``osproc`` use ``fork`` instead of ``posix_spawn``.
``useNimRtl``        Compile and link against ``nimrtl.dll``.
``useMalloc``        Makes Nim use C's `malloc`:idx: instead of Nim's
                     own memory manager, ableit prefixing each allocation with
                     its size to support clearing memory on reallocation.
                     This only works with ``gc:none``.
``useRealtimeGC``    Enables support of Nim's GC for *soft* realtime
                     systems. See the documentation of the `gc <gc.html>`_
                     for further information.
``nodejs``           The JS target is actually ``node.js``.
``ssl``              Enables OpenSSL support for the sockets module.
``memProfiler``      Enables memory profiling for the native GC.
``uClibc``           Use uClibc instead of libc. (Relevant for Unix-like OSes)
``checkAbi``         When using types from C headers, add checks that compare
                     what's in the Nim file with what's in the C header
                     (requires a C compiler with _Static_assert support, like
                     any C11 compiler)
``tempDir``          This symbol takes a string as its value, like
                     ``--define:tempDir:/some/temp/path`` to override the
                     temporary directory returned by ``os.getTempDir()``.
                     The value **should** end with a directory separator
                     character. (Relevant for the Android platform)
``useShPath``        This symbol takes a string as its value, like
                     ``--define:useShPath:/opt/sh/bin/sh`` to override the
                     path for the ``sh`` binary, in cases where it is not
                     located in the default location ``/bin/sh``
==================   =========================================================



Additional Features
===================

This section describes Nim's additional features that are not listed in the
Nim manual. Some of the features here only make sense for the C code
generator and are subject to change.


LineDir option
--------------
The ``lineDir`` option can be turned on or off. If turned on the
generated C code contains ``#line`` directives. This may be helpful for
debugging with GDB.


StackTrace option
-----------------
If the ``stackTrace`` option is turned on, the generated C contains code to
ensure that proper stack traces are given if the program crashes or an
uncaught exception is raised.


LineTrace option
----------------
The ``lineTrace`` option implies the ``stackTrace`` option. If turned on,
the generated C contains code to ensure that proper stack traces with line
number information are given if the program crashes or an uncaught exception
is raised.

Debugger option
---------------
The ``debugger`` option enables or disables the *Embedded Nim Debugger*.
See the documentation of endb_ for further information.

Hot code reloading
------------------
**Note:** At the moment hot code reloading is supported only in
JavaScript projects.

The `hotCodeReloading`:idx: option enables special compilation mode where changes in
the code can be applied automatically to a running program. The code reloading
happens at the granularity of an individual module. When a module is reloaded,
Nim will preserve the state of all global variables which are initialized with
a standard variable declaration in the code. All other top level code will be
executed repeatedly on each reload. If you want to prevent this behavior, you
can guard a block of code with the ``once`` construct:

.. code-block:: Nim
  var settings = initTable[string, string]()

  once:
    myInit()

    for k, v in loadSettings():
      settings[k] = v

If you want to reset the state of a global variable on each reload, just
re-assign a value anywhere within the top-level code:

.. code-block:: Nim
  var lastReload: Time

  lastReload = now()
  resetProgramState()

**Known limitations:** In the JavaScript target, global variables using the
``codegenDecl`` pragma will be re-initialized on each reload. Please guard the
initialization with a `once` block to work-around this.

**Usage in JavaScript projects:**

Once your code is compiled for hot reloading, you can use a framework such
as `LiveReload <http://livereload.com/>` or `BrowserSync <https://browsersync.io/>`
to implement the actual reloading behavior in your project.

Breakpoint pragma
-----------------
The *breakpoint* pragma was specially added for the sake of debugging with
ENDB. See the documentation of `endb <endb.html>`_ for further information.


DynlibOverride
==============

By default Nim's ``dynlib`` pragma causes the compiler to generate
``GetProcAddress`` (or their Unix counterparts)
calls to bind to a DLL. With the ``dynlibOverride`` command line switch this
can be prevented and then via ``--passL`` the static library can be linked
against. For instance, to link statically against Lua this command might work
on Linux::

  nim c --dynlibOverride:lua --passL:liblua.lib program.nim


Backend language options
========================

The typical compiler usage involves using the ``compile`` or ``c`` command to
transform a ``.nim`` file into one or more ``.c`` files which are then
compiled with the platform's C compiler into a static binary. However there
are other commands to compile to C++, Objective-C or Javascript. More details
can be read in the `Nim Backend Integration document <backends.html>`_.


Nim documentation tools
=======================

Nim provides the `doc`:idx: and `doc2`:idx: commands to generate HTML
documentation from ``.nim`` source files. Only exported symbols will appear in
the output. For more details `see the docgen documentation <docgen.html>`_.

Nim idetools integration
========================

Nim provides language integration with external IDEs through the
idetools command. See the documentation of `idetools <idetools.html>`_
for further information.

..
  Nim interactive mode
  ====================

  The Nim compiler supports an interactive mode. This is also known as
  a `REPL`:idx: (*read eval print loop*). If Nim has been built with the
  ``-d:useGnuReadline`` switch, it uses the GNU readline library for terminal
  input management. To start Nim in interactive mode use the command
  ``nim secret``. To quit use the ``quit()`` command. To determine whether an input
  line is an incomplete statement to be continued these rules are used:

  1. The line ends with ``[-+*/\\<>!\?\|%&$@~,;:=#^]\s*$`` (operator symbol followed by optional whitespace).
  2. The line starts with a space (indentation).
  3. The line is within a triple quoted string literal. However, the detection
     does not work if the line contains more than one ``"""``.


Nim for embedded systems
========================

The standard library can be avoided to a point where C code generation
for 16bit micro controllers is feasible. Use the `standalone`:idx: target
(``--os:standalone``) for a bare bones standard library that lacks any
OS features.

To make the compiler output code for a 16bit target use the ``--cpu:avr``
target.

For example, to generate code for an `AVR`:idx: processor use this command::

  nim c --cpu:avr --os:standalone --genScript x.nim

For the ``standalone`` target one needs to provide
a file ``panicoverride.nim``.
See ``tests/manyloc/standalone/panicoverride.nim`` for an example
implementation.  Additionally, users should specify the
amount of heap space to use with the ``-d:StandaloneHeapSize=<size>``
command line switch.  Note that the total heap size will be
``<size> * sizeof(float64)``.


Nim for realtime systems
========================

See the documentation of Nim's soft realtime `GC <gc.html>`_ for further
information.


Debugging with Nim
==================

Nim comes with its own *Embedded Nim Debugger*. See
the documentation of endb_ for further information.


Optimizing for Nim
==================

Nim has no separate optimizer, but the C code that is produced is very
efficient. Most C compilers have excellent optimizers, so usually it is
not needed to optimize one's code. Nim has been designed to encourage
efficient code: The most readable code in Nim is often the most efficient
too.

However, sometimes one has to optimize. Do it in the following order:

1. switch off the embedded debugger (it is **slow**!)
2. turn on the optimizer and turn off runtime checks
3. profile your code to find where the bottlenecks are
4. try to find a better algorithm
5. do low-level optimizations

This section can only help you with the last item.


Optimizing string handling
--------------------------

String assignments are sometimes expensive in Nim: They are required to
copy the whole string. However, the compiler is often smart enough to not copy
strings. Due to the argument passing semantics, strings are never copied when
passed to subroutines. The compiler does not copy strings that are a result from
a procedure call, because the callee returns a new string anyway.
Thus it is efficient to do:

.. code-block:: Nim
  var s = procA() # assignment will not copy the string; procA allocates a new
                  # string already

However it is not efficient to do:

.. code-block:: Nim
  var s = varA    # assignment has to copy the whole string into a new buffer!

For ``let`` symbols a copy is not always necessary:

.. code-block:: Nim
  let s = varA    # may only copy a pointer if it safe to do so


If you know what you're doing, you can also mark single string (or sequence)
objects as `shallow`:idx:\:

.. code-block:: Nim
  var s = "abc"
  shallow(s) # mark 's' as shallow string
  var x = s  # now might not copy the string!

Usage of ``shallow`` is always safe once you know the string won't be modified
anymore, similar to Ruby's `freeze`:idx:.


The compiler optimizes string case statements: A hashing scheme is used for them
if several different string constants are used. So code like this is reasonably
efficient:

.. code-block:: Nim
  case normalize(k.key)
  of "name": c.name = v
  of "displayname": c.displayName = v
  of "version": c.version = v
  of "os": c.oses = split(v, {';'})
  of "cpu": c.cpus = split(v, {';'})
  of "authors": c.authors = split(v, {';'})
  of "description": c.description = v
  of "app":
    case normalize(v)
    of "console": c.app = appConsole
    of "gui": c.app = appGUI
    else: quit(errorStr(p, "expected: console or gui"))
  of "license": c.license = UnixToNativePath(k.value)
  else: quit(errorStr(p, "unknown variable: " & k.key))
