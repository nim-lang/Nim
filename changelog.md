## v0.18.0 - dd/mm/yyyy

### Changes affecting backwards compatibility

- Removed basic2d/basic3d out of the stdlib and into Nimble packages.
  These packages deprecated however, use the ``glm``, ``arraymancer``, ``neo``
  or another package.
- Arrays of char cannot be converted to ``cstring`` anymore, pointers to
  arrays of char can! This means ``$`` for arrays can finally exist
  in ``system.nim`` and do the right thing.
- ``echo`` now works with strings that contain ``\0`` (the binary zero is not
  shown) and ``nil`` strings are equal to empty strings.
- JSON: Deprecated `getBVal`, `getFNum`, and `getNum` in favour to
  `getBool`, `getFloat`, `getBiggestInt`. Also `getInt` procedure was added.
- `reExtended` is no longer default for the `re` constructor in the `re`
  module.
- The overloading rules changed slightly so that constrained generics are
  preferred over unconstrained generics. (Bug #6526)
- Removed libuv out of the stdlib and into Nimble packages.
- It is now possible to forward declare object types so that mutually
  recursive types can be created across module boundaries. See
  [package level objects](https://nim-lang.org/docs/manual.html#package-level-objects)
  for more information.
- The **unary** ``<`` is now deprecated, for ``.. <`` use ``..<`` for other usages
  use the ``pred`` proc.
- We changed how array accesses "from backwards" like ``a[^1]`` or ``a[0..^1]`` are
  implemented. These are now implemented purely in ``system.nim`` without compiler
  support. There is a new "heterogenous" slice type ``system.HSlice`` that takes 2
  generic parameters which can be ``BackwardsIndex`` indices. ``BackwardsIndex`` is
  produced by ``system.^``.
  This means if you overload ``[]`` or ``[]=`` you need to ensure they also work
  with ``system.BackwardsIndex`` (if applicable for the accessors).
- ``mod`` and bitwise ``and`` do not produce ``range`` subtypes anymore. This
  turned out to be more harmful than helpful and the language is simpler
  without this special typing rule.
- Added ``algorithm.rotateLeft``.
- ``rationals.toRational`` now uses an algorithm based on continued fractions.
  This means its results are more precise and it can't run into an infinite loop
  anymore.
- Added ``typetraits.$`` as an alias for ``typetraits.name``.
- ``os.getEnv`` now takes an optional ``default`` parameter that tells ``getEnv``
  what to return if the environment variable does not exist.
- Removed PDCurses wrapper from the stdlib and published it as a separate
  Nimble package.
- Bodies of ``for`` loops now get their own scope:

.. code-block:: nim
  # now compiles:
  for i in 0..4:
    let i = i + 1
    echo i

- The parsing rules of ``if`` expressions were changed so that multiple
  statements are allowed in the branches. We found few code examples that
  now fail because of this change, but here is one:

.. code-block:: nim

  t[ti] = if exp_negative: '-' else: '+'; inc(ti)

This now needs to be written as:

.. code-block:: nim

  t[ti] = (if exp_negative: '-' else: '+'); inc(ti)

- To make Nim even more robust the system iterators ``..`` and ``countup``
  now only accept a single generic type ``T``. This means the following code
  doesn't die with an "out of range" error anymore:

.. code-block:: nim

  var b = 5.Natural
  var a = -5
  for i in a..b:
    echo i
