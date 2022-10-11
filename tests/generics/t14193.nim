type
  Task*[N: int] = object
    ## Tasks are simple closures that are sent by shared-memory channels
    ## In the future, if Nim built-in closures become threadsafe
    ## they can be used directly instead.
    fn*: proc(env: pointer) {.nimcall.}
    env*: array[N, byte]

var task14193: Task[20]
doAssert task14193.env.len == 20