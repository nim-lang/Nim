discard """
output: '''
set
popped 1
set
popped 0
z1
'''
matrix: "--mm:arc -d:danger -d:lto"
"""

# bug #24596

proc main() =
  var trimMap = [@[1], @[2]]
  var z = 0
  for j in 0 ..< 2:
    var i = trimMap.high
    while i >= 0:
      #let len {.volatile} = trimMap[i].len # this way it "works"
      let len = trimMap[i].len
      if len > 0:
        z = trimMap[i].pop()
        echo "set"
        break
      dec i
    echo "popped ", i
    doAssert z != 0
  echo "z", z

main()
