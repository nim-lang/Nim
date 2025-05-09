discard """
  cmd: '''nim ctags $file'''
  action: "compile"
"""

type
  Foo = object

proc hello() = discard

proc `$`(x: Foo): string = "foo"
