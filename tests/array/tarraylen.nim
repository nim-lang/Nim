discard """
  file: "tarraylen.nim"
  output: '''0
1
1
1
1
2
2
3
3
3
3
1
3
1
'''
"""
var a: array[0, int]
echo a.len
echo array[0..0, int].len
echo(array[0..0, int]([1]).len)
echo array[1..1, int].len
echo(array[1..1, int]([1]).len)
echo array[2, int].len
echo(array[2, int]([1, 2]).len)
echo array[1..3, int].len
echo(array[1..3, int]([1, 2, 3]).len)
echo array[0..2, int].len
echo(array[0..2, int]([1, 2, 3]).len)
echo array[-2 .. -2, int].len
echo([1, 2, 3].len)
echo([42].len)