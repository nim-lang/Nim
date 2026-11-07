import ../timport_as as t {.cyclic.}
import sub/mimport_as2 as other {.all.}

proc fb*(): int = t.fa() + 1
proc hiddenB*(): int = other.hidden()
