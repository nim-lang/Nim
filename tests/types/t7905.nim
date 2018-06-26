discard """
  output: '''
(member: "hello world")
(member: 123.456)
(member: "hello world", x: ...)
(member: 123.456, x: ...)
'''
"""

template foobar(arg: typed): untyped =
  type
    MyType = object
      member: type(arg)

  var myVar: MyType
  myVar.member = arg
  echo myVar

foobar("hello world")
foobar(123.456'f64)

template foobarRec(arg: typed): untyped =
  type
    MyType = object
      member: type(arg)
      x: ref MyType

  var myVar: MyType
  myVar.member = arg
  echo myVar

foobarRec("hello world")
foobarRec(123.456'f64)
