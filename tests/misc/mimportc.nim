#[
this test will grow with more importc+importcpp tests; see driver in trunner.nim
]#

{.emit:"""
struct A {
  static int fun0(int a){
    return a;
  }
  static int& fun1(int& a){
    return a;
  }
};
""".}

proc fun0*(a: cint): int {.importcpp:"A::$1(@)".}
proc fun1*(a: var cint): var int {.importcpp:"A::$1(@)".} =
  ## some comment; this test is for #14314
  runnableExamples: discard

proc main()=
  var a = 10.cint
  doAssert fun0(a) == a
  doAssert fun1(a).addr == a.addr
  echo "witness"
main()
