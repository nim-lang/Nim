discard """
  cmd: "nim c --verbosity:0 --colors:off $file"
  nimout: '''
tests/concepts/texplain.nim(99, 10) Hint: Non-matching candidates for e(y)
proc e(i: int): int

tests/concepts/texplain.nim(102, 7) Hint: Non-matching candidates for e(10)
proc e(o: ExplainedConcept): int
tests/concepts/texplain.nim(65, 6) ExplainedConcept: undeclared field: 'foo'
tests/concepts/texplain.nim(65, 6) ExplainedConcept: undeclared field: '.'
tests/concepts/texplain.nim(65, 6) ExplainedConcept: expression '.' cannot be called
tests/concepts/texplain.nim(65, 5) ExplainedConcept: type class predicate failed
tests/concepts/texplain.nim(66, 6) ExplainedConcept: undeclared field: 'bar'
tests/concepts/texplain.nim(66, 6) ExplainedConcept: undeclared field: '.'
tests/concepts/texplain.nim(66, 6) ExplainedConcept: expression '.' cannot be called
tests/concepts/texplain.nim(65, 5) ExplainedConcept: type class predicate failed

tests/concepts/texplain.nim(105, 10) Hint: Non-matching candidates for e(10)
proc e(o: ExplainedConcept): int
tests/concepts/texplain.nim(65, 6) ExplainedConcept: undeclared field: 'foo'
tests/concepts/texplain.nim(65, 6) ExplainedConcept: undeclared field: '.'
tests/concepts/texplain.nim(65, 6) ExplainedConcept: expression '.' cannot be called
tests/concepts/texplain.nim(65, 5) ExplainedConcept: type class predicate failed
tests/concepts/texplain.nim(66, 6) ExplainedConcept: undeclared field: 'bar'
tests/concepts/texplain.nim(66, 6) ExplainedConcept: undeclared field: '.'
tests/concepts/texplain.nim(66, 6) ExplainedConcept: expression '.' cannot be called
tests/concepts/texplain.nim(65, 5) ExplainedConcept: type class predicate failed

tests/concepts/texplain.nim(109, 20) Error: type mismatch: got (NonMatchingType)
but expected one of: 
proc e(o: ExplainedConcept): int
tests/concepts/texplain.nim(65, 5) ExplainedConcept: type class predicate failed
proc e(i: int): int

tests/concepts/texplain.nim(110, 20) Error: type mismatch: got (NonMatchingType)
but expected one of: 
proc r(o: RegularConcept): int
tests/concepts/texplain.nim(69, 5) RegularConcept: type class predicate failed
proc r[T](a: SomeNumber; b: T; c: auto)
proc r(i: string): int

tests/concepts/texplain.nim(111, 20) Hint: Non-matching candidates for r(y)
proc r[T](a: SomeNumber; b: T; c: auto)
proc r(i: string): int

tests/concepts/texplain.nim(119, 2) Error: type mismatch: got (MatchingType)
but expected one of: 
proc f(o: NestedConcept)
tests/concepts/texplain.nim(69, 6) RegularConcept: undeclared field: 'foo'
tests/concepts/texplain.nim(69, 6) RegularConcept: undeclared field: '.'
tests/concepts/texplain.nim(69, 6) RegularConcept: expression '.' cannot be called
tests/concepts/texplain.nim(69, 5) RegularConcept: type class predicate failed
tests/concepts/texplain.nim(70, 6) RegularConcept: undeclared field: 'bar'
tests/concepts/texplain.nim(70, 6) RegularConcept: undeclared field: '.'
tests/concepts/texplain.nim(70, 6) RegularConcept: expression '.' cannot be called
tests/concepts/texplain.nim(69, 5) RegularConcept: type class predicate failed
tests/concepts/texplain.nim(73, 5) NestedConcept: type class predicate failed
'''
  line: 119
  errormsg: "type mismatch: got (MatchingType)"
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

