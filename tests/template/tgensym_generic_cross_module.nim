discard """
  output: '''foo55
foo8.0
fooaha
bar7'''
"""
# bug #5419
import mgensym_generic_cross_module

foo(55)
foo 8.0
foo "aha"
bar 7

