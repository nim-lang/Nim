discard """
  cmd: "$nim c --gc:regions -d:nimTypeNames -r $file"
  output: "Success"
"""

var s: seq[int] = @[]

var inner: MemRegion

include system/ansi_c

#echo @[1, 20]

echo @[1000, 100]

when false:
  #withRegion(inner):
  withScratchRegion:
    for x in 0..1_000:
      let g = "bar"
      let f = substr("foo ") & g & $x
      echo f # & " stuff"
      s.add(x)

  echo s

echo "Success"