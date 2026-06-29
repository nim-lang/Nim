# Helper for tconverterreexport.nim: defines a converter that a consumer reaches
# only through a re-export chain (mconvbase <- mconvmid <- test). Models
# faststreams' `implicitDeref: InputStreamHandle -> InputStream`.
type
  Handle* = object
    x*: int
  Real* = object
    x*: int

converter toReal*(h: Handle): Real = Real(x: h.x)

type Reader* = object
  v: int

func init*(T: type Reader, r: Real): Reader = Reader(v: r.x + 100)
func readVal*(r: Reader): int = r.v
