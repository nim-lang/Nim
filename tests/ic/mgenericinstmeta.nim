# A generic ref object with a self-referential proc field, instantiated with
# nested generic arguments. See tgenericinstmeta.nim.
type
  BufferedIO*[B; IO] = object
    buffer: B
    io: IO
  MyT5*[R; W] = ref object
    reader: R
    writer: W
    cb: proc(x: MyT5[R, W]): int
proc myNew5*[RB; RIO; WB; WIO](
    rbuffer: RB; rio: RIO; wbuffer: WB; wio: WIO
): MyT5[BufferedIO[RB, RIO], BufferedIO[WB, WIO]] =
  result = MyT5[BufferedIO[RB, RIO], BufferedIO[WB, WIO]]()
