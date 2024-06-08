discard """
  cmd: "nim c --verbosity:0 --colors:off $file"
  nimout: '''
texplain.nim(162, 10) Hint: Non-matching candidates for e(y)
proc e(i: int): int
  first type mismatch at position: 1
  required type for i: int
  but expression 'y' is of type: MatchingType

texplain.nim(165, 7) Hint: Non-matching candidates for e(10)
proc e(o: ExplainedConcept): int
  first type mismatch at position: 1
  required type for o: ExplainedConcept
  but expression '10' is of type: int literal(10)
texplain.nim(128, 6) ExplainedConcept: undeclared field: 'foo'
texplain.nim(128, 5) ExplainedConcept: concept predicate failed
texplain.nim(129, 6) ExplainedConcept: undeclared field: 'bar'
texplain.nim(128, 5) ExplainedConcept: concept predicate failed

texplain.nim(168, 10) Hint: Non-matching candidates for e(10)
proc e(o: ExplainedConcept): int
  first type mismatch at position: 1
  required type for o: ExplainedConcept
  but expression '10' is of type: int literal(10)
texplain.nim(128, 6) ExplainedConcept: undeclared field: 'foo'
texplain.nim(128, 5) ExplainedConcept: concept predicate failed
texplain.nim(129, 6) ExplainedConcept: undeclared field: 'bar'
texplain.nim(128, 5) ExplainedConcept: concept predicate failed

texplain.nim(172, 20) Error: type mismatch: got <NonMatchingType>
but expected one of:
proc e(i: int): int
  first type mismatch at position: 1
  required type for i: int
  but expression 'n' is of type: NonMatchingType
proc e(o: ExplainedConcept): int
  first type mismatch at position: 1
  required type for o: ExplainedConcept
  but expression 'n' is of type: NonMatchingType
texplain.nim(172, 9) template/generic instantiation of `assert` from here
texplain.nim(128, 5) ExplainedConcept: concept predicate failed

expression: e(n)
texplain.nim(173, 20) Error: type mismatch: got <NonMatchingType>
but expected one of:
proc r(i: string): int
  first type mismatch at position: 1
  required type for i: string
  but expression 'n' is of type: NonMatchingType
proc r(o: RegularConcept): int
  first type mismatch at position: 1
  required type for o: RegularConcept
  but expression 'n' is of type: NonMatchingType
texplain.nim(173, 9) template/generic instantiation of `assert` from here
texplain.nim(132, 5) RegularConcept: concept predicate failed
proc r[T](a: SomeNumber; b: T; c: auto)
  first type mismatch at position: 1
  required type for a: SomeNumber
  but expression 'n' is of type: NonMatchingType

expression: r(n)
texplain.nim(174, 20) Hint: Non-matching candidates for r(y)
proc r(i: string): int
  first type mismatch at position: 1
  required type for i: string
  but expression 'y' is of type: MatchingType
proc r[T](a: SomeNumber; b: T; c: auto)
  first type mismatch at position: 1
  required type for a: SomeNumber
  but expression 'y' is of type: MatchingType

texplain.nim(182, 2) Error: type mismatch: got <MatchingType>
but expected one of:
proc f(o: NestedConcept)
  first type mismatch at position: 1
  required type for o: NestedConcept
  but expression 'y' is of type: MatchingType
texplain.nim(132, 6) RegularConcept: undeclared field: 'foo'
texplain.nim(132, 5) RegularConcept: concept predicate failed
texplain.nim(133, 6) RegularConcept: undeclared field: 'bar'
texplain.nim(132, 5) RegularConcept: concept predicate failed
texplain.nim(136, 5) NestedConcept: concept predicate failed

expression: f(y)'''
  errormsg: "type mismatch: got <MatchingType>"
"""



# proc r[T](a: SomeNumber; b: T; c: auto)
# proc r(i: string): int
# proc r(o: RegularConcept): int































# line 124 HERE

type
  ExplainedConcept {.explain.} = concept o
    o.foo is int
    o.bar is string

  RegularConcept = concept o
    o.foo is int
    o.bar is string

  NestedConcept = concept o
    o.foo is RegularConcept

  NonMatchingType = object
    foo: int
    bar: int

  MatchingType = object
    foo: int
    bar: string

proc e(o: ExplainedConcept): int = 1
proc e(i: int): int = i

proc r[T](a: SomeNumber, b: T, c: auto) = discard
proc r(o: RegularConcept): int = 1
proc r(i: string): int = 1

proc f(o: NestedConcept) = discard

var n = NonMatchingType(foo: 10, bar: 20)
var y = MatchingType(foo: 10, bar: "bar")

# no diagnostic here:
discard e(y)

# explain that e(int) doesn't match
discard e(y) {.explain.}

# explain that e(ExplainedConcept) doesn't match
echo(e(10) {.explain.}, 20)

# explain that e(ExplainedConcept) doesn't again
discard e(10)

static:
  # provide diagnostics why the compile block failed
  assert(compiles(e(n)) {.explain.} == false)
  assert(compiles(r(n)) {.explain.} == false)
  assert(compiles(r(y)) {.explain.} == true)

  # these should not produce any output
  assert(compiles(r(10)) == false)
  assert(compiles(e(10)) == true)

# finally, provide multiple nested explanations for failed matching
# of regular concepts, even when the explain pragma is not used
f(y)
