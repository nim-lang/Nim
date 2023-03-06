discard """
cmd: "nim check --hints:off $file"
errormsg: The module symbol cannot be used as a statement
nimout: '''
t19225.nim(11, 1) Error: The module symbol cannot be used as a statement
t19225.nim(14, 3) Error: The module symbol cannot be used as a statement
'''
"""
# bug #19225
import std/sequtils
sequtils
echo 1345
proc foo() =
  block:
    sequtils

foo()
