discard """
  output: '''true
true
true
5
4
3
2
1
0
it should stop now
18446744073709551615
4294967295
'''
"""

# bug 1420
var x = 40'u32
var y = 30'u32
echo x > y # works

echo((40'i32) > (30'i32))
echo((40'u32) > (30'u32)) # Error: ordinal type expected

# bug #4220

const count: uint = 5
var stop_me = false

for i in countdown(count, 0):
  echo i
  if stop_me: break
  if i == 0:
    echo "it should stop now"
    stop_me = true

# bug #3985
const
  HIGHEST_64BIT_UINT = 0xFFFFFFFFFFFFFFFF'u
  HIGHEST_32BIT_UINT = 0xFFFFFFFF'u

echo($HIGHEST_64BIT_UINT)
echo($HIGHEST_32BIT_UINT)
