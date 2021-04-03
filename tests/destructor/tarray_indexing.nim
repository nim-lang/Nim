discard """
  output: '''allocating 1048576 65536
filling page from 1048576 len 65536'''
  cmd: '''nim c --gc:arc $file'''
"""

# bug #12669

type
    MemState* = enum
        memPrivate

    MemPermisison* = enum
        memperm_Read

    MemInfo* = ref object
        base*, size*: uint32
        state*: MemState
        perm*: set[MemPermisison]

    MemBlock = ref object
        info: MemInfo
        data: seq[byte]

    UserProcessMemory* = ref object
        pageAccess: array[0x40000, ptr UncheckedArray[byte]]
        pages: array[0x40000, MemInfo]
        blocks: seq[owned MemBlock]

proc allocMemory*(mem: UserProcessMemory, base, size: uint32) =
    let
        roundedBase = base and not(0xFFF'u32)
        roundedSize = (size + 0xFFF) and not(0xFFF'u32)

    echo "allocating ", base, " ", size
    for i in (roundedBase shr 12)..<((roundedBase + roundedSize) shr 12):
        #echo "span ", i
        doAssert mem.pages[i] == nil
        # TODO: beserer fehler

    let memBlock = MemBlock(
        info: MemInfo(
            base: roundedBase,
            size: roundedSize,
            state: memPrivate,
            perm: {memperm_Read}
        ),
        data: newSeq[byte](roundedSize))
    for i in 0..<(roundedSize shr 12):
        mem.pages[i + (roundedBase shr 12)] = memBlock.info
        #echo cast[uint64](addr mem.pageAccess[i + (roundedBase shr 12)])
        mem.pageAccess[i + (roundedBase shr 12)] = cast[ptr UncheckedArray[byte]](addr memBlock.data[i * 0x1000])
    mem.blocks.add memBlock

    #for i in (roundedBase shr 12)..<((roundedBase + roundedSize) shr 12):
    #    assert mem.pageAccess[i] != nil

proc fillPages*(mem: UserProcessMemory, start: uint32, data: seq[byte]) =
    echo "filling page from ", start, " len ", data.len
    assert (start and not(0xFFF'u32)) == start
    assert (uint32(data.len) and not(0xFFF'u32)) == uint32(data.len)
    for i in (start shr 12)..<((start + uint32(data.len)) shr 12):
        #echo cast[uint64](addr mem.pageAccess[i])
        let page = mem.pageAccess[i]
        assert page != nil
        #copyMem(page, unsafeAddr data[i * 0x1000 - start], 0x1000)

const base = 0x00100000

proc a(): owned UserProcessMemory =
    result = UserProcessMemory()
    result.allocMemory(base, 0x1000 * 16)
    result.fillPages(base, newSeq[byte](0x1000 * 16))

discard a()
