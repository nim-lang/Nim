discard """
  cmd: '''nim c --styleCheck:warning --hints:off $file'''
  nimout: '''
tlinter_warnings.nim(25, 1) Warning: 'tyPE' should be: 'type' [User]
tlinter_warnings.nim(21, 14) Warning: 'nosideeffect' should be: 'noSideEffect' [User]
tlinter_warnings.nim(21, 28) Warning: 'myown' should be: 'myOwn' [template declared in tlinter_warnings.nim(19, 9)] [User]
tlinter_warnings.nim(21, 35) Warning: 'inLine' should be: 'inline' [User]
tlinter_warnings.nim(23, 1) Warning: 'foO' should be: 'foo' [proc declared in tlinter_warnings.nim(21, 6)] [User]
tlinter_warnings.nim(27, 14) Warning: 'Foo_bar' should be: 'FooBar' [type declared in tlinter_warnings.nim(25, 6)] [User]
tlinter_warnings.nim(29, 6) Warning: 'someVAR' should be: 'someVar' [var declared in tlinter_warnings.nim(27, 5)] [User]
tlinter_warnings.nim(32, 7) Warning: 'i_fool' should be: 'iFool' [User]
tlinter_warnings.nim(39, 5) Warning: 'meh_field' should be: 'mehField' [User]
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

