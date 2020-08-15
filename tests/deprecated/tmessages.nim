discard """
  nimout:'''tmessages.nim(10, 1) Warning: Deprecated since v1.2.0, use 'HelloZ'; hello is deprecated [Deprecated]
'''
"""

proc hello[T](a: T) {.deprecated: "Deprecated since v1.2.0, use 'HelloZ'".} =
  discard


hello[int](12)
