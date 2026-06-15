discard """
output: '''ok string
ok int
ok seq'''
"""

# Regression test: `signatureHash(T)` must be stable across the NIF boundary so
# that a macrocache keyed by it (nim-serialization's auto-serialization registry)
# can be populated in one module and queried from another under `nim ic`.
#
# Before the fix, `signatureHash` hashed the generic *parameter symbol* (whose
# `disamb` is a per-module instantiation counter) instead of the type it denotes.
# The registering module (msighashstable) and this importer instantiated the
# generic `getSig[T]` separately, got different `disamb`s, and the lookups for
# `string`/`SomeInteger` missed -> `{.error: auto serialization not enabled.}`.

import msighashstable

proc writeStr(F: type DefaultFlavor, v: string) =
  autoCheck(F, string):
    echo "ok string"

proc writeInt[T: SomeInteger](F: type DefaultFlavor, v: T) =
  autoCheck(F, SomeInteger):
    echo "ok int"

proc writeSeq[T](F: type DefaultFlavor, v: seq[T]) =
  autoCheck(F, seq):
    echo "ok seq"

writeStr(DefaultFlavor, "hi")
writeInt(DefaultFlavor, 42)
writeSeq(DefaultFlavor, @[1, 2, 3])
