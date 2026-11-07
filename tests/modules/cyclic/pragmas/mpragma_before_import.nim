{.deprecated: "use something else".}
import ../tpragma_before_import {.cyclic.}

proc fb*(): int = fa() + 1
