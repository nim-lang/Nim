proc exportedFromSupport*(value: int): int {.exportabi.} =
  value + 1

type
  CustomHooked* = object
    value*: int

  MoveOnly* = object
    value*: int

var
  customHookDestroys = 0
  moveOnlyDestroys = 0

proc `=destroy`(value: CustomHooked) =
  if value.value != 0:
    inc customHookDestroys

proc `=destroy`(value: MoveOnly) =
  if value.value != 0:
    inc moveOnlyDestroys

proc `=copy`(dest: var MoveOnly; source: MoveOnly) {.error.}

proc makeMoveOnly*(value: int): MoveOnly {.exportabi.} =
  MoveOnly(value: value)
