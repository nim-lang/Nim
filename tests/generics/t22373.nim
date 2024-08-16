# issue #22373

import m22373a
import m22373b

# original:
template lazy_header(name: untyped): untyped {.dirty.} =
  var `name _ ptr`: ptr[data_fork.LightClientHeader]  # this data_fork.Foo part seems required to reproduce
proc createLightClientUpdates(data_fork: static LightClientDataFork) =
  lazy_header(attested_header)
createLightClientUpdates(LightClientDataFork.Altair)

# simplified:
proc generic[T](abc: T) =
  var x: abc.TypeOrTemplate
generic(123)
