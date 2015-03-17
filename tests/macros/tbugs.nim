discard """
msg: '''a
s
d
f
TTaa
TTaa
TTaa
TTaa
true
true
nil'''

output: '''test
2'''
"""

type
  Foo = object
    s: char

iterator test2(f: string): Foo =
  for i in f:
    yield Foo(s: i)

macro test(): stmt =
  for i in test2("asdf"):
    echo i.s

test()


# bug 1297

import macros

type TType = tuple[s: string]

macro echotest(): stmt =
  var t: TType
  t.s = ""
  t.s.add("test")
  result = newCall(newIdentNode("echo"), newStrLitNode(t.s))

echotest()

# bug #1103

type
    Td = tuple
        a:string
        b:int

proc get_data(d: Td) : string {.compileTime.} =
    result = d.a # Works if a literal string is used here.
    # Bugs if line A or B is active. Works with C
    result &= "aa"          # A
    #result.add("aa")       # B
    #result = result & "aa" # C

macro m(s:static[Td]) : stmt =
    echo get_data(s)
    echo get_data(s)
    result = newEmptyNode()

const s=("TT", 3)
m(s)
m(s)

# bug #933

proc nilcheck(): NimNode {.compileTime.} =
  echo(result == nil) # true
  echo(result.isNil) # true
  echo(repr(result)) # nil

macro testnilcheck(): stmt =
  result = newNimNode(nnkStmtList)
  discard nilcheck()

testnilcheck()

# bug #1323

proc calc(): array[1, int] =
  result[0].inc()
  result[0].inc()

const c = calc()
echo c[0]
