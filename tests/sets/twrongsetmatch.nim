# issue #25009

type EnumOne {.pure.} = enum
  aaa
  bbb

type EnumTwo {.pure.} = enum
  ccc
  ddd
  eee

proc doStuff(e: set[EnumOne]) =
  echo e

doStuff({EnumTwo.ddd}) #[tt.Error
       ^ type mismatch]#
