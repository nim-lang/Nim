# test the file-IO

proc main() =
  for line in lines("thello.nim"):
    writeln(stdout, line)

main()
