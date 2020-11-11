discard """
  output: '''asdf
asdf
231
231
'''
  cmd: "nim c --gc:orc $file"
"""

{.experimental: "views".}

const
  Whitespace = {' ', '\t', '\n', '\r'}

proc split*(s: string, seps: set[char] = Whitespace,
                maxsplit: int = -1): seq[openArray[char]] =
  var last = 0
  var splits = maxsplit
  result = @[]

  while last <= len(s):
    var first = last
    while last < len(s) and s[last] notin seps:
      inc(last)
    if splits == 0: last = len(s)
    result.add toOpenArray(s, first, last-1)
    result.add toOpenArray(s, first, last-1)
    if splits == 0: break
    dec(splits)
    inc(last)

proc `$`(x: openArray[char]): string =
  result = newString(x.len)
  for i in 0..<x.len: result[i] = x[i]

proc main() =
  let words = split("asdf 231")
  for x in words:
    echo x

main()
