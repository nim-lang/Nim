# Helper for tsecsrc.nim: confutils `load` / `generateSecondarySources` pattern.
# A macro introduces a type named `SecondarySources` into a template expansion
# so the caller's untyped callback can mention that type.

import std/macros

macro generateSecondarySources*(ConfType: typedesc): untyped =
  let CF = ident "SecondarySources"
  result = quote do:
    type
      `CF` = object
        data*: int
    (ref `CF`)()

template load*(Configuration: typedesc, secondarySources: untyped): untyped =
  block:
    let secondarySourcesRef = generateSecondarySources(Configuration)
    secondarySources(default(Configuration), secondarySourcesRef)
    secondarySourcesRef.data
