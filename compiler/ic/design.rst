====================================
  Incremental Recompilations
====================================

We split the Nim compiler into a frontend and a backend.
The frontend produces a set of `.rod` files. Every `.nim` module
produces its own `.rod` file.

- The IR must be a faithful representation of the AST in memory.
- The backend can do its own caching but doesn't have to. In the
  current implementation the backend also caches its results.

Advantage of the "set of files" vs the previous global database:
- By construction, we either read from the `.rod` file or from the
  `.nim` file, there can be no inconsistency. There can also be no
  partial updates.
- No dependency to external packages (SQLite). SQLite simply is too
  slow and the old way of serialization was too slow too. We use a
  format designed for Nim and expect to base further tools on this
  file format.

References to external modules must be (moduleId, symId) pairs.
The symbol IDs are module specific. This way no global ID increment
mechanism needs to be implemented that we could get wrong. ModuleIds
are rod-file specific too.



Global state
------------

There is no global state.

Rod File Format
---------------

It's a simple binary file format. `rodfiles.nim` contains some details.


Backend
-------

Nim programmers have to come to enjoy whole-program dead code elimination,
by default. Since this is a "whole program" optimization, it does break
modularity. However, thanks to the packed AST representation we can perform
this global analysis without having to unpack anything. This is basically
a mark&sweep GC algorithm:

- Start with the top level statements. Every symbol that is referenced
  from a top level statement is not "dead" and needs to be compiled by
  the backend.
- Every symbol referenced from a referenced symbol also has to be
  compiled.

Caching logic: Only if the set of alive symbols is different from the
last run, the module has to be regenerated.
