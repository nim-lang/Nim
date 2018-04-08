## v0.X.X - XX/XX/2018

### Changes affecting backwards compatibility

- The stdlib module ``future`` has been renamed to ``sugar``.

#### Breaking changes in the standard library

- ``re.split`` for empty regular expressions now yields every character in
  the string which is what other programming languages chose to do.

- ``cookies.setCookie` no longer assumes UTC for the expiration date.

#### Breaking changes in the compiler

### Library additions

- ``re.split`` now also supports the ``maxsplit`` parameter for consistency
  with ``strutils.split``.
- Added ``system.toOpenArray`` in order to support zero-copy slicing
  operations. This is currently not yet available for the JavaScript target.

### Library changes

- ``macros.astGenRepr``, ``macros.lispRepr`` and ``macros.treeRepr``
  now escapes the content of string literals consistently.

### Language additions

- Dot calls combined with explicit generic instantiations can now be written
  as ``x.y[:z]``. ``x.y[:z]`` that is transformed into ``y[z](x)`` in the parser.

### Language changes

- The `importcpp` pragma now allows importing the listed fields of generic
  C++ types. Support for numeric parameters have also been added through
  the use of `static[T]` types.
  (#6415)

- Native C++ exceptions can now be imported with `importcpp` pragma. 
  Imported exceptions can be raised and caught just like Nim exceptionы.
  More details in language manual.

### Tool changes

- ``jsondoc2`` has been renamed ``jsondoc``, similar to how ``doc2`` was renamed
  ``doc``. The old ``jsondoc`` can still be invoked with ``jsondoc0``.

### Compiler changes

- The VM's instruction count limit was raised to 1 billion instructions in order
  to support more complex computations at compile-time.
