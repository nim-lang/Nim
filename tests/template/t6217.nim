discard """
  output: '''
start
side effect!
end
'''
"""

# bug #6217

template optMul{`*`(a, 2)}(a: int{noSideEffect}): int = a+a

proc f(): int =
  echo "side effect!"
  result = 55

echo "start"
doAssert f() * 2 == 110
echo "end"
