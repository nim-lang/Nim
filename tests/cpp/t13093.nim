discard """
  targets: "cpp"
  action: reject
  errormsg: "The PledgeObj type requires the following fields to be initialized: refCount"
"""

import atomics

type
  Pledge* = object
    p: PledgePtr

  PledgePtr = ptr PledgeObj
  PledgeObj = object
    refCount: Atomic[int32]

proc main() =
  var pledge: Pledge
  pledge.p = createShared(PledgeObj)
  let tmp = PledgeObj() # <---- not allowed: atomics are not copyable

  pledge.p[] = tmp

main()
