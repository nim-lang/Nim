# Helper for toptfield.nim: protobuf.Register-shaped type — exported Opt field
# with custom pragmas, accessed from a generic via `.get`, instantiated through
# another generic that also has a parameter named `ttl` (the nimbus advertise
# / save collision).

template proto2() {.pragma.}
template fieldNumber(n: int) {.pragma.}
template pint() {.pragma.}

type
  Opt*[T] = object
    val: T
    has: bool

proc some*[T](v: T): Opt[T] = Opt[T](val: v, has: true)

func get*[T](self: Opt[T], otherwise: T): T =
  if self.has: self.val else: otherwise

type
  Register* {.proto2.} = object
    ns* {.fieldNumber: 1.}: string
    ttl* {.fieldNumber: 3, pint.}: Opt[uint64]

proc save*[E](r: Register, x: E): uint64 =
  r.ttl.get(0)

proc advertise*[E](r: Register, ttl: Opt[uint64], x: E): uint64 =
  save(r, x)
