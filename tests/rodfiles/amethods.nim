
type
  TBaseClass* = object of TObject

proc newBaseClass*: ref TBaseClass =
  new result

method echoType*(x: ref TBaseClass) =
  echo "base class"

proc echoAlias*(x: ref TBaseClass) =
  echoType x

