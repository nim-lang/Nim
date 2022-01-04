discard """
nimout: '''
StmtList
  TypeSection
    TypeDef
      Ident "A"
      Empty
      Call
        Ident "call"
        IntLit 1
  TypeSection
    TypeDef
      Ident "B"
      Empty
      Command
        Ident "call"
        IntLit 2
    TypeDef
      Ident "C"
      Empty
      Call
        Ident "call"
        StmtList
          IntLit 3
    TypeDef
      Ident "D"
      Empty
      Call
        Ident "call"
        StmtList
          IntLit 4
  TypeSection
    TypeDef
      Ident "E"
      Empty
      Call
        Ident "call"
        IntLit 5
        IntLit 6
    TypeDef
      Ident "F"
      Empty
      Command
        Ident "call"
        IntLit 7
        IntLit 8
    TypeDef
      Ident "G"
      Empty
      Call
        Ident "call"
        IntLit 9
        StmtList
          IntLit 10
    TypeDef
      Ident "H"
      Empty
      Call
        Ident "call"
        IntLit 11
        StmtList
          IntLit 12
    TypeDef
      Ident "I"
      Empty
      Command
        Ident "call"
        IntLit 13
        StmtList
          IntLit 14
    TypeDef
      Ident "J"
      Empty
      Command
        Ident "call"
        IntLit 15
        StmtList
          IntLit 16
  TypeSection
    TypeDef
      Ident "K"
      Empty
      Call
        Ident "call"
        IntLit 17
        IntLit 18
        IntLit 19
    TypeDef
      Ident "L"
      Empty
      Command
        Ident "call"
        IntLit 20
        IntLit 21
        IntLit 22
    TypeDef
      Ident "M"
      Empty
      Call
        Ident "call"
        IntLit 23
        IntLit 24
        StmtList
          IntLit 25
    TypeDef
      Ident "N"
      Empty
      Command
        Ident "call"
        IntLit 26
        IntLit 27
        StmtList
          IntLit 28
    TypeDef
      Ident "O"
      Empty
      Command
        Ident "call"
        IntLit 29
        IntLit 30
        StmtList
          IntLit 31
  TypeSection
    TypeDef
      Ident "P"
      Empty
      Command
        Ident "call"
        TupleConstr
          IntLit 32
          IntLit 33
        Infix
          Ident "+"
          Infix
            Ident "*"
            IntLit 34
            IntLit 35
          IntLit 36
        StmtList
          IntLit 37
    TypeDef
      Ident "R"
      Empty
      Command
        Ident "call"
        Infix
          Ident "@"
          TupleConstr
            IntLit 38
            IntLit 39
          Infix
            Ident "shl"
            IntLit 40
            IntLit 41
        Infix
          Ident "-"
          Infix
            Ident "*"
            IntLit 42
            IntLit 43
          IntLit 44
        StmtList
          IntLit 45
    TypeDef
      Ident "S"
      Empty
      Command
        Ident "call"
        IntLit 46
        StmtList
          IntLit 47
        StmtList
          IntLit 48
    TypeDef
      Ident "T"
      Empty
      Call
        Ident "call"
        StmtList
          IntLit 49
        StmtList
          IntLit 50
        StmtList
          IntLit 51
a: IntLit 1
a: IntLit 2
a: StmtList
  IntLit 3
a: StmtList
  IntLit 4
a: IntLit 5
b: IntLit 6
a: IntLit 7
b: IntLit 8
a: IntLit 9
b: StmtList
  IntLit 10
a: IntLit 11
b: StmtList
  IntLit 12
a: IntLit 13
b: StmtList
  IntLit 14
a: IntLit 15
b: StmtList
  IntLit 16
a: IntLit 17
b: IntLit 18
c: IntLit 19
a: IntLit 20
b: IntLit 21
c: IntLit 22
a: IntLit 23
b: IntLit 24
c: StmtList
  IntLit 25
a: IntLit 26
b: IntLit 27
c: StmtList
  IntLit 28
a: IntLit 29
b: IntLit 30
c: StmtList
  IntLit 31
a: TupleConstr
  IntLit 32
  IntLit 33
b: Infix
  Ident "+"
  Infix
    Ident "*"
    IntLit 34
    IntLit 35
  IntLit 36
c: StmtList
  IntLit 37
a: Infix
  Ident "@"
  TupleConstr
    IntLit 38
    IntLit 39
  Infix
    Ident "shl"
    IntLit 40
    IntLit 41
b: Infix
  Ident "-"
  Infix
    Ident "*"
    IntLit 42
    IntLit 43
  IntLit 44
c: StmtList
  IntLit 45
a: IntLit 46
b: StmtList
  IntLit 47
c: StmtList
  IntLit 48
a: StmtList
  IntLit 49
b: StmtList
  IntLit 50
c: StmtList
  IntLit 51
'''
"""
import macros

macro call(a): untyped =
  echo "a: ", a.treeRepr
  result = ident"int"
macro call(a, b): untyped =
  echo "a: ", a.treeRepr
  echo "b: ", b.treeRepr
  result = ident"int"
macro call(a, b, c): untyped =
  echo "a: ", a.treeRepr
  echo "b: ", b.treeRepr
  echo "c: ", c.treeRepr
  result = ident"int"

macro sections(x): untyped =
  echo x.treeRepr
  result = newStmtList(x)
  for ts in x:
    for td in ts:
      let t = td[0]
      result.add quote do:
        doAssert `t` is int

sections:
  type A = call(1)
  type
    B = call 2
    C = call: 3
    D = call(): 4
  type
    E = call(5, 6)
    F = call 7, 8
    G = call(9): 10
    H = call(11):
      12
    I = call 13: 14
    J = call 15:
      16
  type
    K = call(17, 18, 19)
    L = call 20, 21, 22
    M = call(23, 24): 25
    N = call 26, 27: 28
    O = call 29, 30:
      31
  type
    P = call (32, 33), 34 * 35 + 36:
      37
    R = call (38, 39) @ 40 shl 41, 42 * 43 - 44:
      45
    S = call 46:
      47
    do:
      48
    T = call:
      49
    do:
      50
    do:
      51
