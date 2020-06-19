
include prelude

proc positionToOffset(content: string; line, col: int): int =
  var line = line-1
  var col = col
  var i = 0
  var found = line == 0
  while i < content.len:
    if content[i] == '\n':
      dec line
      if line == 0: found = true
    inc i
    if found:
      if col == 0: return i
      dec col
  return -1

proc patch(instructions: string) =
  var files = initTable[string, string]()
  for instr in lines(instructions):
    if instr.len > 0:
      let cmd = instr.splitWhitespace()
      if cmd.len == 5:
        let file = cmd[0]
        let line = parseInt cmd[1]
        let col = parseInt cmd[2]
        let span = parseInt cmd[3]
        let replaceBy = cmd[4]

        if not files.contains(file):
          files[file] = readFile(file)
        let offset = positionToOffset(files[file], line, col)
        if offset >= 0:
          files[file] = substr(files[file], 0, offset-1) & replaceBy &
                        substr(files[file], offset+span)

  for name, content in pairs(files):
    #echo "----------- for ", name, " the content would be ----------"
    #echo content
    echo "patching ", name
    writeFile(name, content)

patch("to_func.txt")
