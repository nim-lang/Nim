====================================
  Incremental Recompilations
====================================

We split the Nim compiler into a frontend and a backend.
The frontend produces a set of `.rod` files. Every `.nim` module
produces its own `.rod` file.

- The IR must be a faithful representation of the AST in memory.
- The backend can do its own caching but doesn't have to.
- We know by comparing 'nim check compiler/nim' against 'nim c compiler/nim'
  that 2/3 of the compiler's runtime is spent in the frontend. Hence we
  implement IC for the frontend first and only later for the backend. The
  backend will recompile everything until we implement its own caching
  mechanisms.

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


Configuration setup changes
---------------------------

For a MVP these are not detected. Later the configuration will be
stored in every `.rod` file.


Global state
------------

Global persistent state will be kept in a project specific `.rod` file.
