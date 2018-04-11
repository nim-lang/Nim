when defined(macosx):
  # MacOS has CFRunloop API, used in most of MacOS apps. This code allows
  # nim asyncdispatch to interoperate with existing CFRunloop.

  # This module is included by asyncdispatch, and relies on `pool` function
  # to be defined. This module's "public" function is `addKqueueFdToCFRunloop`.

  import dynlib

  type
    CFOptionFlags = uint
    CFIndex = int
    CFAllocator = pointer
    CFRunLoop = pointer
    CFFileDescriptor = pointer
    CFRunLoopSource = pointer
    CFRunLoopMode = pointer
    Boolean = uint8

    CFFileDescriptorCallBack = proc(f: CFFileDescriptor, callBackTypes: CFOptionFlags, nilPtr: pointer) {.cdecl.}

    CFApi = object
      CFFileDescriptorCreate: proc(nilPtr0: pointer, fd: cint, b: Boolean, cb: CFFileDescriptorCallBack, nilPtr1: pointer): CFFileDescriptor {.cdecl, gcsafe.}
      CFFileDescriptorEnableCallBacks: proc(f: CFFileDescriptor, opts: CFOptionFlags) {.cdecl, gcsafe.}
      CFFileDescriptorCreateRunLoopSource: proc(nilPtr: pointer, f: CFFileDescriptor, zero: CFIndex): CFRunLoopSource {.cdecl, gcsafe.}
      CFRunLoopAddSource: proc(r: CFRunLoop, s: CFRunLoopSource, m: CFRunLoopMode) {.cdecl, gcsafe.}
      CFRunLoopGetCurrent: proc(): CFRunLoop {.cdecl, gcsafe.}
      kCFRunLoopCommonModes: CFRunLoopMode
      CFRelease: proc(p: pointer) {.cdecl, gcsafe.}

  const
    kCFFileDescriptorReadCallBack = 1
    kCFFileDescriptorWriteCallBack = 2
    kCFFileDescriptorReadWriteCallBack = kCFFileDescriptorReadCallBack or kCFFileDescriptorWriteCallBack

  var cfApi: ptr CFApi

  proc CFRunLoop_callout_to_nim_kqueue(fdref: CFFileDescriptor, callBackTypes: CFOptionFlags, info: pointer) {.cdecl.} =
    poll(0)
    cfApi.CFFileDescriptorEnableCallBacks(fdref, kCFFileDescriptorReadWriteCallBack)

  proc replaceCFApi(api: ptr CFApi): bool {.inline.} =
    while cfApi.isNil:
      result = cas(addr cfApi, nil, api)

  proc initCFApi() {.gcsafe.} =
    let api = cast[ptr CFApi](allocShared(sizeof(CFApi)))
    let dl = loadLib()
    template load(s: untyped) =
      api.s = cast[type(api.s)](dl.symAddr(astToStr(s)))
    load(CFFileDescriptorCreate)
    var ok = false
    if not api.CFFileDescriptorCreate.isNil:
      load(CFFileDescriptorEnableCallBacks)
      load(CFFileDescriptorCreateRunLoopSource)
      load(CFRunLoopAddSource)
      load(CFRunLoopGetCurrent)
      load(kCFRunLoopCommonModes)
      load(CFRelease)

      ok = not(api.CFFileDescriptorEnableCallBacks.isNil or
        api.CFFileDescriptorCreateRunLoopSource.isNil or
        api.CFRunLoopAddSource.isNil or
        api.CFRunLoopGetCurrent.isNil or
        api.kCFRunLoopCommonModes.isNil or
        api.CFRelease.isNil)

    if ok:
      api.kCFRunLoopCommonModes = cast[ptr pointer](api.kCFRunLoopCommonModes)[]

    if not ok:
      api.CFFileDescriptorCreate = nil

    let replaced = replaceCFApi(api)
    if not replaced:
      deallocShared(api)

    if not replaced or not ok:
      unloadLib(dl)

  proc addKqueueFdToCFRunloop(kqFd: cint) {.gcsafe.} =
    ## Adds `kqFd` to current CFRunLoop, causing `poll(0)` to be triggered on
    ## any `kqFd` events.
    if cfApi.isNil:
      # Load required CoreFoundation API symbols.
      # The symbols are only loaded if we're linked to CoreFoundation, otherwise
      # there's no point to add to CFRunLoop, because CFRunLoop is not used.
      initCFApi()
    if not cfApi.CFFileDescriptorCreate.isNil:
      let fdref = cfApi.CFFileDescriptorCreate(nil, kqFd, 1, CFRunLoop_callout_to_nim_kqueue, nil)
      cfApi.CFFileDescriptorEnableCallBacks(fdref, kCFFileDescriptorReadWriteCallBack)
      let source = cfApi.CFFileDescriptorCreateRunLoopSource(nil, fdref, 0)
      cfApi.CFRunLoopAddSource(cfApi.CFRunLoopGetCurrent(), source, cfApi.kCFRunLoopCommonModes)
      cfApi.CFRelease(source)
      cfApi.CFRelease(fdref)
