discard """
  output: '''done'''
"""
# Issue #22842: internal error: getTypeDescAux(tyAnything) with auto in proc type
# https://github.com/nim-lang/Nim/issues/22842

proc register(cb: proc (e: auto): void) = discard

register(proc (e: int) = echo e)

echo "done"
