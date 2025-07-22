#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  NimSeqPayloadReimpl = int

  NimSeqV2Reimpl = object
    len: int
    p: ptr NimSeqPayloadReimpl

template readNimSeqV2Reimpl(s: var NimSeqV2Reimpl; value: pointer) =
  c_memcpy(addr s, value, csize_t(sizeof(s)))

template storeNimSeqV2Reimpl(value: pointer; s: NimSeqV2Reimpl) =
  c_memcpy(value, unsafeAddr s, csize_t(sizeof(s)))

template frees(s: NimSeqV2Reimpl) =
  if s.p != nil and (s.p[] and strlitFlag) != strlitFlag:
    when compileOption("threads"):
      deallocShared(s.p)
    else:
      dealloc(s.p)
