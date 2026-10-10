discard """
  output: '''9'''
"""

# Regression test for object-field serialization of static-generic instances
# under `nim ic`.
#
# A generic object's instances SHARE one field PSym (same itemId) while each
# instance carries a DISTINCT field type, e.g. `Digest[32].data: array[32,byte]`
# vs `Digest[48].data: array[48,byte]` (this is exactly nimcrypto's `MDigest`,
# which crashed compiling nimbus's `altair.nim`). The `.s.bif` writer DEFs each
# field once inside its owning type's reclist and references it as a bare SymUse
# elsewhere, deduping by a per-Writer `emittedFieldSyms` set. That set wrongly
# spanned DIFFERENT type reclists: after the first instance's `data` def, every
# other instance's reclist got a typeless SymUse stub instead of its own typed
# def. On load that field had a nil `typ`/`owner`, and `=destroy` lifting
# (`liftdestructors.fillBodyObj`) dereferenced it -> SIGSEGV. The fix scopes the
# dedup per-reclist so each instance reclist is a self-contained typed def.
#
# The `seq` field forces `=destroy` to be lifted for `Outer`, which walks the
# reclists of both `Digest` instances (the crash path).

type
  Digest[n: static int] = object
    data: array[n, byte]
  Outer = object
    a: Digest[32]
    b: Digest[48]
    s: seq[int]

proc use(o: Outer): int =
  result = o.a.data[0].int + o.b.data[0].int + o.s.len

var o: Outer
o.a.data[0] = 4
o.b.data[0] = 2
o.s = @[1, 2, 3]
echo use(o)
