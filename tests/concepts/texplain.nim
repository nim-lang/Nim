discard """
  cmd: "nim c --verbosity:0 --colors:off $file"
  nimout: '''
texplain.nim(103, 10) Hint: Non-matching candidates for e(y)
proc e(i: int): int

texplain.nim(106, 7) Hint: Non-matching candidates for e(10)
proc e(o: ExplainedConcept): int
texplain.nim(69, 6) ExplainedConcept: undeclared field: 'foo'
texplain.nim(69, 6) ExplainedConcept: undeclared field: '.'
texplain.nim(69, 6) ExplainedConcept: expression '.' cannot be called
texplain.nim(69, 5) ExplainedConcept: concept predicate failed
texplain.nim(70, 6) ExplainedConcept: undeclared field: 'bar'
texplain.nim(70, 6) ExplainedConcept: undeclared field: '.'
texplain.nim(70, 6) ExplainedConcept: expression '.' cannot be called
texplain.nim(69, 5) ExplainedConcept: concept predicate failed

texplain.nim(109, 10) Hint: Non-matching candidates for e(10)
proc e(o: ExplainedConcept): int
texplain.nim(69, 6) ExplainedConcept: undeclared field: 'foo'
texplain.nim(69, 6) ExplainedConcept: undeclared field: '.'
texplain.nim(69, 6) ExplainedConcept: expression '.' cannot be called
texplain.nim(69, 5) ExplainedConcept: concept predicate failed
texplain.nim(70, 6) ExplainedConcept: undeclared field: 'bar'
texplain.nim(70, 6) ExplainedConcept: undeclared field: '.'
texplain.nim(70, 6) ExplainedConcept: expression '.' cannot be called
texplain.nim(69, 5) ExplainedConcept: concept predicate failed

texplain.nim(113, 20) Error: type mismatch: got <NonMatchingType>
but expected one of:
proc e(o: ExplainedConcept): int
texplain.nim(69, 5) ExplainedConcept: concept predicate failed
proc e(i: int): int

expression: e(n)
texplain.nim(114, 20) Error: type mismatch: got <NonMatchingType>
but expected one of:
proc r(o: RegularConcept): int
texplain.nim(73, 5) RegularConcept: concept predicate failed
proc r[T](a: SomeNumber; b: T; c: auto)
proc r(i: string): int

expression: r(n)
texplain.nim(115, 20) Hint: Non-matching candidates for r(y)
proc r[T](a: SomeNumber; b: T; c: auto)
proc r(i: string): int

texplain.nim(123, 2) Error: type mismatch: got <MatchingType>
but expected one of:
proc f(o: NestedConcept)
texplain.nim(73, 6) RegularConcept: undeclared field: 'foo'
texplain.nim(73, 6) RegularConcept: undeclared field: '.'
texplain.nim(73, 6) RegularConcept: expression '.' cannot be called
texplain.nim(73, 5) RegularConcept: concept predicate failed
texplain.nim(74, 6) RegularConcept: undeclared field: 'bar'
texplain.nim(74, 6) RegularConcept: undeclared field: '.'
texplain.nim(74, 6) RegularConcept: expression '.' cannot be called
texplain.nim(73, 5) RegularConcept: concept predicate failed
texplain.nim(77, 5) NestedConcept: concept predicate failed

expression: f(y)
'''
  line: 123
  errormsg: "type mismatch: got <MatchingType>"
"""

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

