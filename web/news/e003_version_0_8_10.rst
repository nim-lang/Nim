Version 0.8.10 released
=======================

.. container:: metadata

  Posted by Andreas Rumpf on 20/10/2010

Bugfixes
--------

- Bugfix: Command line parsing on Windows and ``os.parseCmdLine`` now adheres
  to the same parsing rules as Microsoft's C/C++ startup code.
- Bugfix: Passing a ``ref`` pointer to the untyped ``pointer`` type is invalid.
- Bugfix: Updated ``keyval`` example.
- Bugfix: ``system.splitChunk`` still contained code for debug output.
- Bugfix: ``dialogs.ChooseFileToSave`` uses ``STOCK_SAVE`` instead of
  ``STOCK_OPEN`` for the GTK backend.
- Bugfix: Various bugs concerning exception handling fixed.
- Bugfix: ``low(somestring)`` crashed the compiler.
- Bugfix: ``strutils.endsWith`` lacked range checking.
- Bugfix: Better detection for AMD64 on Mac OS X.


Changes affecting backwards compatibility
-----------------------------------------

- Reversed parameter order for ``os.copyFile`` and ``os.moveFile``!!!
- Procs not marked as ``procvar`` cannot only be passed to a procvar anymore,
  unless they are used in the same module.
- Deprecated ``times.getStartMilsecs``: Use ``epochTime`` or ``cpuTime``
  instead.
- Removed ``system.OpenFile``.
- Removed ``system.CloseFile``.
- Removed ``strutils.replaceStr``.
- Removed ``strutils.deleteStr``.
- Removed ``strutils.splitLinesSeq``.
- Removed ``strutils.splitSeq``.
- Removed ``strutils.toString``.
- If a DLL cannot be loaded (via the ``dynlib`` pragma) ``EInvalidLibrary``
  is not raised anymore. Instead ``system.quit()`` is called. This is because
  raising an exception requires heap allocations. However the memory manager
  might be contained in the DLL that failed to load.
- The ``re`` module (and the ``pcre`` wrapper) now depend on the pcre dll.


Additions
---------

- The ``{.compile: "file.c".}`` pragma uses a CRC check to see if the file
  needs to be recompiled.
- Added ``system.reopen``.
- Added ``system.getCurrentException``.
- Added ``system.appType``.
- Added ``system.compileOption``.
- Added ``times.epochTime`` and ``times.cpuTime``.
- Implemented explicit type arguments for generics.
- Implemented ``{.size: sizeof(cint).}`` pragma for enum types. This is useful
  for interfacing with C.
- Implemented ``{.pragma.}`` pragma for user defined pragmas.
- Implemented ``{.extern.}`` pragma for better control of name mangling.
- The ``importc`` and ``exportc`` pragmas support format strings:
  ``proc p{.exportc: "nim_$1".}`` exports ``p`` as ``nim_p``. This is useful
  for user defined pragmas.
- The standard library can be built as a DLL. Generating DLLs has been
  improved.
- Added ``expat`` module.
- Added ``json`` module.
- Added support for a *Tiny C* backend. Currently this only works on Linux.
  You need to bootstrap with ``-d:tinyc`` to enable Tiny C support. Nimrod
  can then execute code directly via ``nimrod run myfile``.
