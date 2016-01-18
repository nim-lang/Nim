type
    TBinOp*[T] = proc (x,y: T): bool

    THeap*[T] = object
        cmp*:   TBinOp[T]

proc less*[T](x,y: T): bool =
    x < y

proc initHeap*[T](cmp: TBinOp[T]): THeap[T] =
    result.cmp = cmp

when isMainModule:
    var h = initHeap[int](less[int])

    echo h.cmp(2,3)