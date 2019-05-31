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
User                             Some user defined warning.
==========================       ============================================


List of hints
-------------

Each hint can be activated individually with ``--hint[NAME]:on|off`` or in a
``push`` pragma.

==========================       ============================================
Name                             Description
==========================       ============================================
CC                               Shows when the C compiler is called.
CodeBegin
CodeEnd
CondTrue
Conf                             A config file was loaded.
ConvToBaseNotNeeded
ConvFromXtoItselfNotNeeded
Dependency
Exec                             Program is executed.
ExprAlwaysX
ExtendedContext
GCStats                          Dumps statistics about the Garbage Collector.
GlobalVar                        Shows global variables declarations.
LineTooLong                      Line exceeds the maximum length.
Link                             Linking phase.
Name
Path                             Search paths modifications.
Pattern
Performance
Processing                       Artifact being compiled.
QuitCalled
Source                           The source line that triggered a diagnostic
                                 message.
StackTrace
Success, SuccessX                Successful compilation of a library or a binary.
User
UserRaw
XDeclaredButNotUsed              Unused symbols in the code.
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
activate SSL sockets.

Additionally, you may pass a value along with the symbol: ``-d:x=y``
which may be used in conjunction with the `compile time define
pragmas<manual.html#implementation-specific-pragmas-compile-time-define-pragmas>`_
to override symbols during build time.

Compile time symbols are completely **case insensitive** and underscores are
ignored too. ``--define:FOO`` and ``--define:foo`` are identical.


Configuration files
-------------------

**Note:** The *project file name* is the name of the ``.nim`` file that is
passed as a command line argument to the compiler.


The ``nim`` executable processes configuration files in the following
directories (in this order; later files overwrite previous settings):

1) ``$nim/config/nim.cfg``, ``/etc/nim/nim.cfg`` (UNIX) or ``<Nim's installation director>\config\nim.cfg`` (Windows). This file can be skipped with the ``--skipCfg`` command line option.
2) If environment variable ``XDG_CONFIG_HOME`` is defined, ``$XDG_CONFIG_HOME/nim/nim.cfg`` or ``~/.config/nim/nim.cfg`` (POSIX) or ``%APPDATA%/nim/nim.cfg`` (Windows). This file can be skipped with the ``--skipUserCfg`` command line option.
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
``nimcache``. Its full path is

- ``$XDG_CACHE_HOME/nim/$projectname(_r|_d)`` or ``~/.cache/nim/$projectname(_r|_d)``
  on Posix
- ``$HOME/nimcache/$projectname(_r|_d)`` on Windows.

The ``_r`` suffix is used for release builds, ``_d`` is for debug builds.

This makes it easy to delete all
generated files. Files generated in this directory follow a naming logic which
you can read about in the `Nim Backend Integration document
<backends.html#nimcache-naming-logic>`_.

The ``--nimcache``
`compiler switch <nimc.html#command-line-switches>`_ can be used to
to change the ``nimcache`` directory.

However, the generated C code is not platform independent. C code generated for
Linux does not compile on Windows, for instance. The comment on top of the
C file lists the OS, CPU and CC the file has been compiled for.


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

Cross compilation for Windows
=============================

To cross compile for Windows from Linux or OSX using the MinGW-w64 toolchain::

  nim c -d:mingw myproject.nim

Use ``--cpu:i386`` or ``--cpu:amd64`` to switch the cpu arch.

The MinGW-w64 toolchain can be installed as follows::

  Ubuntu: apt install mingw-w64
  CentOS: yum install mingw32-gcc | mingw64-gcc - requires EPEL
  OSX: brew install mingw-w64

Cross compilation for Nintendo Switch
=====================================

Simply add --os:nintendoswitch
to your usual ``nim c`` or ``nim cpp`` command and set the ``passC``
and ``passL`` command line switches to something like:

.. code-block:: console
  nim c ... --passC="-I$DEVKITPRO/libnx/include" ...
  --passL="-specs=$DEVKITPRO/libnx/switch.specs -L$DEVKITPRO/libnx/lib -lnx"

or setup a nim.cfg file like so:

.. code-block:: Nim
  #nim.cfg
  --passC="-I$DEVKITPRO/libnx/include"
  --passL="-specs=$DEVKITPRO/libnx/switch.specs -L$DEVKITPRO/libnx/lib -lnx"

The DevkitPro setup must be the same as the default with their new installer
`here for Mac/Linux <https://github.com/devkitPro/pacman/releases>`_ or
`here for Windows <https://github.com/devkitPro/installer/releases>`_.

For example, with the above mentioned config::

  nim c --os:nintendoswitch switchhomebrew.nim

This will generate a file called ``switchhomebrew.elf`` which can then be turned into
an nro file with the ``elf2nro`` tool in the DevkitPro release. Examples can be found at
`the nim-libnx github repo <https://github.com/jyapayne/nim-libnx.git>`_.

There are a few things that don't work because the DevkitPro libraries don't support them.
They are:

1. Waiting for a subprocess to finish. A subprocess can be started, but right
   now it can't be waited on, which sort of makes subprocesses a bit hard to use
2. Dynamic calls. DevkitPro libraries have no dlopen/dlclose functions.
3. Command line parameters. It doesn't make sense to have these for a console
   anyways, so no big deal here.
4. mqueue. Sadly there are no mqueue headers.
5. ucontext. No headers for these either. No coroutines for now :(
6. nl_types. No headers for this.

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

======================   =========================================================
Define                   Effect
======================   =========================================================
``release``              Turns off runtime checks and turns on the optimizer.
                         More aggressive optimizations are possible, eg:
                         ``--passC:-ffast-math`` (but see issue #10305)
                         ``--stacktrace:off``
``useFork``              Makes ``osproc`` use ``fork`` instead of ``posix_spawn``.
``useNimRtl``            Compile and link against ``nimrtl.dll``.
``useMalloc``            Makes Nim use C's `malloc`:idx: instead of Nim's
                         own memory manager, albeit prefixing each allocation with
                         its size to support clearing memory on reallocation.
                         This only works with ``gc:none`` and
                         with ``--newruntime``.
``useRealtimeGC``        Enables support of Nim's GC for *soft* realtime
                         systems. See the documentation of the `gc <gc.html>`_
                         for further information.
``logGC``                Enable GC logging to stdout.
``nodejs``               The JS target is actually ``node.js``.
``ssl``                  Enables OpenSSL support for the sockets module.
``memProfiler``          Enables memory profiling for the native GC.
``uClibc``               Use uClibc instead of libc. (Relevant for Unix-like OSes)
``checkAbi``             When using types from C headers, add checks that compare
                         what's in the Nim file with what's in the C header
                         (requires a C compiler with _Static_assert support, like
                         any C11 compiler)
``tempDir``              This symbol takes a string as its value, like
                         ``--define:tempDir:/some/temp/path`` to override the
                         temporary directory returned by ``os.getTempDir()``.
                         The value **should** end with a directory separator
                         character. (Relevant for the Android platform)
``useShPath``            This symbol takes a string as its value, like
                         ``--define:useShPath:/opt/sh/bin/sh`` to override the
                         path for the ``sh`` binary, in cases where it is not
                         located in the default location ``/bin/sh``.
``noSignalHandler``      Disable the crash handler from ``system.nim``.
======================   =========================================================



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

Hot code reloading
------------------

The `hotCodeReloading`:idx: option enables special compilation mode where
changes in the code can be applied automatically to a running program.
The code reloading happens at the granularity of an individual module.
When a module is reloaded, any newly added global variables will be
initialized, but all other top-level code appearing in the module won't
be re-executed and the state of all existing global variables will be
preserved. One can use the special event handlers ``beforeCodeReload`` and
``afterCodeReload`` to reset the state of a particular variable or to force
the execution of certain statements:

.. code-block:: Nim
  var
   settings = initTable[string, string]()
   lastReload: Time

  for k, v in loadSettings():
    settings[k] = v

  initProgram()

  afterCodeReload:
    lastReload = now()
    resetProgramState()

On each code reload, Nim will first execute all `beforeCodeReload`:idx:
handlers registered in the previous version of the program and then all
`afterCodeReload`:idx handlers appearing in the newly loaded code. Please note
that any handlers appearing in modules that weren't reloaded will also be
executed. To prevent this behavior, one can guard the code with the
`hasModuleChanged()`:idx: API:

.. code-block:: Nim
  import mydb

  var myCache = initTable[Key, Value]()

  afterCodeReload:
    if hasModuleChanged(mydb):
      resetCache(myCache)

The hot code reloading is based on dynamic library hot swapping in the native
targets and direct manipulation of the global namespace in the JavaScript
target. The Nim compiler does not specify the mechanism for detecting the
conditions when the code must be reloaded. Instead, the program code is
expected to call `performCodeReload()`:idx every time it wishes to reload
its code.

It's expected that most projects will implement the reloading with a suitable
build-system triggered IPC notification mechanism, but a polling solution is
also possible through the provided `hasAnyModuleChanged()`:idx API.

In order to access ``beforeCodeReload``, ``afterCodeReload``, ``hasModuleChanged``
or ``hasAnyModuleChanged`` one must import the `hotcodereloading`:idx module.

**Usage in Native projects:**

Native projects using the hot code reloading option will be implicitly
compiled with the `-d:useNimRtl` option and they will depend on both
the ``nimrtl`` library and the ``nimhcr`` library which implements the
hot code reloading run-time.

All modules of the project will be compiled to separate dynamic link
libraries placed in the ``nimcache`` directory. Please note that during
the execution of the program, the hot code reloading run-time will load
only copies of these libraries in order to not interfere with any newly
issued build commands.

The main module of the program is considered non-reloadable. Please note
that procs from reloadable modules should not appear in the call stack of
program while ``performCodeReload`` is being called. Thus, the main module
is a suitable place for implementing a program loop capable of calling
``performCodeReload``.

Please note that reloading won't be possible when any of the type definitions
in the program has been changed. When closure iterators are used (directly or
through async code), the reloaded refinitions will affect only newly created
instances. Existing iterator instancess will execute their original code to
completion.

**Usage in JavaScript projects:**

Once your code is compiled for hot reloading, the ``nim-livereload`` NPM
package provides a convenient solution for implementing the actual reloading
in the browser using a framework such as [LiveReload](http://livereload.com/)
or [BrowserSync](https://browsersync.io/).


DynlibOverride
==============

By default Nim's ``dynlib`` pragma causes the compiler to generate
``GetProcAddress`` (or their Unix counterparts)
calls to bind to a DLL. With the ``dynlibOverride`` command line switch this
can be prevented and then via ``--passL`` the static library can be linked
against. For instance, to link statically against Lua this command might work
on Linux::

  nim c --dynlibOverride:lua --passL:liblua.lib program.nim


Cursor pragma
=============

The ``.cursor`` pragma is a temporary tool for optimization purposes
and this property will be computed by Nim's optimizer eventually. Thus it
remains undocumented.


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


Signal handling in Nim
======================

The Nim programming language has no concept of Posix's signal handling
mechanisms. However, the standard library offers some rudimentary support
for signal handling, in particular, segmentation faults are turned into
fatal errors that produce a stack trace. This can be disabled with the
``-d:noSignalHandler`` switch.


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
