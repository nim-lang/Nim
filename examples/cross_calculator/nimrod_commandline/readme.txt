In this directory you will find the nimrod commandline version of the
cross-calculator sample.

The commandline interface can be used non interactively through switches, or
interactively when running the command without parameters.

Compilation is fairly easy despite having the source split in different
directories. Thanks to the nimrod.cfg file, which adds the ../nimrod_backend
directory as a search path, you can compile and run the example just fine from
the command line with 'nimrod c -r nimcalculator.nim'.
