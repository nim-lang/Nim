In this directory you will find the nim commandline version of the
cross-calculator sample.

The commandline interface can be used non interactively through switches, or
interactively when running the command without parameters.

Compilation is fairly easy despite having the source split in different
directories. Thanks to the nim.cfg file, which adds the ../nim_backend
directory as a search path, you can compile and run the example just fine from
the command line with 'nim c -r nimcalculator.nim'.
