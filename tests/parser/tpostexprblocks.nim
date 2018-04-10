discard """
nimout: '''
StmtList
  Ident ident"foo010"
  Call
    Ident ident"foo020"
  Call
    Ident ident"foo030"
    Ident ident"x"
  Command
    Ident ident"foo040"
    Ident ident"x"
  Call
    Ident ident"foo050"
    StmtList
      DiscardStmt
        Empty
  Call
    Ident ident"foo060"
    StmtList
      DiscardStmt
        Empty
  Call
    Ident ident"foo070"
    StrLit "test"
    StmtList
      DiscardStmt
        Empty
  Call
    Ident ident"foo080"
    StrLit "test"
    StmtList
      DiscardStmt
        Empty
  Command
    Ident ident"foo090"
    StrLit "test"
    StmtList
      DiscardStmt
        Empty
  Command
    Ident ident"foo100"
    Call
      StrLit "test"
      StmtList
        DiscardStmt
          Empty
  Command
    Ident ident"foo101"
    Call
      IntLit 10
      StmtList
        DiscardStmt
          Empty
  Command
    Ident ident"foo110"
    IntLit 1
    Par
      Infix
        Ident ident"+"
        IntLit 2
        IntLit 3
    StmtList
      DiscardStmt
        Empty
  Command
    Ident ident"foo120"
    IntLit 1
    Call
      Par
        Infix
          Ident ident"+"
          IntLit 2
          IntLit 3
      StmtList
        DiscardStmt
          Empty
  Call
    Ident ident"foo130"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Empty
        IdentDefs
          Ident ident"x"
          Empty
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Call
    Ident ident"foo140"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Empty
        IdentDefs
          Ident ident"x"
          Ident ident"int"
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Call
    Ident ident"foo150"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Ident ident"int"
        IdentDefs
          Ident ident"x"
          Ident ident"int"
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Command
    Ident ident"foo160"
    Call
      Ident ident"x"
      Do
        Empty
        Empty
        Empty
        FormalParams
          Empty
          IdentDefs
            Ident ident"y"
            Empty
            Empty
        Empty
        Empty
        StmtList
          DiscardStmt
            Empty
  Call
    Ident ident"foo170"
    StmtList
      DiscardStmt
        Empty
    Else
      StmtList
        DiscardStmt
          Empty
  Call
    Ident ident"foo180"
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
    Ident ident"foo190"
    Call
      Ident ident"x"
      Do
        Empty
        Empty
        Empty
        FormalParams
          Empty
          IdentDefs
            Ident ident"y"
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
          Ident ident"int"
          IdentDefs
            Ident ident"z"
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
          Ident ident"int"
          IdentDefs
            Ident ident"w"
            Ident ident"int"
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
    Ident ident"foo200"
    Ident ident"x"
    Call
      Ident ident"bar"
      StmtList
        DiscardStmt
          Empty
      Else
        StmtList
          DiscardStmt
            Empty
  VarSection
    IdentDefs
      Ident ident"a"
      Empty
      Ident ident"foo210"
  VarSection
    IdentDefs
      Ident ident"a"
      Empty
      Call
        Ident ident"foo220"
  VarSection
    IdentDefs
      Ident ident"a"
      Empty
      Call
        Ident ident"foo230"
        Ident ident"x"
  VarSection
    IdentDefs
      Ident ident"a"
      Empty
      Command
        Ident ident"foo240"
        Ident ident"x"
  VarSection
    IdentDefs
      Ident ident"a"
      Empty
      Call
        Ident ident"foo250"
        StmtList
          DiscardStmt
            Empty
  VarSection
    IdentDefs
      Ident ident"a"
      Empty
      Call
        Ident ident"foo260"
        StmtList
          DiscardStmt
            Empty
  VarSection
    IdentDefs
      Ident ident"a"
      Empty
      Call
        Ident ident"foo270"
        StmtList
          DiscardStmt
            Empty
        Else
          StmtList
            DiscardStmt
              Empty
  VarSection
    IdentDefs
      Ident ident"a"
      Empty
      Command
        Ident ident"foo280"
        Call
          Ident ident"x"
          Do
            Empty
            Empty
            Empty
            FormalParams
              Empty
              IdentDefs
                Ident ident"y"
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
    Ident ident"a"
    Ident ident"foo290"
  Asgn
    Ident ident"a"
    Call
      Ident ident"foo300"
  Asgn
    Ident ident"a"
    Call
      Ident ident"foo310"
      Ident ident"x"
  Asgn
    Ident ident"a"
    Command
      Ident ident"foo320"
      Ident ident"x"
  Asgn
    Ident ident"a"
    Call
      Ident ident"foo330"
      StmtList
        DiscardStmt
          Empty
  Asgn
    Ident ident"a"
    Call
      Ident ident"foo340"
      StmtList
        DiscardStmt
          Empty
  Asgn
    Ident ident"a"
    Call
      Ident ident"foo350"
      StmtList
        DiscardStmt
          Empty
      Else
        StmtList
          DiscardStmt
            Empty
  Asgn
    Ident ident"a"
    Command
      Ident ident"foo360"
      Call
        DotExpr
          Ident ident"x"
          Ident ident"bar"
        Do
          Empty
          Empty
          Empty
          FormalParams
            Empty
            IdentDefs
              Ident ident"y"
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
  Command
    DotExpr
      Ident ident"foo370"
      Ident ident"add"
    Call
      Ident ident"quote"
      StmtList
        DiscardStmt
          Empty
  Call
    DotExpr
      Ident ident"foo380"
      Ident ident"add"
    BracketExpr
      Call
        Ident ident"quote"
        StmtList
          DiscardStmt
            Empty
      IntLit 0
'''
"""

import macros

dumpTree:
  # simple calls
  foo010
  foo020()
  foo030(x)
  foo040 x

  foo050:
    discard

  foo060 do:
    discard

  foo070("test"):
    discard

  foo080("test") do:
    discard

  foo090 "test":
    discard

  foo100 "test" do:
    discard

  foo101 10 do:
    discard

  # more complicated calls
  foo110 1, (2+3):
    discard

  foo120 1, (2+3) do:
    discard

  foo130 do (x):
    discard

  foo140 do (x: int):
    discard

  foo150 do (x: int) -> int:
    discard

  foo160 x do (y):
    discard

  # extra blocks
  foo170:
    discard
  else:
    discard

  foo180 do:
    discard
  do:
    discard
  else:
    discard

  foo190 x do (y):
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
  foo200(x, bar do:
    discard
  else:
    discard
  )

  # introduce a variable
  var a = foo210
  var a = foo220()
  var a = foo230(x)
  var a = foo240 x

  var a = foo250:
    discard

  var a = foo260 do:
    discard

  var a = foo270 do:
    discard
  else:
    discard

  var a = foo280 x do (y):
    discard
  else:
    discard

  # assignments
  a = foo290
  a = foo300()
  a = foo310(x)
  a = foo320 x

  a = foo330:
    discard

  a = foo340 do:
    discard

  a = foo350 do:
    discard
  else:
    discard

  a = foo360 x.bar do (y):
    discard
  else:
    discard

  foo370.add quote do:
    discard

  # some edge cases
  foo380.add((quote do:
    discard
  )[0])
