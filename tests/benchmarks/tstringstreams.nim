discard """
  action: compile
"""
#[
  nimble install benchy
  nim r -d:danger -d:lto tests/benchmarks/stringstreams.nim
]#

import pkg/benchy
import std/streams



timeIt "Tightly Sized uint32", 1000:
  var s = streams.newStringStream()
  for i in 0 .. 100000:
    s.write(i.uint32)
  s.setPosition(0)
  while not s.atEnd:
    keep s.readUint32()
  keep s.data

timeIt "Two Times Growth uint32", 1000:
  var s = streams.newStringStream(growthRate = 2)
  for i in 0 .. 100000:
    s.write(i.uint32)
  s.setPosition(0)
  while not s.atEnd:
    keep s.readUint32()
  keep s.data

timeIt "Tightly Sized uint8", 1000:
  var s = streams.newStringStream()
  for i in 0 .. 100000:
    s.write(i.uint8)
  s.setPosition(0)
  while not s.atEnd:
    keep s.readUint8()
  keep s.data

timeIt "Two Times Growth uint8", 1000:
  var s = streams.newStringStream(growthRate = 2)
  for i in 0 .. 100000:
    s.write(i.uint8)
  s.setPosition(0)
  while not s.atEnd:
    keep s.readUint8()
  keep s.data

timeIt "Tightly Sized uint16", 1000:
  var s = streams.newStringStream()
  for i in 0 .. 100000:
    s.write(i.uint16)
  s.setPosition(0)
  while not s.atEnd:
    keep s.readUint16()
  keep s.data

timeIt "Two Times Growth uint16", 1000:
  var s = streams.newStringStream(growthRate = 2)
  for i in 0 .. 100000:
    s.write(i.uint16)
  s.setPosition(0)
  while not s.atEnd:
    keep s.readUint16()
  keep s.data

timeIt "Tightly Sized String", 1000:
  var s = streams.newStringStream()
  for i in 0 .. 100000:
    s.write("Hello World")
  keep s.data

timeIt "Two Times Growth String", 1000:
  var s = streams.newStringStream(growthRate = 2)
  for i in 0 .. 100000:
    s.write("Hello World")
  keep s.data