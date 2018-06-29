import macros

type
  MyEnum = enum
    AVal, BVal, CVal

echo($AVal)
echo($BVal)


proc bar(arg: set[MyEnum], arg2: MyEnum): void {.exportc: "bar".} =
  echo arg
  echo arg2

proc foo(arg: NimNodeKind): void {.exportc: "foo".} =
  echo arg

proc mymain(): void =
  let myArray = [AVal,BVal,CVal]
  var mySeq = @myArray
  mySeq.add myArray
  echo mySeq

  foo(nnkIdent)
  foo(nnkVarSection)
  bar({AVal, CVal}, BVal)

mymain()
