discard """
  output: 9
"""

type DataTable = concept x
  x is object
  for f in fields(x):
    f is seq

type Students = object
   id : seq[int]
   name : seq[string]
   age: seq[int]

proc nrow*(dt: DataTable) : Natural =
  var totalLen = 0
  for f in fields(dt):
    totalLen += f.len
  return totalLen

let
  stud = Students(id : @[1,2,3], name : @["Vas", "Pas", "NafNaf"], age : @[10,16,32])

echo nrow(stud)

