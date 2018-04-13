## v0.X.X - XX/XX/2018

### Changes affecting backwards compatibility

- The stdlib module ``future`` has been renamed to ``sugar``.
- ``macros.callsite`` is now deprecated. Since the introduction of ``varargs``
  parameters this became unnecessary.

#### Breaking changes in the standard library

- ``re.split`` for empty regular expressions now yields every character in
  the string which is what other programming languages chose to do.
- The returned tuple of ``system.instantiationInfo`` now has a third field
  containing the column of the instantiation.

- ``cookies.setCookie` no longer assumes UTC for the expiration date.

#### Breaking changes in the compiler

### Library additions

- ``re.split`` now also supports the ``maxsplit`` parameter for consistency
  with ``strutils.split``.
- Added ``system.toOpenArray`` in order to support zero-copy slicing
  operations. This is currently not yet available for the JavaScript target.
- Added ``getCurrentDir``, ``findExe``, ``cpDir`` and  ``mvDir`` procs to
  ``nimscript``.

### Library changes

- ``macros.astGenRepr``, ``macros.lispRepr`` and ``macros.treeRepr``
  now escapes the content of string literals consistently.
- ``macros.NimSym`` and ``macros.NimIdent`` is now deprecated in favor
  of the more general ``NimNode``.
- ``macros.getImpl`` now includes the pragmas of types, instead of omitting them.
- ``macros.hasCustomPragma`` and ``macros.getCustomPragmaVal`` now 
  also support pragmas on types(including variants), ``ref`` and ``ptr`` types.

### Language additions

- Dot calls combined with explicit generic instantiations can now be written
  as ``x.y[:z]``. ``x.y[:z]`` that is transformed into ``y[z](x)`` in the parser.
- ``func`` is now an alias for ``proc {.noSideEffect.}``.

### Language changes

- The `importcpp` pragma now allows importing the listed fields of generic
  C++ types. Support for numeric parameters have also been added through
  the use of `static[T]` types.
  (#6415)

- Native C++ exceptions can now be imported with `importcpp` pragma.
  Imported exceptions can be raised and caught just like Nim exceptions.
  More details in language manual.

### Tool changes

- ``jsondoc2`` has been renamed ``jsondoc``, similar to how ``doc2`` was renamed
  ``doc``. The old ``jsondoc`` can still be invoked with ``jsondoc0``.

### Compiler changes

- The VM's instruction count limit was raised to 1 billion instructions in order
  to support more complex computations at compile-time.
- Added ``macros.getProjectPath`` and ``ospaths.putEnv`` procs to VM.