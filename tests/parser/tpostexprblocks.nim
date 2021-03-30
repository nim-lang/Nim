discard """
nimout: '''
StmtList
  Ident "foo010"
  Call
    Ident "foo020"
  Call
    Ident "foo030"
    Ident "x"
  Command
    Ident "foo040"
    Ident "x"
  Call
    Ident "foo050"
    StmtList
      DiscardStmt
        Empty
  Call
    Ident "foo060"
    StmtList
      DiscardStmt
        Empty
  Call
    Ident "foo070"
    StrLit "test"
    StmtList
      DiscardStmt
        Empty
  Call
    Ident "foo080"
    StrLit "test"
    StmtList
      DiscardStmt
        Empty
  Command
    Ident "foo090"
    StrLit "test"
    StmtList
      DiscardStmt
        Empty
  Command
    Ident "foo100"
    Call
      StrLit "test"
      StmtList
        DiscardStmt
          Empty
  Command
    Ident "foo101"
    Call
      IntLit 10
      StmtList
        DiscardStmt
          Empty
  Command
    Ident "foo110"
    IntLit 1
    Par
      Infix
        Ident "+"
        IntLit 2
        IntLit 3
    StmtList
      DiscardStmt
        Empty
  Command
    Ident "foo120"
    IntLit 1
    Call
      Par
        Infix
          Ident "+"
          IntLit 2
          IntLit 3
      StmtList
        DiscardStmt
          Empty
  Call
    Ident "foo130"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Empty
        IdentDefs
          Ident "x"
          Empty
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Call
    Ident "foo140"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Empty
        IdentDefs
          Ident "x"
          Ident "int"
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Call
    Ident "foo150"
    Do
      Empty
      Empty
      Empty
      FormalParams
        Ident "int"
        IdentDefs
          Ident "x"
          Ident "int"
          Empty
      Empty
      Empty
      StmtList
        DiscardStmt
          Empty
  Command
    Ident "foo160"
    Call
      Ident "x"
      Do
        Empty
        Empty
        Empty
        FormalParams
          Empty
          IdentDefs
            Ident "y"
            Empty
            Empty
        Empty
        Empty
        StmtList
          DiscardStmt
            Empty
  Call
    Ident "foo170"
    StmtList
      DiscardStmt
        Empty
    Else
      StmtList
        DiscardStmt
          Empty
  Call
    Ident "foo180"
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
    Ident "foo190"
    Call
      Ident "x"
      Do
        Empty
        Empty
        Empty
        FormalParams
          Empty
          IdentDefs
            Ident "y"
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
          Ident "int"
          IdentDefs
            Ident "z"
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
          Ident "int"
          IdentDefs
            Ident "w"
            Ident "int"
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
    Ident "foo200"
    Ident "x"
    Call
      Ident "bar"
      StmtList
        DiscardStmt
          Empty
      Else
        StmtList
          DiscardStmt
            Empty
  VarSection
    IdentDefs
      Ident "a"
      Empty
      Ident "foo210"
  VarSection
    IdentDefs
      Ident "a"
      Empty
      Call
        Ident "foo220"
  VarSection
    IdentDefs
      Ident "a"
      Empty
      Call
        Ident "foo230"
        Ident "x"
  VarSection
    IdentDefs
      Ident "a"
      Empty
      Command
        Ident "foo240"
        Ident "x"
  VarSection
    IdentDefs
      Ident "a"
      Empty
      Call
        Ident "foo250"
        StmtList
          DiscardStmt
            Empty
  VarSection
    IdentDefs
      Ident "a"
      Empty
      Call
        Ident "foo260"
        StmtList
          DiscardStmt
            Empty
  VarSection
    IdentDefs
      Ident "a"
      Empty
      Call
        Ident "foo270"
        StmtList
          DiscardStmt
            Empty
        Else
          StmtList
            DiscardStmt
              Empty
  VarSection
    IdentDefs
      Ident "a"
      Empty
      Command
        Ident "foo280"
        Call
          Ident "x"
          Do
            Empty
            Empty
            Empty
            FormalParams
              Empty
              IdentDefs
                Ident "y"
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
    Ident "a"
    Ident "foo290"
  Asgn
    Ident "a"
    Call
      Ident "foo300"
  Asgn
    Ident "a"
    Call
      Ident "foo310"
      Ident "x"
  Asgn
    Ident "a"
    Command
      Ident "foo320"
      Ident "x"
  Asgn
    Ident "a"
    Call
      Ident "foo330"
      StmtList
        DiscardStmt
          Empty
  Asgn
    Ident "a"
    Call
      Ident "foo340"
      StmtList
        DiscardStmt
          Empty
  Asgn
    Ident "a"
    Call
      Ident "foo350"
      StmtList
        DiscardStmt
          Empty
      Else
        StmtList
          DiscardStmt
            Empty
  Asgn
    Ident "a"
    Command
      Ident "foo360"
      Call
        DotExpr
          Ident "x"
          Ident "bar"
        Do
          Empty
          Empty
          Empty
          FormalParams
            Empty
            IdentDefs
              Ident "y"
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
      Ident "foo370"
      Ident "add"
    Call
      Ident "quote"
      StmtList
        DiscardStmt
          Empty
  Call
    DotExpr
      Ident "foo380"
      Ident "add"
    BracketExpr
      Call
        Ident "quote"
        StmtList
          DiscardStmt
            Empty
      IntLit 0
  Command
    Ident "foo390"
    Call
      Ident "x"
      Do
        Empty
        Empty
        Empty
        FormalParams
          Empty
          IdentDefs
            Ident "y"
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
          Ident "int"
          IdentDefs
            Ident "z"
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
          Ident "int"
          IdentDefs
            Ident "w"
            Ident "int"
            Empty
        Empty
        Empty
        StmtList
          DiscardStmt
            Empty
      StmtList
        DiscardStmt
          Empty
      OfBranch
        Ident "a"
        StmtList
          DiscardStmt
            Empty
      OfBranch
        TupleConstr
          Ident "a"
          Ident "b"
        StmtList
          DiscardStmt
            Empty
      ElifBranch
        Ident "a"
        StmtList
          DiscardStmt
            Empty
      ElifBranch
        TupleConstr
          Ident "a"
          Ident "b"
        StmtList
          DiscardStmt
            Empty
      ExceptBranch
        Ident "a"
        StmtList
          DiscardStmt
            Empty
      ExceptBranch
        TupleConstr
          Ident "a"
          Ident "b"
        StmtList
          DiscardStmt
            Empty
      Finally
        StmtList
          DiscardStmt
            Empty
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

  foo390 x do (y):
    discard
  do (z) -> int:
    discard
  do (w: int) -> int:
    discard
  do:
    discard
  of a:
    discard
  of (a, b):
    discard
  elif a:
    discard
  elif (a, b):
    discard
  except a:
    discard
  except (a, b):
    discard
  finally:
    discard
