discard """
  output: '''
(lo: 10, hi: 0)
(lo: 10, hi: 0)
'''
"""

# bug #7378: `static` param used in `when` of a generic object
type
  MpUint*[bits: static[int]] = object
    when system.cpuEndian == littleEndian:
      when bits == 128: lo*, hi*: uint64
      elif bits ==  64: lo*, hi*: uint32
      elif bits ==  32: lo*, hi*: uint16
      elif bits ==  16: lo*, hi*: uint8
      else:
        lo*, hi*: MpUint[bits div 2]
    else:
      when bits == 128: hi*, lo*: uint64
      elif bits ==  64: hi*, lo*: uint32
      elif bits ==  32: hi*, lo*: uint16
      elif bits ==  16: hi*, lo*: uint8
      else:
        hi*, lo*: MpUint[bits div 2]

proc toMpUint*(n: uint16): MpUint[16] =
  cast[typeof(result)](n)

let a = 10'u16
var b = a.toMpUint()

proc fails_always(x: MpUint, y: MpUint) =
  echo x

proc fails_if_called*[bits: static[int]](x: MpUint[bits], y: MpUint[bits]) =
  echo x

fails_if_called(b, b)
fails_always(b, b)
