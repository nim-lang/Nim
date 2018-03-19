## v0.X.X - XX/XX/2018

### Changes affecting backwards compatibility

#### Breaking changes in the standard library

- ``re.split`` for empty regular expressions now yields every character in
  the string which is what other programming languages chose to do.

#### Breaking changes in the compiler

### Library additions

- ``re.split`` now also supports the ``maxsplit`` parameter for consistency
  with ``strutils.split``.

### Library changes

### Language additions

### Language changes

- The `importcpp` pragma now allows importing the listed fields of generic
  C++ types. Support for numeric parameters have also been added through
  the use of `static[T]` types.
  (#6415)

### Tool changes

- ``jsondoc2`` has been renamed ``jsondoc``, similar to how ``doc2`` was renamed
  ``doc``. The old ``jsondoc`` can still be invoked with ``jsondoc0``.

### Compiler changes

- The VM's instruction count limit was raised to 1 billion instructions in order
  to support more complex computations at compile-time.
