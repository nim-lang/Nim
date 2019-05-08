discard """
errormsg: '''
invalid type: 'UncheckedArray[uint8]' for var
'''
"""

var
  rawMem = alloc0(20)
  byteUA = cast[UncheckedArray[uint8]](rawMem)
