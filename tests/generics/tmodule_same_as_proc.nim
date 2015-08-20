
# bug #1965

import mmodule_same_as_proc

proc test[T](t: T) =
  mmodule_same_as_proc"a"

test(0)
