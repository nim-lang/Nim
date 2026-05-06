# bug #25617
# Ensure that proc types with backend type alias mismatches
# (e.g. uint vs csize_t) are rejected at the Nim level rather
# than producing invalid C code.

discard """
  cmd: "nim check --hints:off --warnings:off --errorMax:0 $file"
  action: "reject"
  nimout: '''
tbackendtypealias.nim(21, 7) Error: type mismatch: got <proc (len: csize_t){.closure.}> but expected 'proc (len: uint){.closure.}'
tbackendtypealias.nim(28, 7) Error: type mismatch: got <proc (len: uint){.closure.}> but expected 'proc (len: csize_t){.closure.}'
'''
"""

block direct_assignment:
  # Direct proc variable assignment with backend type alias mismatch
  var
    a: proc (len: uint)
    b: proc (len: csize_t)
    c = a
  c = b

block direct_assignment_reverse:
  var
    a: proc (len: csize_t)
    b: proc (len: uint)
    c = a
  c = b

block same_backend_type:
  # Same backend type should still work
  var
    a: proc (len: uint)
    b: proc (len: uint)
    c = a
  c = b

block cint_same_type:
  # cint to cint should work
  var
    a: proc (len: cint)
    b: proc (len: cint)
    c = a
  c = b
