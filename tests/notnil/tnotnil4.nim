discard ""
type
   TObj = ref object

proc check(a: TObj not nil) =
  echo repr(a)

proc doit() =
   var x : array[0..1, TObj]

   if x[0] != nil:
      check(x[0])

doit()