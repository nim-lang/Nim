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

### Tool changes

### Compiler changes

### Bugfixes
