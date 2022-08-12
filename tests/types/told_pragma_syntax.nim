discard """
  nimout: '''
told_pragma_syntax.nim(8, 19) Warning: pragmas after the `object` keyword is a legacy syntax kept for compatibility; put pragmas after the type name instead [Deprecated]
told_pragma_syntax.nim(9, 20) Warning: pragma before generic parameter list is a legacy syntax for compatibility, put pragmas after the generic parameter list instead [Deprecated]
'''
"""

type Foo = object {.final.}
type Bar {.final.} [T] = object
