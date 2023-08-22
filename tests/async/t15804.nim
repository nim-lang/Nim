import asyncdispatch

type
  Foo*[E] = ref object 
    op: proc(): Future[bool] {.gcsafe.}

proc newFoo*[E](): Foo[E] =
  result = Foo[E]()
  result.op = proc(): Future[bool] {.gcsafe,async.} =
    await sleepAsync(100)
    result = false

when isMainModule:
  let f = newFoo[int]()
  echo waitFor f.op()
