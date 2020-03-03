discard ""
type
   TObj = ref object

{.experimental: "notnil".}

proc check(a: TObj not nil) =
  echo repr(a)

proc doit() =
   var x : array[0..1, TObj]

   if x[0] != nil:
      check(x[0])

doit()

# bug #2352

proc p(x: proc() {.noconv.} not nil) = discard
p(proc() {.noconv.} = discard)
# Error: cannot prove 'proc () {.noconv.} = discard ' is not nil
