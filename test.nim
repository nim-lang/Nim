type
  ChunkObj = object
    data: UncheckedArray[byte]

proc alloc(size: int): ref ChunkObj =
  unsafeNew(result, size)

proc main() =
  let buf = alloc(10)
  buf.data[9] = 100    # index out of bounds, because one byte is occupied by the 'dummy' field, 
                       # the actual usable size of data is 9 bytes

main()
