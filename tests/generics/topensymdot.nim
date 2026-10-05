# the RHS of a dot expression can be wrapped in `nkOpenSym` by the generic
# prepass (e.g. a `x.T` type conversion expanded from a dirty template):
# the captured symbol (`hashes.Hash`, not in scope here) must be used when
# nothing is injected, while a symbol injected during instantiation still
# overrides it

{.experimental: "openSym".}

import mopensymdot

doAssert sizeof(usesCaptured(@[1, 2, 3])) == sizeof(int) # hashes.Hash
doAssert sizeof(usesInjected(@[1, 2, 3])) == 1           # injected uint8
