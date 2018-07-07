discard """
  output: '''1
0
0
0
x = ['a', 'b', 'c', '0', '1', '2', '3', '4', '5', '6'] and y = ['a', 'b', 'c', '0', '1', '2', '3', '4', '5', '6']'''
"""

proc `1/1`() = echo(1 div 1)
template `1/2`() = echo(1 div 2)
var `1/3` = 1 div 4
`1/3` = 1 div 3 # oops, 1/3!=1/4
let `1/4` = 1 div 4

`1/1`()
`1/2`()
echo `1/3`
echo `1/4`

# bug #6422

proc toCharArray1(N : static[int], s: string): array[N, char] =
  doAssert s.len <= N
  let x = cast[ptr array[N, char]](s.cstring)
  x[]

proc toCharArray2(N : static[int], s: string): array[N, char] =
  doAssert s.len <= N
  let x = cast[ptr array[N, char]](s.cstring)
  result = x[]

let x = toCharArray1(10, "abc0123456")
let y = toCharArray2(10, "abc0123456")
echo "x = ", $x, " and y = ", $y
