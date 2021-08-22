import macros

block TEST_1:
  # https://github.com/nim-lang/Nim/issues/11923

  type
    MyObj[T] = object
      test: Point[T]

    Point[T] = object
      x, y: T

  template testPragma {.pragma.}

  proc case1(x: var MyObj) =
    for k, v in fieldPairs(x):
      when v.hasCustomPragma(testPragma):
        echo("hi")

  proc case2(x: MyObj) =
    for k, v in fieldPairs(x):
      when v.hasCustomPragma(testPragma):
        echo("hi")

  var x = MyObj[float](test: Point[float](x: 1.3, y: 0.0))
  case2(x)
  case1(x)



block TEST_2:
  template myPragma(val: string) {.pragma.}
  template myPragma2(val: string) {.pragma.}

  type
    PKind = enum
      Player
    GKind = enum
      Game
    MyObj[T] = object of RootObj
      test: T
    BaseControls[T] {.myPragma: "Hallo".} = object of RootObj
      myObj: seq[MyObj[T]]

  assert BaseControls[PKind].hasCustomPragma(myPragma) == true
  assert BaseControls[GKind].hasCustomPragma(myPragma) == true
  assert BaseControls[PKind].hasCustomPragma(myPragma2) == false
  assert BaseControls[GKind].hasCustomPragma(myPragma2) == false



block TEST_3:
  template myPragma() {.pragma.}
  template myPragma2() {.pragma.}

  type
    PKind = enum
      Player

    GKind = enum
      Game

    MyObj[T] = object of RootObj
      test: T

    BaseControls[T] {.myPragma.} = object of RootObj
      myObj {.myPragma2.}: seq[MyObj[T]]

    ControlsDefaultGame = object of BaseControls[GKind]
    ControlsDefaultPlayer = object of BaseControls[PKind]

    Controls {.myPragma.} = object
      attrGame {.myPragma.}: ControlsDefaultGame
      attrPlayer {.myPragma.}: ControlsDefaultPlayer


  var controls: Controls
  for key1, val1 in controls.fieldPairs:
    assert val1.hasCustomPragma(myPragma) == true
    assert val1.hasCustomPragma(myPragma2) == false

    for key2, val2 in val1.fieldPairs:
      assert val2.hasCustomPragma(myPragma) == false
      assert val2.hasCustomPragma(myPragma2) == true
