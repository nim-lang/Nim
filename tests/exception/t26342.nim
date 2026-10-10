discard """
  matrix: "--mm:orc --panics:on; --mm:orc; --mm:refc"
  output: '''
false
false
false
'''
"""

# bug #26342: a call through a generic proc-type alias must keep the
# goto-exception check after it.

type
  GenericCallback[T] = proc(value: T)
  AliasCallback = GenericCallback[int]
  GenericClosure[T] = proc(value: T) {.closure, raises: [CatchableError].}

var continued = false

proc invoke[T](callback: GenericCallback[T], value: T) =
  callback(value)
  continued = true

proc invokeAlias(callback: AliasCallback, value: int) =
  callback(value)
  continued = true

proc invokeClosure[T](callback: GenericClosure[T], value: T) =
  callback(value)
  continued = true

proc fail(value: int) =
  raise newException(ValueError, "boom")

proc failC(value: int) {.raises: [CatchableError].} =
  raise newException(ValueError, "boom")

try:
  invoke[int](fail, 0)
except ValueError:
  discard
echo continued

try:
  invokeAlias(fail, 0)
except ValueError:
  discard
echo continued

try:
  invokeClosure[int](failC, 0)
except ValueError:
  discard
echo continued
