# Test a printf proc

proc printf(file: TTextFile, args: openarray[string]) =
  var i = 0
  while i < args.len:
    write(file, args[i])
    inc(i)

printf(stdout, ["Andreas ", "Rumpf\n"])
#OUT Andreas Rumpf
