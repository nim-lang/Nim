# A generic and a macro whose expansions use the fields of their argument.

import std/macros

proc countFields*[T: object](o: T): int =
  for k, v in o.fieldPairs:
    discard v
    inc result

macro setFlag*(o: typed): untyped =
  let field = ident"flag"
  result = quote do:
    `o`.`field` = true
