discard """
  output: "1"
"""

proc viewInto(a: array[4, string]): lent string =
  result = a[0]

proc passToVar(x: var string) =
  discard

proc main =
  let x = ["1", "2", "3", "4"]
  echo viewInto(x)
  doAssert(not compiles(passToVar(viewInto(x))))

main()
