discard """
  output: "true\n(y: XInt, a: 5)\n(y: XString, b: \"abc\")"
"""

import macros

block TEST_1:
  # https://github.com/nim-lang/Nim/issues/14511

  template myPragma() {.pragma.}

  type
    XType = enum
      XInt,
      XString,
      XUnused
    X = object
      case y {.myPragma.}: XType
        of XInt, XUnused:
          a: int
        else: # <-- Else case caused the "Error: index 1 not in 0 .. 0" error
          b: string

  var x: X = X(y: XInt, a: 5)
  echo x.y.hasCustomPragma(myPragma)
  echo x
  echo X(y: XString, b: "abc")


block TEST_2:
  template myDevice(val: string) {.pragma.}
  template myKey(val: string) {.pragma.}
  template myMouse(val: string) {.pragma.}

  type
    Device {.pure.} = enum Keyboard, Mouse
    Key = enum Key1, Key2
    Mouse = enum Mouse1, Mouse2

  type
    Obj = object of RootObj
      case device {.myDevice: "MyDevicePragmaStr".}: Device
      of Device.Keyboard:
        key {.myKey: "MyKeyPragmaStr".}: Key
      else: # <-- Else case caused the "Error: index 1 not in 0 .. 0" error
        mouse {.myMouse: "MyMousePragmaStr".}: Mouse

  var obj: Obj
  assert obj.device.hasCustomPragma(myDevice) == true
  assert obj.key.hasCustomPragma(myKey) == true
  assert obj.mouse.hasCustomPragma(myMouse) == true
  assert obj.device.getCustomPragmaVal(myDevice) == "MyDevicePragmaStr"
  assert obj.key.getCustomPragmaVal(myKey) == "MyKeyPragmaStr"
  assert obj.mouse.getCustomPragmaVal(myMouse) == "MyMousePragmaStr"