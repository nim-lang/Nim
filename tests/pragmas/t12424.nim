discard """
  nimout: '''t12424.nim(8, 10) Warning: This is a test warning from user code [User]'''
"""
# Issue #12424: Warning and Hint Pragmas do not print to console when declared from a std lib module
# https://github.com/nim-lang/Nim/issues/12424
# This test verifies that warning pragmas in user code work correctly.

{.warning: "This is a test warning from user code".}
