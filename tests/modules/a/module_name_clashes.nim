# See `tmodule_name_clashes`

import ../b/module_name_clashes
type A* = object
  b*: B

proc print*(a: A) =
  echo repr a
