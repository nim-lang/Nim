discard """
  output: "6"
"""
# test this particular function

proc mypos(sub, s: string, start: int = 0): int =
  var
    i, j, M, N: int
  M = sub.len
  N = s.len
  i = start
  j = 0
  if i >= N:
    result = -1
  else:
    while true:
      if s[i] == sub[j]:
        inc(i)
        inc(j)
      else:
        i = i - j + 1
        j = 0
      if (j >= M) or (i >= N): break
    if j >= M:
      result = i - M
    else:
      result = -1

var sub = "hello"
var s = "world hello"
write(stdout, mypos(sub, s))
write stdout, "\n"
#OUT 6
