import streams, io

let myStream = StringStream(data: "hello")
static:
  assert myStream is SyncIO
  assert Stream is SyncIO
