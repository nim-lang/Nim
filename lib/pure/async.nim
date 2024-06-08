## Exports [asyncmacro](asyncmacro.html) and [asyncfutures](asyncfutures.html) for native backends,
## and [asyncjs](asyncjs.html) on the JS backend. 

when defined(js):
  import std/asyncjs
  export asyncjs
else:
  import std/[asyncmacro, asyncfutures]
  export asyncmacro, asyncfutures
