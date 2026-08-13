# Helper for tasyncvar.nim: chronos-shaped `{.async.}` proc with a `var`
# parameter, nested as a closure iterator that mutates through the param.
# Under `nim ic` the lower stage transforms every owned routine (unlike `nim c`,
# which demand-drives codegen and can DCE an unused `stop`); capturing the
# `var` param must not illegalCapture.

type Mgr* = object
  x*: int
  done*: bool

proc stop*[T](self: var Mgr, _: T) =
  # Simulate the async-generated nested closure iterator that references `self`.
  proc stepper() {.closure.} =
    self.x = self.x + 1
    self.done = true
  stepper()
