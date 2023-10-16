discard """
  targets: "cpp"
  cmd: "nim cpp $file"
  output: '''
'''
"""
{.emit: """/*TYPESECTION*/
  struct Foo {
    Foo(int a){};
  };
  struct Boo {
    Boo(int a){};
  };

  """.}

type 
  Foo {.importcpp.} = object
  Boo {.importcpp, noInit.} = object
  Test {.exportc.} = object
    foo {.noInit.}: Foo
    boo: Boo

proc makeTest(): Test {.constructor: "Test() : foo(10), boo(1)".} = 
  discard

proc main() = 
  var t = makeTest()

main()