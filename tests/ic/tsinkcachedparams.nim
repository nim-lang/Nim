discard
  """
  description: '''IC: sink parameters retain ownership when instantiated from a cached generic'''
"""

#? metamorphic

#!FLAGS --skipParentCfg --skipUserCfg --mm:arc

# Keep the generic helper outside the materialized fixtures so editing main
# does not rewrite it and discard the cached declarations being tested.

#!FILE main.nim
import ../msinkcachedparams
echo "ready"
#!STEP expect: ready

# Cache the generic declaration before its sink parameters' elements acquire
# their type-bound operations, then instantiate it in a subsequent build.
#!FILE main.nim
import ../msinkcachedparams

var number = 42
var replies: ReplyQueue[int]
replies.enqueue("reply " & $number)
let retained = replies.enqueueAndReturn("retained " & $number)
replies.enqueueBatch(@["nested " & $number])
doAssert replies.replies == @["reply 42", "retained 42"]
doAssert retained == "retained 42"
doAssert replies.batches == @[@["nested 42"]]
echo "replies retained"
#!STEP expect: replies retained

#!STEP expect: replies retained

#!STEP expect: replies retained; noop

#!FILE main.nim
import ../msinkcachedparams

var number = 43
var replies: ReplyQueue[int]
replies.enqueue("reply " & $number)
let retained = replies.enqueueAndReturn("retained " & $number)
replies.enqueueBatch(@["nested " & $number])
doAssert replies.replies == @["reply 43", "retained 43"]
doAssert retained == "retained 43"
doAssert replies.batches == @[@["nested 43"]]
echo "replies retained"
#!STEP expect: replies retained

#!STEP expect: replies retained

#!STEP expect: replies retained; noop

#!FLAGS --skipParentCfg --skipUserCfg --mm:orc

#!FILE main.nim
import ../msinkcachedparams
echo "ready"
#!STEP expect: ready

#!FILE main.nim
import ../msinkcachedparams

var number = 43
var replies: ReplyQueue[int]
replies.enqueue("reply " & $number)
let retained = replies.enqueueAndReturn("retained " & $number)
replies.enqueueBatch(@["nested " & $number])
doAssert replies.replies == @["reply 43", "retained 43"]
doAssert retained == "retained 43"
doAssert replies.batches == @[@["nested 43"]]
echo "replies retained"
#!STEP expect: replies retained

#!STEP expect: replies retained

#!STEP expect: replies retained; noop
