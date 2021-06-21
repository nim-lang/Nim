discard """
  cmd: '''nim c --styleCheck:hint $file'''
  nimout: '''
tlinter.nim(21, 14) Hint: 'nosideeffect' should be: 'noSideEffect' [Name]
tlinter.nim(21, 28) Hint: 'myown' should be: 'myOwn' [template declared in tlinter.nim(19, 9)] [Name]
tlinter.nim(21, 35) Hint: 'inLine' should be: 'inline' [Name]
tlinter.nim(25, 1) Hint: 'tyPE' should be: 'type' [Name]
tlinter.nim(23, 1) Hint: 'foO' should be: 'foo' [proc declared in tlinter.nim(21, 6)] [Name]
tlinter.nim(27, 14) Hint: 'Foo_bar' should be: 'FooBar' [type declared in tlinter.nim(25, 6)] [Name]
tlinter.nim(29, 6) Hint: 'someVAR' should be: 'someVar' [var declared in tlinter.nim(27, 5)] [Name]
tlinter.nim(32, 7) Hint: 'i_fool' should be: 'iFool' [Name]
tlinter.nim(39, 5) Hint: 'meh_field' should be: 'mehField' [Name]
'''
  action: "compile"
"""



{.pragma: myOwn.}

proc foo() {.nosideeffect, myown, inLine.} = debugEcho "hi"

foO()

tyPE FooBar = string

var someVar: Foo_bar = "a"

echo someVAR

proc main =
  var i_fool = 34
  echo i_fool

main()

type
  Foo = object
    meh_field: int

