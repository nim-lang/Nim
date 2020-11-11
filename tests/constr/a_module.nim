# a.nim
{.push stackTrace: off.}
proc foo*(): int =
  var a {.global.} = 0
  result = a
{.pop.}