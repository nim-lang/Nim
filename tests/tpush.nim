# test the new pragmas

import
  io

{.push warnings: off, hints: off.}
proc noWarning() =
  var
    x: int
  echo(x)

{.pop.}

proc WarnMe() =
  var
    x: int
  echo(x)

