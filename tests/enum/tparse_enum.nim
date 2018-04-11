import strutils


type Enum7 {.pure.} = enum
  KE0
  KE1
  KE2
  KE3
  KE4
  KE5
  KE6

type Enum17 {.pure.} = enum
  KE0
  KE1
  KE2
  KE3
  KE4
  KE5
  KE6
  KE7
  KE8
  KE9
  KE10
  KE11
  KE12
  KE13
  KE14
  KE15
  KE16

type Enum75 {.pure.} = enum
  KE0
  KE1
  KE2
  KE3
  KE4
  KE5
  KE6
  KE7
  KE8
  KE9
  KE10
  KE11
  KE12
  KE13
  KE14
  KE15
  KE16
  KE17
  KE18
  KE19
  KE20
  KE21
  KE22
  KE23
  KE24
  KE25
  KE26
  KE27
  KE28
  KE29
  KE30
  KE31
  KE32
  KE33
  KE34
  KE35
  KE36
  KE37
  KE38
  KE39
  KE40
  KE41
  KE42
  KE43
  KE44
  KE45
  KE46
  KE47
  KE48
  KE49
  KE50
  KE51
  KE52
  KE53
  KE54
  KE55
  KE56
  KE57
  KE58
  KE59
  KE60
  KE61
  KE62
  KE63
  KE64
  KE65
  KE66
  KE67
  KE68
  KE69
  KE70
  KE71
  KE72
  KE73
  KE74

proc test[T: enum]() =
    for k in T:
      doAssert parseEnum[T]($k, T(0)) == k

test[Enum7]()
test[Enum17]()
test[Enum75]()

static:
    test[Enum7]()
    test[Enum17]()
    test[Enum75]()

echo "OK"
