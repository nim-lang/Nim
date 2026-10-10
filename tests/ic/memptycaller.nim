# Calls `emptyOwned` from a DIFFERENT module than the one that owns it, so the
# reference at link time must resolve to a definition the owning module emits.

import memptyowned

proc callEmpty*(cond: bool) =
  if cond:
    emptyOwned()
  echo "called ", cond
