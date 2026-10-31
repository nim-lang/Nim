# `ns2shrink` before `tns2_stale_root.nim` drops most of it: symbols that
# the project's NIF refers to and the new one no longer has.
type
  Extra1* = object
    f1*: int
  Extra2* = object
    f2*: int
  Extra3* = object
    f3*: int
  Extra4* = object
    f4*: int
  Extra5* = object
    f5*: int
  Extra6* = object
    f6*: int
  Extra7* = object
    f7*: int
  Extra8* = object
    f8*: int
  Extra9* = object
    f9*: int
  Extra10* = object
    f10*: int
  Extra11* = object
    f11*: int
  Extra12* = object
    f12*: int
  Extra13* = object
    f13*: int
  Extra14* = object
    f14*: int
  Extra15* = object
    f15*: int
  Extra16* = object
    f16*: int
  Extra17* = object
    f17*: int
  Extra18* = object
    f18*: int
  Extra19* = object
    f19*: int
  Extra20* = object
    f20*: int
  Extra21* = object
    f21*: int
  Extra22* = object
    f22*: int
  Extra23* = object
    f23*: int
  Extra24* = object
    f24*: int
  Extra25* = object
    f25*: int
  Extra26* = object
    f26*: int
  Extra27* = object
    f27*: int
  Extra28* = object
    f28*: int
  Extra29* = object
    f29*: int
  Extra30* = object
    f30*: int
  Extra31* = object
    f31*: int
  Extra32* = object
    f32*: int
  Extra33* = object
    f33*: int
  Extra34* = object
    f34*: int
  Extra35* = object
    f35*: int
  Extra36* = object
    f36*: int
  Extra37* = object
    f37*: int
  Extra38* = object
    f38*: int
  Extra39* = object
    f39*: int
  Extra40* = object
    f40*: int
  Thing* = object
    x*: int

proc extra1*(): Extra1 = Extra1()
proc extra2*(): Extra2 = Extra2()
proc extra3*(): Extra3 = Extra3()
proc extra4*(): Extra4 = Extra4()
proc extra5*(): Extra5 = Extra5()
proc extra6*(): Extra6 = Extra6()
proc extra7*(): Extra7 = Extra7()
proc extra8*(): Extra8 = Extra8()
proc extra9*(): Extra9 = Extra9()
proc extra10*(): Extra10 = Extra10()
proc extra11*(): Extra11 = Extra11()
proc extra12*(): Extra12 = Extra12()
proc extra13*(): Extra13 = Extra13()
proc extra14*(): Extra14 = Extra14()
proc extra15*(): Extra15 = Extra15()
proc extra16*(): Extra16 = Extra16()
proc extra17*(): Extra17 = Extra17()
proc extra18*(): Extra18 = Extra18()
proc extra19*(): Extra19 = Extra19()
proc extra20*(): Extra20 = Extra20()
proc extra21*(): Extra21 = Extra21()
proc extra22*(): Extra22 = Extra22()
proc extra23*(): Extra23 = Extra23()
proc extra24*(): Extra24 = Extra24()
proc extra25*(): Extra25 = Extra25()
proc extra26*(): Extra26 = Extra26()
proc extra27*(): Extra27 = Extra27()
proc extra28*(): Extra28 = Extra28()
proc extra29*(): Extra29 = Extra29()
proc extra30*(): Extra30 = Extra30()
proc extra31*(): Extra31 = Extra31()
proc extra32*(): Extra32 = Extra32()
proc extra33*(): Extra33 = Extra33()
proc extra34*(): Extra34 = Extra34()
proc extra35*(): Extra35 = Extra35()
proc extra36*(): Extra36 = Extra36()
proc extra37*(): Extra37 = Extra37()
proc extra38*(): Extra38 = Extra38()
proc extra39*(): Extra39 = Extra39()
proc extra40*(): Extra40 = Extra40()

proc makeThing*(x: int): Thing =
  Thing(x: x)
