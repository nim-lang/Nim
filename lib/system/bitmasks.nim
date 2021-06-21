#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Page size of the system; in most cases 4096 bytes. For exotic OS or
# CPU this needs to be changed:
const
  PageShift = when defined(cpu16): 8 else: 12 # \
    # my tests showed no improvements for using larger page sizes.
  PageSize = 1 shl PageShift
  PageMask = PageSize-1

  MemAlign = # also minimal allocatable memory block
    when defined(useMalloc):
      when defined(amd64): 16 
      else: 8
    else: 16

  BitsPerPage = PageSize div MemAlign
  UnitsPerPage = BitsPerPage div (sizeof(int)*8)
    # how many ints do we need to describe a page:
    # on 32 bit systems this is only 16 (!)

  TrunkShift = 9
  BitsPerTrunk = 1 shl TrunkShift # needs to be power of 2 and divisible by 64
  TrunkMask = BitsPerTrunk - 1
  IntsPerTrunk = BitsPerTrunk div (sizeof(int)*8)
  IntShift = 5 + ord(sizeof(int) == 8) # 5 or 6, depending on int width
  IntMask = 1 shl IntShift - 1
