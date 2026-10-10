# Helper module for tpureenum.nim (not a test itself; no `discard`).
#
# Defines a `{.pure.}` enum whose field name (`Number`) collides with a distinct
# type of the same name. Under `nim ic` the pure enum is loaded from a NIF; its
# fields must NOT leak into the importer's unqualified scope (the source path
# keeps them out via `declarePureEnumField`). Before the fix, a loaded pure
# enum's fields were marked bare-importable and leaked into `interf`, so the
# field shadowed the distinct type and `uint64(x).Number` failed with
# "undeclared field 'Number' for type system.uint64" (the nim-json-serialization
# `JsonValueKind.Number` vs web3 `Number = distinct uint64` bug).

type
  Number* = distinct uint64

  JsonValueKind* {.pure.} = enum
    String, Number, Object, Array, Bool, Null

proc val*(x: Number): uint64 = uint64(x)

proc toNumber*(x: uint64): Number =
  x.Number   # must bind to the distinct TYPE `Number`, not the pure enum field
