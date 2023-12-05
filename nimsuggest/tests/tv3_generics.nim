type
  Hello[T] = object
    value: T

proc printHelloValue[T](hello: Hello[T]) =
  echo hello.value

proc main() =
  let a = Hello[float]()
  p#[!]#rintHelloValue(a)

main()

discard """
$nimsuggest --v3 --tester $file
>def $1
def;;skProc;;tv3_generics.printHelloValue;;proc (hello: Hello[printHelloValue.T]);;$file;;5;;5;;"";;100
"""
