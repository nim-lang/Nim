discard """
  output: "direct\ngeneric\ngeneric"
"""

proc withDirectType(args: string) =
  echo "direct"

proc withDirectType[T](arg: T) =
  echo "generic"

proc withOpenArray(args: openarray[string]) =
  echo "openarray"

proc withOpenArray[T](arg: T) =
  echo "generic"

proc withVarargs(args: varargs[string]) =
  echo "varargs"

proc withVarargs[T](arg: T) =
  echo "generic"

withDirectType "string"
withOpenArray "string"
withVarargs "string"

