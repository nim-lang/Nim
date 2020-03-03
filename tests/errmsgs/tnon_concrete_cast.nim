discard """
  errormsg: "cannot cast to a non concrete type: 'ptr SomeNumber'"
  line: 36
"""

# https://github.com/nim-lang/Nim/issues/5428

type
  MemFile = object
    mem: pointer

proc memfileopen(filename: string, newFileSize: int): MemFile =
  # just a memfile mock
  return

type
  MyData = object
    member1: seq[int]
    member2: int

type
  MyReadWrite = object
    memfile: MemFile
    offset: int

# Here, SomeNumber is bound to a concrete type, and that's OK
proc write(rw: var MyReadWrite; value: SomeNumber): void =
  (cast[ptr SomeNumber](cast[uint](rw.memfile.mem) + rw.offset.uint))[] = value
  rw.offset += sizeof(SomeNumber)

# Here, we try to use SomeNumber without binding it to a type. This should
# produce an error message for now. It's also possible to relax the rules
# and allow for type-class based type inference in such situations.
proc write[T](rw: var MyReadWrite; value: seq[T]): void =
  rw.write value.len
  let dst  = cast[ptr SomeNumber](cast[uint](rw.memfile.mem) + uint(rw.offset))
  let src  = cast[pointer](value[0].unsafeAddr)
  let size = sizeof(T) * value.len
  copyMem(dst, src, size)
  rw.offset += size

proc saveBinFile(arg: var MyData, filename: string): void =
  var rw: MyReadWrite
  rw.memfile = memfileOpen(filename, newFileSize = rw.offset)
  rw.offset = 0
  rw.write arg.member1

