discard """
  targets: "c js"
  output: '''
:)
1
2
3
before
a
b
3
4
'''
"""

# bug #12805: the statements before the iterator call in a `for` loop's
# iterable were dropped
for it in (echo ":)"; 1..3):
  echo it

iterator items2(s: seq[string]): string =
  for x in s: yield x

proc main =
  let s = @["a", "b"]
  for it in (echo "before"; items2(s)):
    echo it
main()

proc other =
  for i in (let a = 3; a..4): echo i
other()
