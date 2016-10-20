Version 0.9.2 released
======================

.. container:: metadata

  Posted by Dominik Picheta on 20/05/2013

We are pleased to announce that version 0.9.2 of the Nimrod compiler has been
released. This release has attracted by far the most contributions in comparison
to any other release.

This release brings with it many new features and bug fixes, a list of which
can be seen later. One of the major new features is the effect system together
with exception tracking which allows for checked exceptions and more,
for further details check out the `manual <manual.html#effect-system>`_.
Another major new feature is the introduction of statement list expressions,
more details on these can be found `here <manual.html#statement-list-expression>`_.
The ability to exclude symbols from modules has also been
implemented, this feature can be used like so: ``import module except symbol``.

Thanks to all `contributors <https://github.com/Araq/Nimrod/contributors>`_!

Bugfixes
--------

- The old GC never collected cycles correctly. Fixed but it can cause
  performance regressions. However you can deactivate the cycle collector
  with ``GC_disableMarkAndSweep`` and run it explicitly at an appropriate time
  or not at all. There is also a new GC you can activate
  with ``--gc:markAndSweep`` which does not have this problem but is slower in
  general and has no realtime guarantees.
- ``cast`` for floating point types now does the bitcast as specified in the
  manual. This breaks code that erroneously uses ``cast`` to convert different
  floating point values.
- SCGI module's performance has been improved greatly, it will no longer block
  on many concurrent requests.
- In total fixed over 70 github issues and merged over 60 pull requests.


Library Additions
-----------------

- There is a new experimental mark&sweep GC which can be faster (or much
  slower) than the default GC. Enable with ``--gc:markAndSweep``.
- Added ``system.onRaise`` to support a condition system.
- Added ``system.locals`` that provides access to a proc's locals.
- Added ``macros.quote`` for AST quasi-quoting.
- Added ``system.unsafeNew`` to support hacky variable length objects.
- ``system.fields`` and ``system.fieldPairs`` support ``object`` too; they
  used to only support tuples.
- Added ``system.CurrentSourcePath`` returning the full file-system path of
  the current source file.
- The ``macros`` module now contains lots of useful helpers for building up
  abstract syntax trees.


Changes affecting backwards compatibility
-----------------------------------------

- ``shared`` is a keyword now.
- Deprecated ``sockets.recvLine`` and ``asyncio.recvLine``, added
  ``readLine`` instead.
- The way indentation is handled in the parser changed significantly. However,
  this affects very little (if any) real world code.
- The expression/statement unification has been implemented. Again this
  only affects edge cases and no known real world code.
- Changed the async interface of the ``scgi`` module.
- WideStrings are now garbage collected like other string types.


Compiler Additions
------------------

- The ``doc2`` command does not generate output for the whole project anymore.
  Use the new ``--project`` switch to enable this behaviour.
- The compiler can now warn about shadowed local variables. However, this needs
  to be turned on explicitly via ``--warning[ShadowIdent]:on``.
- The compiler now supports almost every pragma in a ``push`` pragma.
- Generic converters have been implemented.
- Added a **highly experimental** ``noforward`` pragma enabling a special
  compilation mode that largely eliminates the need for forward declarations.

Language Additions
------------------

- ``case expressions`` are now supported.
- Table constructors now mimic more closely the syntax of the ``case``
  statement.
- Nimrod can now infer the return type of a proc from its body.
- Added a ``mixin`` declaration to affect symbol binding rules in generics.
- Exception tracking has been added and the ``doc2`` command annotates possible
  exceptions for you.
- User defined effects ("tags") tracking has been added and the ``doc2``
  command annotates possible tags for you.
- Types can be annotated with the new syntax ``not nil`` to explicitly state
  that ``nil`` is not allowed. However currently the compiler performs no
  advanced static checking for this; for now it's merely for documentation
  purposes.
- An ``export`` statement has been added to the language: It can be used for
  symbol forwarding so client modules don't have to import a module's
  dependencies explicitly.
- Overloading based on ASTs has been implemented.
- Generics are now supported for multi methods.
- Objects can be initialized via an *object constructor expression*.
- There is a new syntactic construct ``(;)`` unifying expressions and
  statements.
- You can now use ``from module import nil`` if you want to import the module
  but want to enforce fully qualified access to every symbol in ``module``.


Notes for the future
--------------------

- The scope rules of ``if`` statements will change in 0.9.4. This affects the
  ``=~`` pegs/re templates.
- The ``sockets`` module will become a low-level wrapper of OS-specific socket
  functions. All the high-level features of the current ``sockets`` module
  will be moved to a ``network`` module.
