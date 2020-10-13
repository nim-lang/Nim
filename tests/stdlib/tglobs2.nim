import std/globs2
from std/private/globs2 as globs2Old import fn

proc baz(a: seq[PathEntry]) = fn(a[0].path)
baz(@[PathEntry(path: "a")])
