discard """
  nimout: '''
told_pragma_syntax.nim(7, 19) Warning: type pragmas follow the type name; this form of writing pragmas is a legacy syntax kept for compatibility [Deprecated]
told_pragma_syntax.nim(8, 20) Warning: pragma before generic parameter list is a legacy syntax for compatibility, put pragmas after the generic parameter list instead [Deprecated]
'''
"""

type Foo = object {.final.}
type Bar {.final.} [T] = object
