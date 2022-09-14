discard """
  nimout: '''
tslimsystem.nim(7, 1) Warning: about to move out of system, import `std/syncio` instead; use `-d:nimPreviewSlimSystem` to enforce import; write is deprecated [Deprecated]
'''
"""

write(stdout, "hello")
