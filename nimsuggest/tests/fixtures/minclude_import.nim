# Creates an awkward set of dependencies between this, import, and include.
# This pattern appears in the compiler, compiler/(sem|ast|semexprs).nim.

import mfakeassert
import minclude_types

proc say*(g: Greet): string =
  fakeAssert(true, "always works")
  g.greeting & ", " & g.subject & "!"

include minclude_include

proc say*(): string =
  fakeAssert(1 + 1 == 2, "math works")
  say(create())
