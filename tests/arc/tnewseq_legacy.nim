discard """
  output: "(allocCount: 201, deallocCount: 201)"
  cmd: "nim c --gc:orc -d:nimAllocStats -d:noSignalHandler $file"
"""

proc main(prefix: string) =
  var c: seq[string]
  for i in 0..<100:
    newSeq(c, 100)
    c[i] = prefix & $i

main("abc")
echo getAllocStats()
