#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a base64 encoder and decoder.

const 
  cb64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

template encodeInternal(s: expr, lineLen: int, newLine: string): stmt {.immediate.} = 
  ## encodes `s` into base64 representation. After `lineLen` characters, a 
  ## `newline` is added.
  var total = ((len(s) + 2) div 3) * 4
  var numLines = (total + lineLen - 1) div lineLen
  if numLines > 0: inc(total, (numLines-1) * newLine.len)

  result = newString(total)
  var i = 0
  var r = 0
  var currLine = 0
  while i < s.len - 2:
    var a = ord(s[i])
    var b = ord(s[i+1])
    var c = ord(s[i+2])
    result[r] = cb64[a shr 2]
    result[r+1] = cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result[r+2] = cb64[((b and 0x0F) shl 2) or ((c and 0xC0) shr 6)] 
    result[r+3] = cb64[c and 0x3F] 
    inc(r, 4)
    inc(i, 3)
    inc(currLine, 4)
    if currLine >= lineLen and i != s.len-2: 
      for x in items(newLine): 
        result[r] = x
        inc(r)
      currLine = 0

  if i < s.len-1:
    var a = ord(s[i])
    var b = ord(s[i+1])
    result[r] = cb64[a shr 2]
    result[r+1] = cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result[r+2] = cb64[((b and 0x0F) shl 2)] 
    result[r+3] = '='
    if r+4 != result.len:
      setLen(result, r+4)
  elif i < s.len:
    var a = ord(s[i])
    result[r] = cb64[a shr 2]
    result[r+1] = cb64[(a and 3) shl 4]
    result[r+2] = '='
    result[r+3] = '='
    if r+4 != result.len:
      setLen(result, r+4)
  else:
    #assert(r == result.len)

proc encode*[T:TInteger|char](s: openarray[T], lineLen = 75, newLine="\13\10"): string = 
  ## encodes `s` into base64 representation. After `lineLen` characters, a 
  ## `newline` is added.
  encodeInternal(s, lineLen, newLine)
    
proc encode*(s: string, lineLen = 75, newLine="\13\10"): string = 
  ## encodes `s` into base64 representation. After `lineLen` characters, a 
  ## `newline` is added.
  encodeInternal(s, lineLen, newLine)
  
proc decodeByte(b: char): int {.inline.} = 
  case b
  of '+': result = ord('>')
  of '0'..'9': result = ord(b) + 4
  of 'A'..'Z': result = ord(b) - ord('A')
  of 'a'..'z': result = ord(b) - 71
  else: result = 63

proc decode*(s: string): string = 
  ## decodes a string in base64 representation back into its original form.
  ## Whitespace is skipped.
  const Whitespace = {' ', '\t', '\v', '\r', '\l', '\f'}
  var total = ((len(s) + 3) div 4) * 3
  # total is an upper bound, as we will skip arbitrary whitespace:
  result = newString(total)

  var i = 0
  var r = 0
  while true:
    while s[i] in Whitespace: inc(i)
    if i < s.len-3:
      var a = s[i].decodeByte
      var b = s[i+1].decodeByte
      var c = s[i+2].decodeByte
      var d = s[i+3].decodeByte
      
      result[r] = chr((a shl 2) and 0xff or ((b shr 4) and 0x03))
      result[r+1] = chr((b shl 4) and 0xff or ((c shr 2) and 0x0F))
      result[r+2] = chr((c shl 6) and 0xff or (d and 0x3F))
      inc(r, 3)
      inc(i, 4)
    else: break
  assert i == s.len
  # adjust the length:
  if i > 0 and s[i-1] == '=': 
    dec(r)
    if i > 1 and s[i-2] == '=': dec(r)
  setLen(result, r)
  
when isMainModule:
  assert encode("leasure.") == "bGVhc3VyZS4="
  assert encode("easure.") == "ZWFzdXJlLg=="
  assert encode("asure.") == "YXN1cmUu"
  assert encode("sure.") == "c3VyZS4="
  
  const longText = """Man is distinguished, not only by his reason, but by this
    singular passion from other animals, which is a lust of the mind, 
    that by a perseverance of delight in the continued and indefatigable
    generation of knowledge, exceeds the short vehemence of any carnal
    pleasure."""
  const tests = ["", "abc", "xyz", "man", "leasure.", "sure.", "easure.",
                 "asure.", longText]
  for t in items(tests):
    assert decode(encode(t)) == t

