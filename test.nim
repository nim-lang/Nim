type
  RpcResponse*[T] = ref object
    result*: T

func testit[T](p: var ref T) =
  p = new(T)

when isMainModule:
  var v: RpcResponse[string]
  testit(v)
