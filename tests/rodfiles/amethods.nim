
type
  TBaseClass* = object of RootObj

proc newBaseClass*: ref TBaseClass =
  new result

method echoType*(x: ref TBaseClass) {.base.} =
  echo "base class"

proc echoAlias*(x: ref TBaseClass) =
  echoType x

