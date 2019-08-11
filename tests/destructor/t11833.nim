discard """
  cmd: '''nim c --newruntime $file'''
  output: '''
'''
"""

type Foo = object

proc test() =
  var x = @[@[Foo()]]

test()
