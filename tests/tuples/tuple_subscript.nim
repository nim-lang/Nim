discard """
  output: '''5
5
str2
str2
4
0
1
2'''
"""

proc`[]` (t: tuple, key: string): string =
  for name, field in fieldPairs(t):
    if name == key: 
      return $field
  return ""


proc`[]` [A,B](t: tuple, key: string, op: (proc(x: A): B)): B =
  for name, field in fieldPairs(t):
    when field is A:
      if name == key: 
        return op(field)

proc`[]=`[T](t: var tuple, key: string, val: T) =
  for name, field in fieldPairs(t):
    when field is T:
      if name == key: 
        field = val

var tt = (a: 1, b: "str1")

# test built in operator
tt[0] = 5
echo tt[0] 
echo `[]`(tt, 0)


# test overloaded operator
tt["b"] = "str2"
echo tt["b"] 
echo `[]`(tt, "b")
echo tt["b", proc(s: string) : int = s.len]

echo tt.low
echo tt.high
echo tt.len