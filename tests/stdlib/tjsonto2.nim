discard """
  output: "42"
"""

import json

type
  MsgBase = object of RootObj
    name*: int

  MsgChallenge = object of MsgBase
    challenge*: int

let data = %* {"name": 21, "challenge": 2}
let msg = data.to(MsgChallenge)
echo msg.name * msg.challenge
