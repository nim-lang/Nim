discard """
  errormsg: "index out of bounds: (a:0) <= (i:2) <= (b:1) "
  line: 18
"""

block:
  try:
    let a = @[1,2]
    echo a[3]
  except Exception as e:
    doAssert e.msg == "index out of bounds: (i:3) <= (n:1) "

block:
  type TTestArr = array[0..1, int16]
  var f: TTestArr
  f[0] = 30
  f[1] = 40
  f[2] = 50
  f[3] = 60

  echo(repr(f))
