discard """
  nimout: '''
tdeprecated.nim(23, 3) Warning: a is deprecated [Deprecated]
tdeprecated.nim(30, 11) Warning: asdf; enum 'Foo' which contains field 'a' is deprecated [Deprecated]
tdeprecated.nim(40, 16) Warning: use fooX instead; fooA is deprecated [Deprecated]
end
'''
"""






## line 15



block:
  var
    a {.deprecated.}: array[0..11, int]

  a[8] = 1

block t10111:
  type
    Foo {.deprecated: "asdf" .} = enum
      a 
  
  var _ = a
  

block: # issue #8063
  type
    Foo = enum
      fooX

  {.deprecated: [fooA: fooX].}
  let
    foo: Foo = fooA
  echo foo
  static: echo "end"
