Version 0.9.6 released
=================================

.. container:: metadata

  Posted by Andreas Rumpf on 19/10/2014

**Note: 0.9.6 is the last release of Nimrod. The language is being renamed to
Nim. Nim slightly breaks compatibility.**

This is a maintenance release. The upcoming 0.10.0 release has
the new features and exciting developments.


Changes affecting backwards compatibility
-----------------------------------------

- ``spawn`` now uses an elaborate self-adapting thread pool and as such
  has been moved into its own module. So to use it, you now have to import
  ``threadpool``.
- The symbol binding rules in generics changed: ``bar`` in ``foo.bar`` is
  now considered for implicit early binding.
- ``c2nim`` moved into its own repository and is now a Babel package.
- ``pas2nim`` moved into its own repository and is now a Babel package.
- ``system.$`` for floating point types now produces a human friendly string
  representation.
- ``uri.TUrl`` as well as the ``parseurl`` module are now deprecated in favour
  of the new ``TUri`` type in the ``uri`` module.
- The ``destructor`` pragma has been deprecated. Use the ``override`` pragma
  instead. The destructor's name has to be ``destroy`` now.
- ``lambda`` is not a keyword anymore.
- **system.defined has been split into system.defined and system.declared**.
  You have to use ``--symbol`` to declare new conditional symbols that can be
  set via ``--define``.
- ``--threadanalysis:on`` is now the default. To make your program compile
  you can disable it but this is only a temporary solution as this option
  will disappear soon!


Compiler improvements
---------------------

- Multi method dispatching performance has been improved by a factor of 10x for
  pathological cases.


Language Additions
------------------

- This version introduces the ``deprecated`` pragma statement that is used
  to handle the upcoming massive amount of symbol renames.
- ``spawn`` can now wrap proc that has a return value. It then returns a data
  flow variable of the wrapped return type.


Library Additions
-----------------

- Added module ``cpuinfo``.
- Added module ``threadpool``.
- ``sequtils.distnct`` has been renamed to ``sequtils.deduplicate``.
- Added ``algorithm.reversed``
- Added ``uri.combine`` and ``uri.parseUri``.
- Some sockets procedures now support a ``SafeDisconn`` flag which causes
  them to handle disconnection errors and not raise them.
