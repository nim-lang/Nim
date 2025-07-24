# module b for t22373

import m22373a

# original:
type
  LightClientDataFork* {.pure.} = enum
    None = 0,
    Altair = 1
template LightClientHeader*(kind: static LightClientDataFork): auto =
  when kind == LightClientDataFork.Altair:
    typedesc[m22373a.LightClientHeader]
  else:
    static: raiseAssert "Unreachable"

# simplified:
template TypeOrTemplate*(num: int): untyped =
  typedesc[m22373a.TypeOrTemplate]
