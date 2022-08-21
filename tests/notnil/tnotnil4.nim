discard ""
type
   TObj = ref object

{.experimental: "notnil".}

proc check(a: TObj not nil) =
  echo repr(a)

proc doit() =
   var x : array[0..1, TObj]

   let y = x[0]
   if y != nil:
      check(y)

doit()

# bug #2352

proc p(x: proc() {.noconv.} not nil) = discard
p(proc() {.noconv.} = discard)
# Error: cannot prove 'proc () {.noconv.} = discard ' is not nil
