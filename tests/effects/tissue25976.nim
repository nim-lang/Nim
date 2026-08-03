type
  NestedPoll = object of RootEffect

  CallbackFunc = proc(arg: pointer) {.gcsafe, raises: [], forbids: [NestedPoll].}
  TaggedCallbackFunc = proc(arg: pointer) {.gcsafe, raises: [], tags: [], forbids: [NestedPoll].}

  InternalAsyncCallback = object
    fn: CallbackFunc

  TaggedInternalAsyncCallback = object
    fn: TaggedCallbackFunc

proc closeSocket(aftercb: CallbackFunc = nil) =
  proc continuation(udata: pointer) =
    aftercb(nil)

  let acb = InternalAsyncCallback(fn: continuation)
  discard acb

proc closeSocketTagged(aftercb: TaggedCallbackFunc = nil) =
  proc continuation(udata: pointer) =
    aftercb(nil)

  let acb = TaggedInternalAsyncCallback(fn: continuation)
  discard acb

closeSocket()
closeSocketTagged()
