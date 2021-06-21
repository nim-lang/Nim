discard """
  output: '''asdf
231
'''
  cmd: "nim c --gc:arc -d:useMalloc -g $file"
  valgrind: true
"""

{.experimental: "views".}

const
  Whitespace = {' ', '\t', '\n', '\r'}

iterator split*(s: string, seps: set[char] = Whitespace,
                maxsplit: int = -1): openArray[char] =
  var last = 0
  var splits = maxsplit

  while last <= len(s):
    var first = last
    while last < len(s) and s[last] notin seps:
      inc(last)
    if splits == 0: last = len(s)
    yield toOpenArray(s, first, last-1)
    if splits == 0: break
    dec(splits)
    inc(last)

proc `$`(x: openArray[char]): string =
  result = newString(x.len)
  for i in 0..<x.len: result[i] = x[i]

proc main() =
  for x in split("asdf 231"):
    echo x

main()
