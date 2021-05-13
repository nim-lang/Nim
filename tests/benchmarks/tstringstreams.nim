discard """
  action: compile
"""
#[
  nimble install benchy
  nim r -d:danger -d:lto tests/benchmarks/stringstreams.nim
]#

import pkg/benchy
import std/streams

type
  PacketID = enum
    jump, shoot, crouch, hit
  Entity = object
    id: int

proc writePacket(str: StringStream, kind: PacketID, ent: Entity, target: Entity = Entity(id: -1)) =
  str.write kind
  str.write ent.id
  case kind:
  of shoot:
    str.write 10
    str.write target.id
  of hit:
    str.write 3
  else: discard

# Benchmark using string streams as a network buffer shows ~`0.005ms` improvement in this small example
timeIt "Normal growth rate Network", 1000:
  var s = newStringStream()
  for i in 0..1000:
    let event = i.mod(PacketID.high.ord).PacketID
    if event == shoot:
      s.writePacket(event, Entity(id: i), Entity(id: i + 1))
    else:
      s.writePacket(event, Entity(id: i))
  keep s.data

timeIt "Twice growth rate Network", 1000:
  var s = newStringStream(growthRate = 2)
  for i in 0..1000:
    let event = i.mod(PacketID.high.ord).PacketID
    if event == shoot:
      s.writePacket(event, Entity(id: i), Entity(id: i + 1))
    else:
      s.writePacket(event, Entity(id: i))
  keep s.data


let data = newSeq[(byte, byte, byte)](300 * 500)

# Basic pseudo image example using a header and data
# Results on my machine shows constant 2 times growth is roughly ~`.5ms` faster
timeIt "Normal growth rate image saving", 1000:
  var s = newStringStream()
  s.write("Width:300, Height:500") # Simulated header format
  for x in data:
    s.write(x)

timeIt "Twice growth rate image saving", 1000:
  var s = newStringStream(growthRate = 2)
  s.write("Width:300, Height:500") # Simulated header format
  for x in data:
    s.write(x)

timeIt "Four times growth rate image saving", 1000:
  var s = newStringStream(growthRate = 3)
  s.write("Width:300, Height:500") # Simulated header format
  for x in data:
    s.write(x)