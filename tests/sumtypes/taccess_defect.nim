discard """
  matrix: "--mm:refc; --mm:orc"
  exitcode: 1
  outputsub: "field 'val' is not accessible for type 'Opt' in branch 'None' [FieldDefect]"
"""

type
  Opt[T] = object
    case
    of None: discard
    of Some: val: T

let a = Opt[int](None())
{.cast(uncheckedAccess).}:
  echo a.val
