discard """
nimout: '''
StmtList
  Ident !"foo"
  Call
    Ident !"foo"
  Call
    Ident !"foo"
    Ident !"x"
  Command
    Ident !"foo"
    Ident !"x"
  Call
    Ident !"foo"
    StmtList
      DiscardStmt
        Empty
  Call
    Ident !"foo"
    StmtList
      DiscardStmt
        Empty
  Call
    Ident !"foo"
    StrLit test
    StmtList
      DiscardStmt
        Empty
  Call
    Ident !"foo"
    StrLit test
    StmtList
      DiscardStmt
        Empty
  Command
    Ident !"foo"
    StrLit test
    StmtList
      DiscardStmt
        Empty
  Command
    Ident !"foo"
    StrLit test
    StmtList
      DiscardStmt
        Empty
  Command
    Ident !"foo"
    IntLit 1
    Par
      Infix
        Ident !"+"
        IntLit 2
        IntLit 3
    StmtList
      DiscardStmt
        Empty
  Command
    Ident !"foo"
    IntLit 1
    Par
      Infix
        Ident !"+"
        IntLit 2
        IntLit 3
    StmtList
      DiscardStmt
        Empty
  Call
    Ident !"foo"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Empty
        IdentDefs
          Ident !"x"
          Empty
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Call
    Ident !"foo"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Empty
        IdentDefs
          Ident !"x"
          Ident !"int"
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Call
    Ident !"foo"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Ident !"int"
        IdentDefs
          Ident !"x"
          Ident !"int"
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Command
    Ident !"foo"
    Ident !"x"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Empty
        IdentDefs
          Ident !"y"
          Empty
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Call
    Ident !"foo"
    StmtList
      DiscardStmt
        Empty
    Else
      StmtList
        DiscardStmt
          Empty
  Call
    Ident !"foo"
    StmtList
      DiscardStmt
        Empty
    StmtList
      DiscardStmt
        Empty
    Else
      StmtList
        DiscardStmt
          Empty
  Command
    Ident !"foo"
    Ident !"x"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Empty
        IdentDefs
          Ident !"y"
          Empty
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
    Do
      Empty
      Empty
      Empty
      FormalParams
        Ident !"int"
        IdentDefs
          Ident !"z"
          Empty
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
    Do
      Empty
      Empty
      Empty
      FormalParams
        Ident !"int"
        IdentDefs
          Ident !"w"
          Ident !"int"
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
    StmtList
      DiscardStmt
        Empty
    Else
      StmtList
        DiscardStmt
          Empty
  Call
    Ident !"foo"
    Ident !"x"
    Call
      Ident !"bar"
      StmtList
        DiscardStmt
          Empty
      Else
        StmtList
          DiscardStmt
            Empty
  VarSection
    IdentDefs
      Ident !"a"
      Empty
      Ident !"foo"
  VarSection
    IdentDefs
      Ident !"a"
      Empty
      Call
        Ident !"foo"
  VarSection
    IdentDefs
      Ident !"a"
      Empty
      Call
        Ident !"foo"
        Ident !"x"
  VarSection
    IdentDefs
      Ident !"a"
      Empty
      Command
        Ident !"foo"
        Ident !"x"
  VarSection
    IdentDefs
      Ident !"a"
      Empty
      Call
        Ident !"foo"
        StmtList
          DiscardStmt
            Empty
  VarSection
    IdentDefs
      Ident !"a"
      Empty
      Call
        Ident !"foo"
        StmtList
          DiscardStmt
            Empty
  VarSection
    IdentDefs
      Ident !"a"
      Empty
      Call
        Ident !"foo"
        StmtList
          DiscardStmt
            Empty
        Else
          StmtList
            DiscardStmt
              Empty
  VarSection
    IdentDefs
      Ident !"a"
      Empty
      Command
        Ident !"foo"
        Ident !"x"
        Do
          Empty
          Empty
          Empty
          FormalParams
            Empty
            IdentDefs
              Ident !"y"
              Empty
              Empty
          Empty
          Empty
          StmtList
            DiscardStmt
              Empty
        Else
          StmtList
            DiscardStmt
              Empty
  Asgn
    Ident !"a"
    Ident !"foo"
  Asgn
    Ident !"a"
    Call
      Ident !"foo"
  Asgn
    Ident !"a"
    Call
      Ident !"foo"
      Ident !"x"
  Asgn
    Ident !"a"
    Command
      Ident !"foo"
      Ident !"x"
  Asgn
    Ident !"a"
    Call
      Ident !"foo"
      StmtList
        DiscardStmt
          Empty
  Asgn
    Ident !"a"
    Call
      Ident !"foo"
      StmtList
        DiscardStmt
          Empty
  Asgn
    Ident !"a"
    Call
      Ident !"foo"
      StmtList
        DiscardStmt
          Empty
      Else
        StmtList
          DiscardStmt
            Empty
  Asgn
    Ident !"a"
    Command
      Ident !"foo"
      Ident !"x"
      Do
        Empty
        Empty
        Empty
        FormalParams
          Empty
          IdentDefs
            Ident !"y"
            Empty
            Empty
        Empty
        Empty
        StmtList
          DiscardStmt
            Empty
      Else
        StmtList
          DiscardStmt
            Empty
  Call
    DotExpr
      Ident !"result"
      Ident !"add"
    BracketExpr
      Call
        Ident !"quote"
        StmtList
          DiscardStmt
            Empty
      IntLit 0
'''
"""

import macros

dumpTree:
  # simple calls
  foo
  foo()
  foo(x)
  foo x

  foo:
    discard

  foo do:
    discard

  foo("test"):
    discard

  foo("test") do:
    discard

  foo "test":
    discard

  foo "test" do:
    discard

  # more complicated calls
  foo 1, (2+3):
    discard

  foo 1, (2+3) do:
    discard

  foo do (x):
    discard

  foo do (x: int):
    discard

  foo do (x: int) -> int:
    discard

  foo x do (y):
    discard

  # extra blocks
  foo:
    discard
  else:
    discard

  foo do:
    discard
  do:
    discard
  else:
    discard

  foo x do (y):
    discard
  do (z) -> int:
    discard
  do (w: int) -> int:
    discard
  do:
    discard
  else:
    discard

  # call with blocks as a param
  foo(x, bar do:
    discard
  else:
    discard
  )

  # introduce a variable
  var a = foo
  var a = foo()
  var a = foo(x)
  var a = foo x

  var a = foo:
    discard

  var a = foo do:
    discard

  var a = foo do:
    discard
  else:
    discard

  var a = foo x do (y):
    discard
  else:
    discard

  # assignments
  a = foo
  a = foo()
  a = foo(x)
  a = foo x

  a = foo:
    discard

  a = foo do:
    discard

  a = foo do:
    discard
  else:
    discard

  a = foo x do (y):
    discard
  else:
    discard

  # some edge cases
  result.add((quote do:
    discard
  )[0])

