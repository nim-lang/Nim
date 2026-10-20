discard """
  targets: "c js"
  output: '''
1
2
len 2
len 0
len 0
slen 0
'''
"""

# bug #2459: empty array/seq literals passed to typed template params
template test(a: openArray[int]) =
  for n in a:
    echo n
  echo "len ", a.len

test([1, 2])
test([])
const x = []
test(x)

template ts(a: seq[int]) =
  for n in a: echo n
  echo "slen ", a.len

ts(@[])
