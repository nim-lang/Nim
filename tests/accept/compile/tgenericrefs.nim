# Compiles:

type 
  TA[T] = object
  PA[T] = ref TA[T]
var a: PA[string]

# Compiles unless you use var a: PA[string]
type 
  PA = ref TA
  TA[T] = object


# Cannot instanciate:
type 
  TA[T] = object
    a: PA[T]
  PA[T] = ref TA[T]

type 
  PA[T] = ref TA[T]
  TA[T] = object


