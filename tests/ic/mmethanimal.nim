# Helper for tmethitanium: the OWNER module of a `{.base.}` method. Its concrete
# base body is emitted here; the whole-program dispatcher is synthesized into the
# main module. Under `--debugger:native` the backend uses the Itanium mangling
# scheme, which encodes the signature instead of the `disamb`, so the base method
# and its same-signature dispatcher want the identical clean C name. The
# clean-vs-unique tie-break used to depend on a per-MODULE set (`mangledPrcs`),
# which the per-module IC backend cannot share — the base mangled clean at this
# owner but `speak_u<n>` (an unstable `itemId.item`) at every demander, so it was
# defined once and referenced under names nobody defined. See
# ccgutils.makeUnique (disamb, not itemId) + ccgtypes.fillBackendName.

type Animal* = ref object of RootObj

method speak*(a: Animal): string {.base.} =
  "generic-animal-sound"
