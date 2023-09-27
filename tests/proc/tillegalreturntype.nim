discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
tillegalreturntype.nim(11, 11) Error: return type 'typed' is only valid for macros and templates
tillegalreturntype.nim(14, 11) Error: return type 'untyped' is only valid for macros and templates
tillegalreturntype.nim(17, 41) Error: return type 'auto' cannot be used in forward declarations
'''
"""

proc x(): typed =
  discard

proc y(): untyped =
  discard

proc test_proc[T, U](arg1: T, arg2: U): auto

proc test_proc[T, U](arg1: T, arg2: U): auto =
    echo "Proc has been called"
    return arg1 / arg2
