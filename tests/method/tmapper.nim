discard """
  errormsg: "invalid declaration order; cannot attach 'step' to method defined here: tmapper.nim(22, 8)"
  line: 25
"""

# bug #2590

type
  Console* = ref object
    mapper*: Mapper

  Mapper* = ref object of RootObj

  Mapper2* = ref object of Mapper

proc newMapper2*: Mapper2 =
  new result

proc newMapper*: Mapper =
  result = newMapper2()

method step*(m: Mapper2) {.base.} =
  echo "Mapper2"

method step*(m: Mapper) {.base.} =
  echo "Mapper"

var console = Console()
console.mapper = newMapper()
console.mapper.step()
