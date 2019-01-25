discard """
  nimout: '''tdeprecated.nim(10, 3) Warning: a is deprecated [Deprecated]
tdeprecated.nim(17, 11) Warning: asdf; enum 'Foo' which contains field 'a' is deprecated [Deprecated]
'''
"""
block:
  var
    a {.deprecated.}: array[0..11, int]

  a[8] = 1

block t10111:
  type
    Foo {.deprecated: "asdf" .} = enum
      a 
  
  var _ = a
  

