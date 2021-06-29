
type
  Base* = ref object of RootObj
    s*: string

method m*(b: Base) {.base.} =
  echo "Base ", b.s
