#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  NimSeqPayloadReimpl = object
    cap: int
    data: pointer

  NimSeqV2Reimpl = object
    len: int
    p: ptr NimSeqPayloadReimpl

template frees(s: NimSeqV2Reimpl) =
  if s.p != nil and (s.p.cap and strlitFlag) != strlitFlag:
    when compileOption("threads"):
      deallocShared(s.p)
    else:
      dealloc(s.p)