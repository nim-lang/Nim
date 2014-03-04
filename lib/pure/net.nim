#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a high-level cross-platform sockets interface.

import sockets2, os, strutils, unsigned

type
  IpAddressFamily* {.pure.} = enum ## Describes the type of an IP address
    IPv6, ## IPv6 address
    IPv4  ## IPv4 address

  TIpAddress* = object ## stores an arbitrary IP address    
    case family*: IpAddressFamily      ## the type of the IP address (IPv4 or IPv6)
    of IpAddressFamily.IPv6:
      address_v6*: array[0..15, uint8] ## Contains the IP address in bytes in case of IPv6
    of IpAddressFamily.IPv4:
      address_v4*: array[0..3, uint8]  ## Contains the IP address in bytes in case of IPv4

proc IPv4_any*(): TIpAddress =
  ## Returns the IPv4 any address, which can be used to listen on all available
  ## network adapters
  result = TIpAddress(
    family: IpAddressFamily.IPv4,
    address_v4: [0'u8, 0'u8, 0'u8, 0'u8])

proc IPv4_loopback*(): TIpAddress =
  ## Returns the IPv4 loopback address (127.0.0.1)
  result = TIpAddress(
    family: IpAddressFamily.IPv4,
    address_v4: [127'u8, 0'u8, 0'u8, 1'u8])

proc IPv4_broadcast*(): TIpAddress =
  ## Returns the IPv4 broadcast address (255.255.255.255)
  result = TIpAddress(
    family: IpAddressFamily.IPv4,
    address_v4: [255'u8, 255'u8, 255'u8, 255'u8])

proc IPv6_any*(): TIpAddress =
  ## Returns the IPv6 any address (::0), which can be used
  ## to listen on all available network adapters 
  result = TIpAddress(
    family: IpAddressFamily.IPv6,
    address_v6: [0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8])

proc IPv6_loopback*(): TIpAddress =
  ## Returns the IPv6 loopback address (::1)
  result = TIpAddress(
    family: IpAddressFamily.IPv6,
    address_v6: [0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,0'u8,1'u8])

proc `==`*(lhs, rhs: TIpAddress): bool =
  ## Compares two IpAddresses for Equality. Returns two if the addresses are equal
  if lhs.family != rhs.family: return false
  if lhs.family == IpAddressFamily.IPv4:
    for i in low(lhs.address_v4) .. high(lhs.address_v4):
      if lhs.address_v4[i] != rhs.address_v4[i]: return false
  else: # IPv6
    for i in low(lhs.address_v6) .. high(lhs.address_v6):
      if lhs.address_v6[i] != rhs.address_v6[i]: return false
  return true

proc `$`*(address: TIpAddress): string =
  ## Converts an TIpAddress into the textual representation
  result = ""
  case address.family
  of IpAddressFamily.IPv4:
    for i in 0 .. 3:
      if i != 0:
        result.add('.')
      result.add($address.address_v4[i])
  of IpAddressFamily.IPv6:
    var
      currentZeroStart = -1
      currentZeroCount = 0
      biggestZeroStart = -1
      biggestZeroCount = 0
    # Look for the largest block of zeros
    for i in 0..7:
      var isZero = address.address_v6[i*2] == 0 and address.address_v6[i*2+1] == 0
      if isZero:
        if currentZeroStart == -1:
          currentZeroStart = i
          currentZeroCount = 1
        else:
          currentZeroCount.inc()
        if currentZeroCount > biggestZeroCount:
          biggestZeroCount = currentZeroCount
          biggestZeroStart = currentZeroStart
      else:
        currentZeroStart = -1

    if biggestZeroCount == 8: # Special case ::0
      result.add("::")
    else: # Print address
      var printedLastGroup = false
      for i in 0..7:
        var word:uint16 = (cast[uint16](address.address_v6[i*2])) shl 8
        word = word or cast[uint16](address.address_v6[i*2+1])

        if biggestZeroCount != 0 and # Check if in skip group
          (i >= biggestZeroStart and i < (biggestZeroStart + biggestZeroCount)):
          if i == biggestZeroStart: # skip start
            result.add("::")
          printedLastGroup = false
        else:
          if printedLastGroup:
            result.add(':')
          result.add(toHex(BiggestInt(word),4)) # this has too many digits
          printedLastGroup = true

proc parseIPv4Address(address_str: string): TIpAddress =
  ## Parses IPv4 adresses
  ## Raises EInvalidValue on errors
  var
    byteCount = 0
    currentByte:uint16 = 0
    seperatorValid = false

  result.family = IpAddressFamily.IPv4

  for i in 0 .. high(address_str):
    if address_str[i] in strutils.Digits: # Character is a number
      currentByte = currentByte * 10 + cast[uint16](ord(address_str[i]) - ord('0'))
      if currentByte > 255'u16: raise new EInvalidValue
      seperatorValid = true
    elif address_str[i] == '.': # IPv4 address separator
      if not seperatorValid or byteCount >= 3:
        raise new EInvalidValue
      result.address_v4[byteCount] = cast[uint8](currentByte)
      currentByte = 0
      byteCount.inc
      seperatorValid = false
    else:
      raise new EInvalidValue # Invalid character

  if byteCount != 3 or not seperatorValid:
    raise new EInvalidValue
  result.address_v4[byteCount] = cast[uint8](currentByte)

proc parseIPv6Address(address_str: string): TIpAddress =
  ## Parses IPv6 adresses
  ## Raises EInvalidValue on errors
  result.family = IpAddressFamily.IPv6
  if address_str.len < 2: raise new EInvalidValue

  var
    groupCount = 0
    currentGroupStart = 0
    currentShort:uint32 = 0
    seperatorValid = true
    dualColonGroup = -1
    lastWasColon = false
    v4StartPos = -1
    byteCount = 0

  for i,c in address_str:
    if c == ':':
      if not seperatorValid: raise new EInvalidValue
      if lastWasColon:        
        if dualColonGroup != -1: raise new EInvalidValue
        dualColonGroup = groupCount
        seperatorValid = false
      elif i != 0 and i != high(address_str):
        if groupCount >= 8: raise new EInvalidValue
        result.address_v6[groupCount*2] = cast[uint8](currentShort shr 8)
        result.address_v6[groupCount*2+1] = cast[uint8](currentShort and 0xFF)
        currentShort = 0
        groupCount.inc()        
        if dualColonGroup != -1: seperatorValid = false
      elif i == 0: # only valid if address starts with ::
        if address_str[1] != ':': raise new EInvalidValue
      else: # i == high(address_str) - only valid if address ends with ::
        if address_str[high(address_str)-1] != ':': raise new EInvalidValue
      lastWasColon = true
      currentGroupStart = i + 1
    elif c == '.': # Switch to parse IPv4 mode
      if i < 3 or not seperatorValid or groupCount >= 7: raise new EInvalidValue
      v4StartPos = currentGroupStart
      currentShort = 0
      seperatorValid = false
      break
    elif c in strutils.HexDigits:
      if c in strutils.Digits: # Normal digit
        currentShort = (currentShort shl 4) + cast[uint32](ord(c) - ord('0'))
      elif c >= 'a' and c <= 'f': # Lower case hex
        currentShort = (currentShort shl 4) + cast[uint32](ord(c) - ord('a')) + 10
      else: # Upper case hex
        currentShort = (currentShort shl 4) + cast[uint32](ord(c) - ord('A')) + 10
      if currentShort > 65535'u32: raise new EInvalidValue
      lastWasColon = false
      seperatorValid = true
    else:
      raise new EInvalidValue


  if v4StartPos == -1: # Don't parse v4. Copy the remaining v6 stuff
    if seperatorValid: # Copy remaining data
      if groupCount >= 8: raise new EInvalidValue
      result.address_v6[groupCount*2] = cast[uint8](currentShort shr 8)
      result.address_v6[groupCount*2+1] = cast[uint8](currentShort and 0xFF)
      groupCount.inc()
  else: # Must parse IPv4 address
    for i,c in address_str[v4StartPos..high(address_str)]:
      if c in strutils.Digits: # Character is a number
        currentShort = currentShort * 10 + cast[uint32](ord(c) - ord('0'))
        if currentShort > 255'u32: raise new EInvalidValue
        seperatorValid = true
      elif c == '.': # IPv4 address separator
        if not seperatorValid or byteCount >= 3:
          raise new EInvalidValue
        result.address_v6[groupCount*2 + byteCount] = cast[uint8](currentShort)
        currentShort = 0
        byteCount.inc()
        seperatorValid = false
      else: # Invalid character
        raise new EInvalidValue

    if byteCount != 3 or not seperatorValid:
      raise new EInvalidValue
    result.address_v6[groupCount*2 + byteCount] = cast[uint8](currentShort)
    groupCount += 2

  # Shift and fill zeros in case of ::
  if groupCount > 8:
    raise new EInvalidValue
  elif groupCount < 8: # must fill
    if dualColonGroup == -1: raise new EInvalidValue
    var toFill = 8 - groupCount # The number of groups to fill
    var toShift = groupCount - dualColonGroup # Nr of known groups after ::
    for i in 0..2*toShift-1: # shift
      result.address_v6[15-i] = result.address_v6[groupCount*2-i-1]
    for i in 0..2*toFill-1: # fill with 0s
      result.address_v6[dualColonGroup*2+i] = 0
  elif dualColonGroup != -1: raise new EInvalidValue


proc parseIpAddress*(address_str: string): TIpAddress =
  ## Parses an IP address
  ## Raises EInvalidValue on error
  if address_str == nil:
    raise new EInvalidValue
  if address_str.contains(':'):
    return parseIPv6Address(address_str)
  else:
    return parseIPv4Address(address_str)


type
  TSocket* = TSocketHandle

proc bindAddr*(socket: TSocket, port = TPort(0), address = "") {.
  tags: [FReadIO].} =

  ## binds an address/port number to a socket.
  ## Use address string in dotted decimal form like "a.b.c.d"
  ## or leave "" for any address.

  if address == "":
    var name: TSockaddr_in
    when defined(windows):
      name.sin_family = toInt(AF_INET).int16
    else:
      name.sin_family = toInt(AF_INET)
    name.sin_port = htons(int16(port))
    name.sin_addr.s_addr = htonl(INADDR_ANY)
    if bindAddr(socket, cast[ptr TSockAddr](addr(name)),
                  sizeof(name).TSocklen) < 0'i32:
      osError(osLastError())
  else:
    var aiList = getAddrInfo(address, port, AF_INET)
    if bindAddr(socket, aiList.ai_addr, aiList.ai_addrlen.TSocklen) < 0'i32:
      dealloc(aiList)
      osError(osLastError())
    dealloc(aiList)

proc setBlocking*(s: TSocket, blocking: bool) {.tags: [].} =
  ## Sets blocking mode on socket
  when defined(Windows):
    var mode = clong(ord(not blocking)) # 1 for non-blocking, 0 for blocking
    if ioctlsocket(s, FIONBIO, addr(mode)) == -1:
      osError(osLastError())
  else: # BSD sockets
    var x: int = fcntl(s, F_GETFL, 0)
    if x == -1:
      osError(osLastError())
    else:
      var mode = if blocking: x and not O_NONBLOCK else: x or O_NONBLOCK
      if fcntl(s, F_SETFL, mode) == -1:
        osError(osLastError())
