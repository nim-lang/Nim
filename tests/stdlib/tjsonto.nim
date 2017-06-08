discard """
  output: "foobar"
"""

import json

type
  MsgBase = ref object of RootObj
    name*: string

  MsgChallenge = ref object of MsgBase
    challenge*: string

let data = %* {"name": "foo", "challenge": "bar"}
let msg = data.to(MsgChallenge)
echo msg.name & msg.challenge
