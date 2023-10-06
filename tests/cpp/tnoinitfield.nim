discard """
  cmd: "nim cpp $file"
  output: '''
'''
"""
{.emit: """/*TYPESECTION*/
  struct Foo {
    Foo(int a){};

  };

  """.}

type 
  Foo {.importcpp.} = object
  Test {.exportc.} = object
    foo {.noInit.} : Foo

proc makeTest(): Test {.constructor: "Test() : foo(10)".} = 
  discard

proc main() = 
  var t = makeTest()

main()