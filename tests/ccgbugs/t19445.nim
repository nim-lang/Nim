discard """
  matrix: "--nimcache:tests/ccgbugs/nimcache19445 --cincludes:nimcache19445 --header:m19445"
  targets: "c"
"""

# bug #19445
type
  Foo* {.exportc.} = object
    a*, b*, c*, d*: int

proc dummy(): Foo {.exportc.} = discard

{.compile:"m19445.c".}