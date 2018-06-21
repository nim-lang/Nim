discard """
  output: '''
(member: "hello world")
(member: 123.456)
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
