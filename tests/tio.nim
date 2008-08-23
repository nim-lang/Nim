# test the file-IO

proc main() =
  for line in lines("thallo.nim"):
    writeln(stdout, line)

main()
