type 
  PA[T] = ref TA[T]
  TA[T] = object
    field: T
var a: PA[string]
new(a)
a.field = "some string"


proc someOther[T](len: string): seq[T] = discard
proc someOther[T](len: int): seq[T] = echo "we"

proc foo[T](x: T) =
  var s = someOther[T](34)
  #newSeq[T](34)

foo 23



when false:
  # Compiles unless you use var a: PA[string]
  type 
    PA = ref TA
    TA[T] = object


  # Cannot instantiate:
  type 
    TA[T] = object
      a: PA[T]
    PA[T] = ref TA[T]

  type 
    PA[T] = ref TA[T]
    TA[T] = object


