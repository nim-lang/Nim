
# issue #11812

proc run(a: proc()) = a()

proc main() =
  var test: int
  run(proc() = test = 0)
  run do:
    test = 0

main()
