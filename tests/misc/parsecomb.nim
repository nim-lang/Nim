discard """
  matrix: "--mm:arc; --mm:refc"
"""

type Input[T] = object
  toks: seq[T]
  index: int

type
  ResultKind* = enum rkSuccess, rkFailure
  Result*[T, O] = object
    case kind*: ResultKind
    of rkSuccess:
      output*: O
      input: Input[T]
    of rkFailure:
      nil

type
  Parser*[T, O] = proc (input: Input[T]): Result[T, O]

proc unit*[T, O](v: O): Parser[T, O] =
  result = proc (inp: Input[T]): Result[T, O] =
    Result[T, O](kind: rkSuccess, output: v, input: inp)

proc fail*[T, O](): Parser[T, O] =
  result = proc (inp: Input[T]): Result[T, O] =
    Result(kind: rkFailure)

method runInput[T, O](self: Parser[T, O], inp: Input[T]): Result[T, O] =
  # hmmm ..
  type tmp = proc (input: Input[T]): Result[T, O]
  # XXX: above needed for now, as without the `tmp` bit below, it compiles to invalid C.
  tmp(self)(inp)

proc run*[T, O](self: Parser[T, O], toks: seq[T]): Result[T, O] =
  self.runInput(Input[T](toks: toks, index: 0))

proc chain*[T, O1, O2](self: Parser[T, O1], nextp: proc (v: O1): Parser[T, O2]): Parser[T, O2] =
  result = proc (inp: Input[T]): Result[T, O2] =
    let r = self.runInput(inp)
    case r.kind:
    of rkSuccess:
      nextp(r.output).runInput(r.input)
    of rkFailure:
      Result[T, O2](kind: rkFailure)

method skip[T](self: Input[T], n: int): Input[T] {.base.} =
  Input[T](toks: self.toks, index: self.index + n)

proc pskip*[T](n: int): Parser[T, tuple[]] =
  result = proc (inp: Input[T]): Result[T, tuple[]] =
    if inp.index + n <= inp.toks.len:
      Result[T, tuple[]](kind: rkSuccess, output: (), input: inp.skip(n))
    else:
      Result[T, tuple[]](kind: rkFailure)

proc tok*[T](t: T): Parser[T, T] =
  result = proc (inp: Input[T]): Result[T, T] =
    if inp.index < inp.toks.len and inp.toks[inp.index] == t:
      pskip[T](1).then(unit[T, T](t)).runInput(inp)
    else:
      Result[T, T](kind: rkFailure)

proc `+`*[T, O](first: Parser[T, O], second: Parser[T, O]): Parser[T, O] =
  result = proc (inp: Input[T]): Result[T, O] =
    let r = first.runInput(inp)
    case r.kind
    of rkSuccess:
      r
    else:
      second.runInput(inp)

# end of primitives (definitions involving Parser(..))

proc map*[T, O1, O2](self: Parser[T, O1], p: proc (v: O1): O2): Parser[T, O2] =
  self.chain(proc (v: O1): Parser[T, O2] =
    unit[T, O2](p(v)))

proc then*[T, O1, O2](self: Parser[T, O1], next: Parser[T, O2]): Parser[T, O2] =
  self.chain(proc (v: O1): Parser[T, O2] =
    next)

proc `*`*[T, O1, O2](first: Parser[T, O1], second: Parser[T, O2]): Parser[T, (O1, O2)] =
  first.chain(proc (v1: O1): Parser[T, (O1, O2)] =
    second.map(proc (v2: O2): (O1, O2) =
      (v1, v2)))

proc repeat0*[T, O](inner: Parser[T, O]): Parser[T, seq[O]] =
  var nothing = unit[T, seq[O]](@[])
  inner.chain(proc(v: O): Parser[T, seq[O]] =
    repeat0(inner).map(proc(vs: seq[O]): seq[O] =
      @[v] & vs)) + nothing

proc repeat1*[T, O](inner: Parser[T, O]): Parser[T, seq[O]] =
  inner.chain(proc(v: O): Parser[T, seq[O]] =
    repeat0(inner).map(proc(vs: seq[O]): seq[O] =
      @[v] & vs))

proc leftRec*[T, O, A](inner: Parser[T, O], after: Parser[T, A], fold: proc(i: O, a: A): O): Parser[T, O] =
  (inner*repeat0(after)).map(proc(ias: (O, seq[A])): O =
    var (i, asx) = ias
    for a in asx:
      i = fold(i, a)
    i)

proc lazy*[T, O](inner: proc(): Parser[T, O]): Parser[T, O] =
  unit[T, tuple[]](()).chain(proc(v: tuple[]): Parser[T, O] =
    inner())
