# test the file-IO

proc main() =
  for line in lines("thello.nim"):
    writeLine(stdout, line)

main()
