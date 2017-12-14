#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Low level dataspace allocator for Genode.

when not defined(genode):
  {.error: "Genode only module".}

type DataspaceCapability {.
  importcpp: "Genode::Dataspace_capability", pure.} = object

type
  Map = object
    attachment: pointer
    size: int
    ds: DataspaceCapability

  SlabMeta = object
    next: ptr MapSlab
    ds: DataspaceCapability

  MapSlab = object
    meta: SlabMeta
    maps: array[1,Map]

const SlabBackendSize = 4096

proc ramAvail(): int {.
  importcpp: "genodeEnv->pd().avail_ram().value".}
  ## Return number of bytes available for allocation.

proc capsAvail(): int {.
  importcpp: "genodeEnv->pd().avail_caps().value".}
  ## Return the number of available capabilities.
  ## Each dataspace allocation consumes a capability.

proc allocDataspace(size: int): DataspaceCapability {.
  importcpp: "genodeEnv->pd().alloc(@)".}
  ## Allocate a dataspace and its capability.

proc attachDataspace(ds: DataspaceCapability): pointer {.
  importcpp: "genodeEnv->rm().attach(@)".}
  ## Attach a dataspace into the component address-space.

proc detachAddress(p: pointer) {.
  importcpp: "genodeEnv->rm().detach(@)".}
  ## Detach a dataspace from the component address-space.

proc freeDataspace(ds: DataspaceCapability) {.
  importcpp: "genodeEnv->pd().free(@)".}
  ## Free a dataspace.

proc newMapSlab(): ptr MapSlab =
  let
    ds = allocDataspace SlabBackendSize
    p = attachDataspace ds
  result = cast[ptr MapSlab](p)
  result.meta.ds = ds

iterator items(s: ptr MapSlab): ptr Map =
  let mapCount = (SlabBackendSize - sizeof(SlabMeta)) div sizeof(Map)
  for i in 0 .. <mapCount:
    yield s.maps[i].addr

var slabs: ptr MapSlab

proc osAllocPages(size: int): pointer =
  if slabs.isNil:
    slabs = newMapSlab()
  var
    slab = slabs
    map: ptr Map
  let mapCount = (SlabBackendSize - sizeof(SlabMeta)) div sizeof(Map)
  block findFreeMap:
    while true:
      # lookup first free spot in slabs
      for m in slab.items:
        if m.attachment.isNil:
          map = m
          break findFreeMap
      if slab.meta.next.isNil:
        slab.meta.next = newMapSlab()
          # tack a new slab on the tail
      slab = slab.meta.next
        # move to next slab in linked list
  map.ds = allocDataspace size
  map.size = size
  map.attachment = attachDataspace map.ds
  result = map.attachment

proc osTryAllocPages(size: int): pointer =
  if ramAvail() >= size and capsAvail() > 1:
    result = osAllocPages size

proc osDeallocPages(p: pointer; size: int) =
  var slab = slabs
  while not slab.isNil:
    # lookup first free spot in slabs
    for m in slab.items:
      if m.attachment == p:
        if m.size != size:
          echo "cannot partially detach dataspace"
          quit -1
        detachAddress m.attachment
        freeDataspace m.ds
        m[] = Map()
        return
    slab = slab.meta.next
