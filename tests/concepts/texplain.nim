discard """
  cmd: "nim c --verbosity:0 --colors:off $file"
  nimout: '''
tests/concepts/texplain.nim(71, 10) Hint: Non-matching candidates for e(y)
proc e(i: int): int
 [User]
tests/concepts/texplain.nim(74, 7) Hint: Non-matching candidates for e(10)
proc e[ExplainedConcept](o: ExplainedConcept): int
tests/concepts/texplain.nim(38, 6) Error: undeclared field: 'foo'
tests/concepts/texplain.nim(38, 6) Error: undeclared field: '.'
tests/concepts/texplain.nim(38, 6) Error: type mismatch: got (
 [User]
tests/concepts/texplain.nim(77, 10) Hint: Non-matching candidates for e(10)
proc e[ExplainedConcept](o: ExplainedConcept): int
tests/concepts/texplain.nim(38, 6) Error: undeclared field: 'foo'
tests/concepts/texplain.nim(38, 6) Error: undeclared field: '.'
tests/concepts/texplain.nim(38, 6) Error: type mismatch: got (
 [User]
tests/concepts/texplain.nim(81, 20) Error: type mismatch: got (
tests/concepts/texplain.nim(82, 20) Error: type mismatch: got (
tests/concepts/texplain.nim(83, 20) Hint: Non-matching candidates for r(y)
proc r(i: string): int
 [User]
tests/concepts/texplain.nim(91, 2) Error: type mismatch: got (MatchingType)
but expected one of: 
proc f[NestedConcept](o: NestedConcept)
tests/concepts/texplain.nim(42, 6) Error: undeclared field: 'foo'
tests/concepts/texplain.nim(42, 6) Error: undeclared field: '.'
tests/concepts/texplain.nim(42, 6) Error: type mismatch: got (
tests/concepts/texplain.nim(46, 5) Error: type class predicate failed
'''
  line: 46
  errormsg: "type class predicate failed"
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

