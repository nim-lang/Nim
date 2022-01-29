## Solo5 glue.
# (c) 2022 Emery Heminyway

{.pragma: solo5header, header: "solo5.h".}
{.pragma: solo5, importc: "solo5_$1", solo5header.}

import std/monotimes, std/options
from std/strutils import `%`, toHex
import ./solo5

export Handle

iterator items*(hs: HandleSet): Handle =
  if uint64(hs) != 0:
    for i in 0..63:
      if (uint64(hs) and (1'u64 shl i)) != 0:
        yield Handle(i)

type HandleRegistry*[T] = object
  seq: seq[Option[T]]

proc isEmpty*[T](reg: HandleRegistry[T]): bool =
  result = true
  for o in reg.seq:
    if o.isSome: return false

proc contains*[T](reg: HandleRegistry[T]; h: Handle): bool =
  var i = int h
  result = i < reg.seq.len and reg.seq[i].isSome

proc `[]`*[T](reg: HandleRegistry[T]; h: Handle): T =
  var i = int h
  if i < reg.seq.len and reg.seq[i].isSome: result = get reg.seq[i]
  else: raise newException(IndexDefect, "handle not registered")

proc `[]=`*[T](reg: var HandleRegistry; h: Handle; v: T) =
  var i = int h
  if reg.seq.high < i:
    reg.seq.setLen(succ i)
  if reg.seq[i].isNone: reg.seq[i] = some v
  else: raise newException(IndexDefect, "handle already registered")

proc del*[T](reg: var HandleRegistry; h: Handle) =
  if reg.contains h: reg.seq[int h] = none T

iterator items*[T](reg: HandleRegistry[T]; hs: HandleSet): (Handle, T) =
  for h in hs:
    var i = int h
    if i < reg.seq.len and reg.seq[i].isSome:
      yield (h, get(reg.seq[i]),)

const
  SOLO5_NET_ALEN* = 6
  SOLO5_NET_HLEN* = 14

type
  MacAddress* = array[SOLO5_NET_ALEN, uint8]

  NetInfo* {.importc: "struct solo5_net_info", solo5header, pure.} = object
    mac_address*: MacAddress
    mtu*: csize_t ##  Not including Ethernet header

proc `$`*(mac: MacAddress): string =
  result = newStringOfCap(17)
  for i, b in mac:
    if i > 0: result.add '-'
    result.add b.toHex

proc net_acquire(name: cstring; handle: ptr Handle;
    info: ptr NetInfo): Result {.solo5.}

proc net_acquire*(name: string): (Handle, NetInfo) =
  let res = net_acquire(name, addr result[0], addr result[1])
  if res != SOLO5_R_OK:
    raise newException(AccessViolationDefect, $res)

proc net_write*(handle: Handle; buf: ptr uint8;
    size: csize_t): Result {.solo5, tags: [WriteIOEffect].}

proc net_read*(handle: Handle; buf: ptr uint8; size: csize_t;
              read_size: ptr csize_t): Result {.solo5, tags: [ReadIOEffect].}

type
  OffInt* = uint64
  BlockInfo* {.importc: "struct solo5_block_info", solo5header.} = object
    capacity*: OffInt   ##  Capacity of block device, bytes
    block_size*: OffInt ##  Minimum I/O unit (block size), bytes

proc block_acquire(name: cstring; handle: ptr Handle;
                   info: ptr BlockInfo): Result {.solo5.}

proc block_acquire*(name: string): (Handle, BlockInfo) =
  let res = block_acquire(name, addr result[0], addr result[1])
  if res != SOLO5_R_OK:
    raise newException(AccessViolationDefect, $res)

proc block_write*(handle: Handle; offset: OffInt; buf: ptr uint8; size: csize_t): Result {.solo5, tags: [WriteIOEffect].}
  ## Writes data of `size` bytes from the buffer `buf` to the block device
  ## identified by `handle`, starting at byte `offset`. Data is either written in
  ## it's entirety or not at all ("short writes" are not possible).
  ##
  ## Both `size` and `offset` must be a multiple of the block size.

proc block_write*(handle: Handle; offset: OffInt; buf: openarray[byte]) =
  let res = block_write(handle, offset, unsafeAddr buf[0], csize_t buf.len)
  if res != SOLO5_R_OK: raise newException(IOError, $res)

proc block_read*(handle: Handle; offset: OffInt; buf: ptr uint8;
    size: csize_t): Result {.solo5, tags: [ReadIOEffect].}
  ## Reads data of `size` bytes into the buffer `buf` from the block device
  ## identified by `handle`, starting at byte (offset). Always reads the full
  ## amount of `size` bytes ("short reads" are not possible).
  ##
  ## Both `size` and `offset` must be a multiple of the block size.

proc block_read*(handle: Handle; offset: OffInt; buf: var openarray[byte]) =
  let res = block_read(handle, offset, unsafeAddr buf[0], csize_t buf.len)
  if res != SOLO5_R_OK: raise newException(IOError, $res)


type
  DeviceType* = enum blockBasic, netBasic
  ManifestEntry* = tuple[name: string, device: DeviceType]

proc generateMft(devices: openarray[ManifestEntry]): string {.compileTime.} =
  var
    entries: string
    numEntries = 1
  for (name, dev) in devices:
    case dev
    of blockBasic:
      entries.add """, { .name = "$1", .type = MFT_DEV_BLOCK_BASIC }""" % name
    of netBasic:
      entries.add """, { .name = "$1", .type = MFT_DEV_NET_BASIC }""" % name
    inc numEntries
  """
#define MFT_ENTRIES $1
#include "mft_abi.h"

MFT1_NOTE_DECLARE_BEGIN
{
  .version = MFT_VERSION, .entries = $1,
  .e = {
    { .name = "", .type = MFT_RESERVED_FIRST }$2
  }
}
MFT1_NOTE_DECLARE_END

  """ % [ $numEntries, entries ]

type
  NetInitHook* = proc(h: Handle, ni: NetInfo) {.nimcall.}
  BlkInitHok* = proc(h: Handle, bi: BlockInfo) {.nimcall.}

proc discardNet(h: Handle, ni: NetInfo) {.nimcall.} = discard
proc discardBlk(h: Handle, bi: BlockInfo) {.nimcall.} = discard

template acquireDevices*(
    entries: openArray[ManifestEntry],
    netInit: NetInitHook = discardNet;
    blkInit: BlkInitHok = discardBlk) =
  ## Acquire and initialize Solo5 devices.
  ## This template generates a static ELF note and
  ## therefore must be called at the top-level of a module
  ## and only once per-program.
  {.emit: generateMft(entries).}
  proc initDevices() =
    for (name, dev) in entries:
      case dev
      of blockBasic:
        var (h, bi) = block_acquire(name)
        blkInit(h, bi)
      of netBasic:
        var (h, ni) = net_acquire(name)
        netInit(h, ni)
  initDevices()
