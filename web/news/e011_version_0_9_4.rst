2014-04-21 Version 0.9.4 released
=================================

.. container:: metadata

  Posted by Dominik Picheta on 21/04/2014

The Nimrod development community is proud to announce the release of version
0.9.4 of the Nimrod compiler and tools. **Note: This release has to be
considered beta quality! Lots of new features have been implemented but
unfortunately some do not fulfill our quality standards yet.**

Prebuilt binaries and instructions for building from source are available
on the `download page <download.html>`_.

This release includes about
`1400 changes <https://github.com/Araq/Nimrod/compare/v0.9.2...v0.9.4>`_
in total including various bug
fixes, new languages features and standard library additions and improvements.
This release brings with it support for user-defined type classes, a brand
new VM for executing Nimrod code at compile-time and new symbol binding
rules for clean templates.

It also introduces support for the brand new
`Babel package manager <https://github.com/nimrod-code/babel>`_ which
has itself seen its first release recently. Many of the wrappers that were
present in the standard library have been moved to separate repositories
and should now be installed using Babel.

Apart from that a new **experimental** Asynchronous IO API has been added via
the ``asyncdispatch`` and ``asyncnet`` modules. The ``net`` and ``rawsockets``
modules have also been added and they will likely replace the sockets
module in the next release. The Asynchronous IO API has been designed to
take advantage of Linux's epoll and Windows' IOCP APIs, support for BSD's
kqueue has not been implemented yet but will be in the future.
The Asynchronous IO API provides both
a callback interface and an interface which allows you to write code as you
would if you were writing synchronous code. The latter is done through
the use of an ``await`` macro which behaves similar to C#'s await. The
following is a very simple chat server demonstrating Nimrod's new async
capabilities.

.. code-block::nim
  import asyncnet, asyncdispatch

  var clients: seq[PAsyncSocket] = @[]

  proc processClient(client: PAsyncSocket) {.async.} =
    while true:
      let line = await client.recvLine()
      for c in clients:
        await c.send(line & "\c\L")

  proc serve() {.async.} =
    var server = newAsyncSocket()
    server.bindAddr(TPort(12345))
    server.listen()

    while true:
      let client = await server.accept()
      clients.add client

      processClient(client)

  serve()
  runForever()


Note that this feature has been implemented with Nimrod's macro system and so
``await`` and ``async`` are no keywords.

Syntactic sugar for anonymous procedures has also been introduced. It too has
been implemented as a macro. The following shows some simple usage of the new
syntax:

.. code-block::nim
  import future

  var s = @[1, 2, 3, 4, 5]
  echo(s.map((x: int) => x * 5))

A list of changes follows, for a comprehensive list of changes take a look
`here <https://github.com/Araq/Nimrod/compare/v0.9.2...v0.9.4>`_.

Library Additions
-----------------

- Added ``macros.genSym`` builtin for AST generation.
- Added ``macros.newLit`` procs for easier AST generation.
- Added module ``logging``.
- Added module ``asyncdispatch``.
- Added module ``asyncnet``.
- Added module ``net``.
- Added module ``rawsockets``.
- Added module ``selectors``.
- Added module ``asynchttpserver``.
- Added support for the new asynchronous IO in the ``httpclient`` module.
- Added a Python-inspired ``future`` module that features upcoming additions
  to the ``system`` module.


Changes affecting backwards compatibility
-----------------------------------------

- The scoping rules for the ``if`` statement changed for better interaction
  with the new syntactic construct ``(;)``.
- ``OSError`` family of procedures has been deprecated. Procedures with the same
  name but which take different parameters have been introduced. These procs now
  require an error code to be passed to them. This error code can be retrieved
  using the new ``OSLastError`` proc.
- ``os.parentDir`` now returns "" if there is no parent dir.
- In CGI scripts stacktraces are shown to the user only
  if ``cgi.setStackTraceStdout`` is used.
- The symbol binding rules for clean templates changed: ``bind`` for any
  symbol that's not a parameter is now the default. ``mixin`` can be used
  to require instantiation scope for a symbol.
- ``quoteIfContainsWhite`` now escapes argument in such way that it can be safely
  passed to shell, instead of just adding double quotes.
- ``macros.dumpTree`` and ``macros.dumpLisp`` have been made ``immediate``,
  ``dumpTreeImm`` and ``dumpLispImm`` are now deprecated.
- The ``nil`` statement has been deprecated, use an empty ``discard`` instead.
- ``sockets.select`` now prunes sockets that are **not** ready from the list
  of sockets given to it.
- The ``noStackFrame`` pragma has been renamed to ``asmNoStackFrame`` to
  ensure you only use it when you know what you're doing.
- Many of the wrappers that were present in the standard library have been
  moved to separate repositories and should now be installed using Babel.


Compiler Additions
------------------

- The compiler can now warn about "uninitialized" variables. (There are no
  real uninitialized variables in Nimrod as they are initialized to binary
  zero). Activate via ``{.warning[Uninit]:on.}``.
- The compiler now enforces the ``not nil`` constraint.
- The compiler now supports a ``codegenDecl`` pragma for even more control
  over the generated code.
- The compiler now supports a ``computedGoto`` pragma to support very fast
  dispatching for interpreters and the like.
- The old evaluation engine has been replaced by a proper register based
  virtual machine. This fixes numerous bugs for ``nimrod i`` and for macro
  evaluation.
- ``--gc:none`` produces warnings when code uses the GC.
- A ``union`` pragma for better C interoperability is now supported.
- A ``packed`` pragma to control the memory packing/alignment of fields in
  an object.
- Arrays can be annotated to be ``unchecked`` for easier low level
  manipulations of memory.
- Support for the new Babel package manager.


Language Additions
------------------

- Arrays can now be declared with a single integer literal ``N`` instead of a
  range; the range is then ``0..N-1``.
- Added ``requiresInit`` pragma to enforce explicit initialization.
- Exported templates are allowed to access hidden fields.
- The ``using statement`` enables you to more easily author domain-specific
  languages and libraries providing OOP-like syntactic sugar.
- Added the possibility to override various dot operators in order to handle
  calls to missing procs and reads from undeclared fields at compile-time.
- The overload resolution now supports ``static[T]`` params that must be
  evaluable at compile-time.
- Support for user-defined type classes has been added.
- The *command syntax* is supported in a lot more contexts.
- Anonymous iterators are now supported and iterators can capture variables
  of an outer proc.
- The experimental ``strongSpaces`` parsing mode has been implemented.
- You can annotate pointer types with regions for increased type safety.
- Added support for the builtin ``spawn`` for easy thread pool usage.


Tools improvements
------------------

- c2nim can deal with a subset of C++. Use the ``--cpp`` command line option
  to activate.
