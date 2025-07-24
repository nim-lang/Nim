when false: # parse the following
  let foo = Obj(
    field1: proc (src: pointer, srcLen: Natural)
                    {.nimcall, gcsafe, raises: [IOError, Defect].} =
      var file = FileOutputStream(s).file

      implementWrites s.buffers, src, srcLen, "FILE",
                      writeStartAddr, writeLen,
        file.writeBuffer(writeStartAddr, writeLen)
    ,
    field2: proc {.nimcall, gcsafe, raises: [IOError, Defect].} =
      flushFile FileOutputStream(s).file
    ,
    field3: proc () {.nimcall, gcsafe, raises: [IOError, Defect].} =
      close FileOutputStream(s).file
  )
