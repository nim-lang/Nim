discard """
  output: '''it's nil
@[1, 2, 3]'''
"""

template foo(s: string = nil) =
  if isNil(s):
    echo "it's nil"
  else:
    echo s

foo


# bug #2632

proc takeTup(x: tuple[s: string;x: seq[int]]) =
  discard

takeTup(("foo", @[]))


#proc foobar(): () =

proc f(xs: seq[int]) =
  discard

proc g(t: tuple[n:int, xs:seq[int]]) =
  discard

when isMainModule:
  f(@[]) # OK
  g((1,@[1])) # OK
  g((0,@[])) # NG


# bug #2630
type T = tuple[a: seq[int], b: int]

var t: T = (@[1,2,3], 7)

proc test(s: seq[int]): T =
  echo s
  (s, 7)

t = test(t.a)
