discard """
  output: '''caught'''
"""

type
  Base = ref object of RootObj
  Child = ref object of Base

method run(value: Base): string {.base.} =
  result = "base"

method run(value: Child): string =
  raise newException(ValueError, "child")

let value: Base = Child()
try:
  discard value.run()
  quit "virtual method did not raise"
except ValueError:
  echo "caught"
