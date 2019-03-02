import "../../compiler" / [llstream, nimeval]

proc readLineFromStdin(prompt: string, line: var string): bool =
  stdout.write(prompt)
  result = readLine(stdin, line)
  if not result:
    stdout.write("\n")
    quit(0)

proc myRepl(s: PLLStream, buf: pointer, bufLen: int): int =
  s.s = ""
  s.rd = 0
  var line = newStringOfCap(120)
  while readLineFromStdin("$ ", line):
    add(s.s, line)
    add(s.s, "\n")
  result = min(bufLen, len(s.s) - s.rd)
  if result > 0:
    copyMem(buf, addr(s.s[s.rd]), result)
    inc(s.rd, result)

let std = findNimStdLibCompileTime()
var intr = createInterpreter("stdin", [std])
intr.evalScript(llStreamOpenStdIn(myRepl))
