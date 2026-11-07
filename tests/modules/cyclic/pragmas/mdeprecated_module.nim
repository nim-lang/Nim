{.deprecated: "use something else".}
import ../tdeprecated_module {.cyclic.}

proc fb*(): int = 2
proc fbb*(): int = fa()
