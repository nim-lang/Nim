## Exports [asyncmacro](asyncmacro.html) and [asyncfutures](asyncfutures.html) for native backends,
## and [asyncjs](asyncjs.html) on the JS backend. 

when defined(js):
  import asyncjs
  export asyncjs
else:
  import asyncmacro, asyncfutures
  export asyncmacro, asyncfutures
