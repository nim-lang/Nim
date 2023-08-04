type
  Task*[N: int] = object
    env*: array[N, byte]

var task14193: Task[20]
doAssert task14193.env.len == 20
