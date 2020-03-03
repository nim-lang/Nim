discard """
  errormsg: "cannot prove 'x' is not nil"
"""

# bug #2216
{.experimental: "notnil".}

type
    A[T] = ref object
        x: int
        ud: T

proc good[T](p: A[T]) =
    discard

proc bad[T](p: A[T] not nil) =
    discard


proc go() =
    let s = A[int](x: 1)

    good(s)
    bad(s)
    var x: A[int]
    bad(x)

go()
