discard """
  cmd: '''nim check --hints:off $file'''
  action: reject
nimout: '''
tredefinition.nim(9, 25) Error: redefinition of 'Key_a'; previous declaration here: tredefinition.nim(9, 18)
'''
"""

type Key* = enum Key_A, Key_a