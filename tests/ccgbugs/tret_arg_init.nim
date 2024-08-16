discard """
  output: '''



'''
"""

type Bar = object
  s1, s2: string

proc initBar(): Bar = discard

var a: array[5, Bar]
a[0].s1 = "hey"
a[0] = initBar()
echo a[0].s1

type Foo = object
  b: Bar
var f: Foo
f.b.s1 = "hi"
f.b = initBar()
echo f.b.s1

var ad = addr f.b
ad[] = initBar()
echo ad[].s1
